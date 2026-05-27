import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:metadata_god/metadata_god.dart';
import 'app.dart';
import 'services/music_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  await MetadataGod.initialize();

  final handler = MusicHandler();
  runApp(MelodyShareApp(handler: handler));
}
