import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/local_track.dart';

class MediaStoreScanner {
  MediaStoreScanner._();

  static const _channel = MethodChannel('guangling/mediastore');

  static Future<bool> deleteAudioFile(String filePath) async {
    if (kIsWeb || !Platform.isAndroid) return false;
    try {
      final result = await _channel.invokeMethod<bool>('deleteAudioFile', {
        'filePath': filePath,
      });
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<List<LocalTrack>> scanAudio({
    void Function(String dir, int count)? onProgress,
  }) async {
    if (kIsWeb || !Platform.isAndroid) return [];

    try {
      onProgress?.call('MediaStore', 0);
      final result = await _channel.invokeMethod<List<dynamic>>('scanAudio');
      if (result == null) return [];

      final tracks = <LocalTrack>[];
      for (final r in result) {
        try {
          final map = Map<String, dynamic>.from(r as Map);
          final filePath = map['filePath'] as String? ?? '';
          if (filePath.isEmpty) continue;
          tracks.add(
            LocalTrack(
              id: map['id'] as String? ?? filePath.hashCode.toString(),
              filePath: filePath,
              title: map['title'] as String? ?? '',
              artist: map['artist'] as String? ?? '',
              extension: map['extension'] as String? ?? '',
              durationMs: map['durationMs'] as int? ?? 0,
              album: map['album'] as String? ?? '',
            ),
          );
        } catch (_) {}
      }
      return tracks;
    } catch (_) {
      return [];
    }
  }
}
