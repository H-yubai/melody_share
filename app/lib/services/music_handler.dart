import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:media_kit/media_kit.dart';

import '../models/local_track.dart';
import 'database_service.dart';
import 'media_notification_service.dart';

enum PlaybackMode { noRepeat, repeatAll, repeatOne, shuffle }

class MusicHandler {
  final Player player = Player();
  final _random = Random();
  final MediaNotificationService? _notificationService;

  List<LocalTrack> _allTracks = [];
  List<LocalTrack> _localQueue = [];
  int _currentIndex = -1;
  PlaybackMode _mode = PlaybackMode.noRepeat;
  List<int> _shuffleOrder = [];
  int _shuffleCursor = 0;
  Map<String, int> _ratings = {};
  StreamSubscription? _completedSub;
  StreamSubscription? _errorSub;
  StreamSubscription? _notificationSub;

  MusicHandler({MediaNotificationService? notificationService})
      : _notificationService = notificationService {
    _completedSub = player.stream.completed.listen((completed) {
      if (completed) next();
    });
    player.stream.playing.listen((playing) {
      _notificationService?.setPlaying(playing);
      _notify();
    });
    _errorSub = player.stream.error.listen((err) {
      if (err.isNotEmpty) debugPrint('MusicHandler player error: $err');
    });
    _notificationSub =
        _notificationService?.actionStream.listen((action) {
      switch (action) {
        case 'play':
          play();
        case 'pause':
          pause();
        case 'next':
          next();
        case 'previous':
          previous();
        case 'stop':
          stop();
      }
    });
    _loadRatings();
  }

  Future<void> _loadRatings() async {
    try {
      _ratings = await DatabaseService.getAllRatings();
    } catch (_) {
      _ratings = {};
    }
  }

  List<LocalTrack> get allTracks => List.unmodifiable(_allTracks);
  List<LocalTrack> get queueTracks => List.unmodifiable(_localQueue);
  int? get currentIndex => _currentIndex >= 0 ? _currentIndex : null;
  LocalTrack? get currentTrack =>
      _currentIndex >= 0 && _currentIndex < _localQueue.length
          ? _localQueue[_currentIndex]
          : null;
  PlaybackMode get mode => _mode;
  bool get isPlaying => player.state.playing;

  Duration get position => player.state.position;
  Duration get duration => player.state.duration;
  Stream<Duration> get positionStream => player.stream.position;
  Stream<Duration> get durationStream => player.stream.duration;
  Stream<bool> get playingStream => player.stream.playing;
  Stream<bool> get completedStream => player.stream.completed;

  int getRating(String trackId) => _ratings[trackId] ?? 0;

  Future<void> removeTrackFromMaster(String trackId) async {
    _allTracks.removeWhere((t) => t.id == trackId);
    _localQueue.removeWhere((t) => t.id == trackId);
    await DatabaseService.deleteScannedTrack(trackId);
    await DatabaseService.removeTrackFromAllGroups(trackId);
    _notify();
  }

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

  Future<void> play() async {
    if (player.state.playing) return;
    if (_currentIndex >= 0 && _currentIndex < _localQueue.length) {
      await player.play();
    } else if (_allTracks.isNotEmpty) {
      await playFromAll(0);
    }
  }

  Future<void> pause() async {
    await player.pause();
  }

  Future<void> stop() async {
    await player.stop();
    _currentIndex = -1;
    _notificationService?.stopPlayback();
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
      await player.open(Media(
        track.fileUri,
        extras: {
          'title': track.title,
          'artist': track.artist,
          'album': track.album,
        },
      ));
      await player.play();
      _notificationService?.startPlayback(track);
    } catch (e) {
      debugPrint('MusicHandler._playCurrent: $e');
    }
  }

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

    _shuffleCursor = 0;
  }

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
    await player.playOrPause();
  }

  void _notify() {
    // Subclasses or listeners can override this.
    // Currently used as a hook for PlaylistProvider.
  }

  Future<void> dispose() async {
    _completedSub?.cancel();
    _errorSub?.cancel();
    _notificationSub?.cancel();
    _notificationService?.dispose();
    await player.dispose();
  }
}
