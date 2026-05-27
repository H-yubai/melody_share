import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import '../models/local_track.dart';
import 'music_handler.dart';

class PlaylistProvider extends ChangeNotifier {
  final MusicHandler _handler;

  PlaylistProvider(this._handler) {
    _handler.player.processingStateStream.listen((_) => notifyListeners());
  }

  AudioPlayer get player => _handler.player;
  List<LocalTrack> get allTracks => _handler.allTracks;
  List<LocalTrack> get queueTracks => _handler.queueTracks;
  int? get currentIndex => _handler.currentIndex;
  LocalTrack? get currentTrack => _handler.currentTrack;
  PlaybackMode get mode => _handler.mode;
  bool get isPlaying => _handler.isPlaying;

  Stream<Duration> get positionStream => _handler.player.positionStream;
  Stream<Duration?> get durationStream => _handler.player.durationStream;
  Stream<PlayerState> get playerStateStream => _handler.player.playerStateStream;

  int getRating(String trackId) => _handler.getRating(trackId);
  Future<void> rateTrack(String trackId, int rating) async {
    await _handler.rateTrack(trackId, rating);
    notifyListeners();
  }

  Future<void> loadCachedTracks() => _handler.loadCachedTracks();
  Future<void> loadRatings() => _handler.loadRatings();
  void setAllTracks(List<LocalTrack> tracks) => _handler.setAllTracks(tracks);

  Future<void> playFromQueue(int index) => _handler.playFromQueue(index);
  Future<void> playFromAll(int index) => _handler.playFromAll(index);
  Future<void> playTracks(List<LocalTrack> tracks, {int startIndex = 0}) =>
      _handler.playTracks(tracks, startIndex: startIndex);

  void addToQueue(LocalTrack track) => _handler.addToQueue(track);
  void removeFromQueue(int index) => _handler.removeFromQueue(index);
  void clearQueue() => _handler.clearQueue();

  void cyclePlaybackMode() => _handler.cyclePlaybackMode();
  void setPlaybackMode(PlaybackMode mode) => _handler.setPlaybackMode(mode);

  Future<void> next() => _handler.next();
  Future<void> previous() => _handler.previous();
  Future<void> togglePlayPause() => _handler.togglePlayPause();
  Future<void> stop() => _handler.stop();
}
