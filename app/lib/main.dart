import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'app.dart';
import 'services/music_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  late final MusicHandler handler;

  try {
    handler = await AudioService.init(
      builder: () => MusicHandler(),
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.melody_share.channel',
        androidNotificationChannelName: 'Melody Share',
        androidNotificationOngoing: true,
        androidStopForegroundOnPause: true,
      ),
    ).timeout(const Duration(seconds: 5));
  } catch (_) {
    handler = MusicHandler();
  }

  runApp(MelodyShareApp(handler: handler));
}
