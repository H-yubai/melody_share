import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/local_track.dart';
import '../services/music_handler.dart';

class PlaylistProvider extends ChangeNotifier {
  final MusicHandler _handler;

  PlaylistProvider(this._handler) {
    _handler.playingStream.listen((_) => notifyListeners());
    _handler.completedStream.listen((_) => notifyListeners());
  }

  Future<void> requestNotificationPermission() async {
    if (!Platform.isAndroid) return;
    if (await Permission.notification.status.isGranted) return;
    await Permission.notification.request();
  }

  List<LocalTrack> get allTracks => _handler.allTracks;
  List<LocalTrack> get queueTracks => _handler.queueTracks;
  int? get currentIndex => _handler.currentIndex;
  LocalTrack? get currentTrack => _handler.currentTrack;
  PlaybackMode get mode => _handler.mode;
  bool get isPlaying => _handler.isPlaying;

  Duration get position => _handler.position;
  Duration get duration => _handler.duration;
  Stream<Duration> get positionStream => _handler.player.stream.position;
  Stream<Duration> get durationStream => _handler.player.stream.duration;
  Stream<bool> get playingStream => _handler.player.stream.playing;

  int getRating(String trackId) => _handler.getRating(trackId);
  Future<void> rateTrack(String trackId, int rating) async {
    await _handler.rateTrack(trackId, rating);
    notifyListeners();
  }

  Future<void> seek(Duration position) => _handler.player.seek(position);

  Future<void> removeTrackFromMaster(String trackId) async {
    await _handler.removeTrackFromMaster(trackId);
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

  void cyclePlaybackMode() {
    _handler.cyclePlaybackMode();
    notifyListeners();
  }

  void setPlaybackMode(PlaybackMode mode) {
    _handler.setPlaybackMode(mode);
    notifyListeners();
  }

  Future<void> next() => _handler.next();
  Future<void> previous() => _handler.previous();
  Future<void> togglePlayPause() => _handler.togglePlayPause();
  Future<void> stop() => _handler.stop();
}
