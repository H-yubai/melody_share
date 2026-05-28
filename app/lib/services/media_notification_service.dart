import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';

import '../models/local_track.dart';

class MediaNotificationService {
  static const _channel = MethodChannel('melody_share/media_session');

  bool _initialized = false;
  bool _serviceStarted = false;

  final StreamController<String> _actionController =
      StreamController<String>.broadcast();

  Stream<String> get actionStream => _actionController.stream;

  void initialize() {
    if (_initialized) return;
    _initialized = true;

    if (!Platform.isAndroid) return;

    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'play':
          _actionController.add('play');
        case 'pause':
          _actionController.add('pause');
        case 'next':
          _actionController.add('next');
        case 'previous':
          _actionController.add('previous');
        case 'stop':
          _actionController.add('stop');
      }
    });
  }

  void startPlayback(LocalTrack track) {
    if (!Platform.isAndroid) return;

    try {
      _channel.invokeMethod('start', {
        'title': track.title,
        'artist': track.artist,
        'album': track.album,
        'albumArtPath': null,
      });
      _serviceStarted = true;
    } catch (_) {}
  }

  void updateTrack(LocalTrack track) {
    if (!Platform.isAndroid || !_serviceStarted) return;

    try {
      _channel.invokeMethod('update', {
        'title': track.title,
        'artist': track.artist,
        'album': track.album,
        'albumArtPath': null,
      });
    } catch (_) {}
  }

  void setPlaying(bool playing) {
    if (!Platform.isAndroid || !_serviceStarted) return;

    try {
      _channel.invokeMethod('setPlaying', playing);
    } catch (_) {}
  }

  void stopPlayback() {
    if (!Platform.isAndroid || !_serviceStarted) return;

    try {
      _channel.invokeMethod('stop');
      _serviceStarted = false;
    } catch (_) {}
  }

  void dispose() {
    stopPlayback();
    _actionController.close();
  }
}
