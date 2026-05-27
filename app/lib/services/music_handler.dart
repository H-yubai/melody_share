import 'dart:async';
import 'dart:math';

import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import '../models/local_track.dart';
import 'database_service.dart';

enum PlaybackMode { noRepeat, repeatAll, repeatOne, shuffle }

class MusicHandler extends BaseAudioHandler with SeekHandler {
  final AudioPlayer player = AudioPlayer();
  final _random = Random();

  List<LocalTrack> _allTracks = [];
  List<LocalTrack> _localQueue = [];
  int _currentIndex = -1;
  PlaybackMode _mode = PlaybackMode.noRepeat;
  List<int> _shuffleOrder = [];
  int _shuffleCursor = 0;
  Map<String, int> _ratings = {};
  StreamSubscription? _processingSub;

  MusicHandler() {
    _processingSub = player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) next();
    });
    player.playerStateStream.listen((_) => _notify());
    _loadRatings();
  }

  Future<void> _loadRatings() async {
    try {
      _ratings = await DatabaseService.getAllRatings();
    } catch (_) {
      _ratings = {};
    }
  }

  // ─── Getters ─────────────────────────────────────────────────

  List<LocalTrack> get allTracks => List.unmodifiable(_allTracks);
  List<LocalTrack> get queueTracks => List.unmodifiable(_localQueue);
  int? get currentIndex => _currentIndex >= 0 ? _currentIndex : null;
  LocalTrack? get currentTrack =>
      _currentIndex >= 0 && _currentIndex < _localQueue.length
          ? _localQueue[_currentIndex]
          : null;
  PlaybackMode get mode => _mode;
  bool get isPlaying => player.playing;

  Stream<Duration> get positionStream => player.positionStream;
  Stream<Duration?> get durationStream => player.durationStream;
  Stream<PlayerState> get playerStateStream => player.playerStateStream;

  int getRating(String trackId) => _ratings[trackId] ?? 0;

  // ─── Data ────────────────────────────────────────────────────

  Future<void> loadCachedTracks() async {
    try {
      final tracks = await DatabaseService.loadScannedTracks();
      if (tracks.isNotEmpty) {
        _allTracks = tracks;
      }
    } catch (_) {}
  }

  Future<void> loadRatings() async {
    try {
      _ratings = await DatabaseService.getAllRatings();
    } catch (_) {
      _ratings = {};
    }
  }

  Future<void> rateTrack(String trackId, int rating) async {
    rating = rating.clamp(0, 3);
    _ratings[trackId] = rating;
    await DatabaseService.setRating(trackId, rating);
    if (_mode == PlaybackMode.shuffle) _rebuildShuffle();
    _notify();
  }

  void setAllTracks(List<LocalTrack> tracks) {
    _allTracks = List.from(tracks);
    _localQueue = List.from(tracks);
    _currentIndex = -1;
    _shuffleOrder = [];
    _notify();
  }

  // ─── Playback ─────────────────────────────────────────────────

  @override
  Future<void> play() async {
    if (player.playing) return;
    if (_currentIndex >= 0 && _currentIndex < _localQueue.length) {
      await player.play();
    } else if (_allTracks.isNotEmpty) {
      await playFromAll(0);
    }
  }

  @override
  Future<void> pause() async {
    await player.pause();
    _notify();
  }

  @override
  Future<void> stop() async {
    await player.stop();
    _currentIndex = -1;
    _notify();
  }

  Future<void> playFromQueue(int index) async {
    if (index < 0 || index >= _localQueue.length) return;
    _currentIndex = index;
    _notify();
    await _playCurrent();
  }

  Future<void> playFromAll(int index) async {
    if (index < 0 || index >= _allTracks.length) return;
    _localQueue = List.from(_allTracks);
    _currentIndex = index;
    if (_mode == PlaybackMode.shuffle) _rebuildShuffle();
    _notify();
    await _playCurrent();
  }

  Future<void> playTracks(List<LocalTrack> tracks, {int startIndex = 0}) async {
    if (tracks.isEmpty) return;
    _localQueue = List.from(tracks);
    _currentIndex = startIndex.clamp(0, tracks.length - 1);
    if (_mode == PlaybackMode.shuffle) _rebuildShuffle();
    _notify();
    await _playCurrent();
  }

  Future<void> _playCurrent() async {
    final track = currentTrack;
    if (track == null) return;
    try {
      await player.setAudioSource(AudioSource.file(track.filePath));
      await player.play();
    } catch (_) {}
  }

  // ─── Queue ────────────────────────────────────────────────────

  void addToQueue(LocalTrack track) {
    _localQueue.add(track);
    _notify();
  }

  void removeFromQueue(int index) {
    if (index < 0 || index >= _localQueue.length) return;
    _localQueue.removeAt(index);
    if (_currentIndex >= _localQueue.length) {
      _currentIndex = _localQueue.isEmpty ? -1 : _localQueue.length - 1;
    } else if (index < _currentIndex) {
      _currentIndex--;
    }
    _notify();
  }

  void clearQueue() {
    _localQueue = List.from(_allTracks);
    _currentIndex = -1;
    _notify();
  }

  // ─── Mode ─────────────────────────────────────────────────────

  void cyclePlaybackMode() {
    _mode = switch (_mode) {
      PlaybackMode.noRepeat => PlaybackMode.repeatAll,
      PlaybackMode.repeatAll => PlaybackMode.repeatOne,
      PlaybackMode.repeatOne => PlaybackMode.shuffle,
      PlaybackMode.shuffle => PlaybackMode.noRepeat,
    };
    if (_mode == PlaybackMode.shuffle) _rebuildShuffle();
    _notify();
  }

  void setPlaybackMode(PlaybackMode mode) {
    _mode = mode;
    if (mode == PlaybackMode.shuffle) _rebuildShuffle();
    _notify();
  }

  void _rebuildShuffle() {
    if (_localQueue.isEmpty) return;
    final weights = _localQueue.map((t) => 1 + (_ratings[t.id] ?? 0)).toList();

    _shuffleOrder = [];
    final remaining = List.generate(_localQueue.length, (i) => i);
    final remainingWeights = List<int>.from(weights);

    while (remaining.isNotEmpty) {
      final subTotal = remainingWeights.fold<int>(0, (a, b) => a + b);
      final pick = _random.nextInt(subTotal);
      int cum = 0;
      int selected = 0;
      for (int i = 0; i < remaining.length; i++) {
        cum += remainingWeights[i];
        if (pick < cum) {
          selected = i;
          break;
        }
      }
      _shuffleOrder.add(remaining[selected]);
      remaining.removeAt(selected);
      remainingWeights.removeAt(selected);
    }

    if (_currentIndex >= 0 && _currentIndex < _localQueue.length) {
      _shuffleOrder.remove(_currentIndex);
      _shuffleOrder.insert(0, _currentIndex);
    }
    _shuffleCursor = 0;
  }

  // ─── Navigation ──────────────────────────────────────────────

  @override
  Future<void> skipToNext() async => next();

  @override
  Future<void> skipToPrevious() async => previous();

  @override
  Future<void> skipToQueueItem(int index) async => playFromQueue(index);

  Future<void> next() async {
    if (_localQueue.isEmpty) return;
    switch (_mode) {
      case PlaybackMode.repeatOne:
        await _playCurrent();
        break;
      case PlaybackMode.shuffle:
        _shuffleCursor = (_shuffleCursor + 1) % _shuffleOrder.length;
        await playFromQueue(_shuffleOrder[_shuffleCursor]);
        break;
      case PlaybackMode.repeatAll:
        final nextIndex = (_currentIndex + 1) % _localQueue.length;
        await playFromQueue(nextIndex);
        break;
      case PlaybackMode.noRepeat:
        if (_currentIndex >= _localQueue.length - 1) {
          await player.pause();
          await player.seek(Duration.zero);
        } else {
          await playFromQueue(_currentIndex + 1);
        }
        break;
    }
  }

  Future<void> previous() async {
    if (_localQueue.isEmpty) return;
    switch (_mode) {
      case PlaybackMode.shuffle:
        _shuffleCursor =
            (_shuffleCursor - 1 + _shuffleOrder.length) % _shuffleOrder.length;
        await playFromQueue(_shuffleOrder[_shuffleCursor]);
        break;
      case PlaybackMode.noRepeat:
      case PlaybackMode.repeatAll:
      case PlaybackMode.repeatOne:
        final prevIndex =
            (_currentIndex - 1 + _localQueue.length) % _localQueue.length;
        await playFromQueue(prevIndex);
        break;
    }
  }

  Future<void> togglePlayPause() async {
    if (player.playing) {
      await player.pause();
    } else {
      await player.play();
    }
  }

  // ─── Notification ────────────────────────────────────────────

  void _notify() {
    final track = currentTrack;
    if (track != null) {
      mediaItem.add(MediaItem(
        id: track.id,
        title: track.displayTitle,
        artist: track.displayArtist,
      ));
    }
    playbackState.add(PlaybackState(
      controls: const [
        MediaControl.skipToPrevious,
        MediaControl.pause,
        MediaControl.skipToNext,
      ],
      systemActions: const {MediaAction.seek},
      processingState: switch (player.processingState) {
        ProcessingState.ready => AudioProcessingState.ready,
        ProcessingState.buffering => AudioProcessingState.buffering,
        ProcessingState.loading => AudioProcessingState.loading,
        ProcessingState.completed => AudioProcessingState.completed,
        _ => AudioProcessingState.idle,
      },
      playing: player.playing,
      repeatMode: switch (_mode) {
        PlaybackMode.noRepeat => AudioServiceRepeatMode.none,
        PlaybackMode.repeatAll => AudioServiceRepeatMode.all,
        PlaybackMode.repeatOne => AudioServiceRepeatMode.one,
        PlaybackMode.shuffle => AudioServiceRepeatMode.group,
      },
      shuffleMode: _mode == PlaybackMode.shuffle
          ? AudioServiceShuffleMode.all
          : AudioServiceShuffleMode.none,
      queueIndex: _currentIndex,
      updatePosition: player.position,
    ));
    if (_localQueue.isNotEmpty) {
      queue.add(_localQueue.map((t) => MediaItem(
        id: t.id,
        title: t.displayTitle,
        artist: t.displayArtist,
      )).toList());
    }
  }

  @override
  Future<dynamic> customAction(String name, [Map<String, dynamic>? extras]) async {
    switch (name) {
      case 'play':
        final tracks = (extras!['tracks'] as List)
            .map((j) => LocalTrack.fromJson(j as Map<String, dynamic>))
            .toList();
        final index = extras['index'] as int;
        await playTracks(tracks, startIndex: index);
    }
  }

  Future<void> dispose() async {
    _processingSub?.cancel();
    await player.dispose();
  }
}
