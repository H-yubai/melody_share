import 'dart:io';

import 'package:flutter/material.dart';
import 'package:guangling/config/log_config.dart';
import 'package:logging/logging.dart';
import 'package:media_kit/media_kit.dart';
import 'package:permission_handler/permission_handler.dart';
import 'app.dart';
import 'services/api_service.dart';
import 'services/media_notification_service.dart';
import 'services/music_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  ApiService.init();

  // 初始化日志
  initLog();

  final notificationService = MediaNotificationService();
  notificationService.initialize();

  final handler = MusicHandler(notificationService: notificationService);
  runApp(MelodyShareApp(handler: handler));

  // Request notification permission on Android 13+ (best effort)
  if (Platform.isAndroid) {
    Permission.notification.request();
  }
}
