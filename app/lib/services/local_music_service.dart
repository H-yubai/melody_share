import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:metadata_god/metadata_god.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/local_track.dart';

class LocalMusicService {
  LocalMusicService._();

  static const _audioExtensions = <String>{'mp3', 'wav', 'flac', 'aac', 'ogg', 'm4a', 'wma'};

  static const _skipDirs = <String>{
    'Android', 'DCIM', 'Pictures', 'Movies', 'Documents', 'Downloads',
    'cache', 'data', 'obb', 'Caches', 'trash', 'temp', 'tmp',
    'Cache', 'Trash', 'Temp', 'Tmp', 'lost+found',
  };

  static Future<bool> requestPermission() async {
    if (kIsWeb) return false;
    if (!Platform.isAndroid) return true;

    if (await Permission.manageExternalStorage.request().isGranted) return true;
    if (await Permission.audio.request().isGranted) return true;
    if (await Permission.storage.request().isGranted) return true;
    return false;
  }

  static Future<List<LocalTrack>> quickScan({
    void Function(String dir, int count)? onProgress,
  }) async {
    final result = <LocalTrack>[];
    final paths = <String>{};

    if (Platform.isAndroid) {
      paths.addAll(['/storage/emulated/0/Music', '/storage/emulated/0/Download']);
      try {
        final list = await getExternalStorageDirectories(type: StorageDirectory.music);
        if (list != null) {
            for (final d in list) { paths.add(d.path); }
        }
      } catch (_) {}
    } else if (Platform.isWindows) {
      final home = Platform.environment['USERPROFILE'];
      if (home != null) {
        paths.add('$home\\Music');
        paths.add('$home\\Downloads');
      }
      for (final drive in _listWindowsDrives()) {
        for (final sub in ['Music', 'Download\\Music', 'Downloads\\Music']) {
          paths.add('$drive\\$sub');
        }
      }
    } else {
      final home = Platform.environment['HOME'];
      if (home != null) {
        paths.add('$home/Music');
        paths.add('$home/Downloads');
      }
    }

    for (final path in paths) {
      try {
        if (await Directory(path).exists()) {
          onProgress?.call(path, result.length);
          await _scanQuick(Directory(path), result, onProgress);
        }
      } catch (_) {}
    }

    return result;
  }

  static Future<List<LocalTrack>> scanDirectory(
    String dirPath, {
    void Function(String dir, int count)? onProgress,
  }) async {
    final result = <LocalTrack>[];
    final dir = Directory(dirPath);
    if (await dir.exists()) {
      onProgress?.call(dirPath, 0);
      await _scanDeep(dir, result, onProgress);
    }
    return result;
  }

  static List<String> _listWindowsDrives() {
    final result = <String>[];
    for (var c = 'C'.codeUnitAt(0); c <= 'Z'.codeUnitAt(0); c++) {
      final drive = String.fromCharCode(c);
      try {
        if (Directory('$drive:\\').existsSync()) {
          result.add('$drive:');
        }
      } catch (_) {}
    }
    return result;
  }

  static Future<List<LocalTrack>> fullScan({
    void Function(String dir, int count)? onProgress,
  }) async {
    final result = <LocalTrack>[];
    final paths = <String>{};

    if (Platform.isAndroid) {
      for (final type in StorageDirectory.values) {
        try {
          final list = await getExternalStorageDirectories(type: type);
          if (list != null) {
          for (final d in list) { paths.add(d.path); }
          }
        } catch (_) {}
      }
    } else if (Platform.isWindows) {
      final home = Platform.environment['USERPROFILE'];
      if (home != null) paths.add(home);
    } else {
      final home = Platform.environment['HOME'];
      if (home != null) paths.add(home);
    }

    for (final path in paths) {
      try {
        if (await Directory(path).exists()) {
          onProgress?.call(path, result.length);
          await _scanDeep(Directory(path), result, onProgress);
        }
      } catch (_) {}
    }

    return result;
  }

  static Future<void> _scanQuick(Directory dir, List<LocalTrack> result,
      void Function(String, int)? onProgress) async {
    try {
      await for (final entity
          in dir.list(recursive: true, followLinks: false).timeout(const Duration(seconds: 10))) {
        if (entity is File) await _tryAddFile(entity, result);
      }
    } catch (_) {}
  }

  static Future<void> _scanDeep(Directory dir, List<LocalTrack> result,
      void Function(String, int)? onProgress) async {
    try {
      await for (final entity
          in dir.list(followLinks: false).timeout(const Duration(seconds: 10))) {
        if (entity is File) {
          await _tryAddFile(entity, result);
        } else if (entity is Directory) {
          final name = entity.uri.pathSegments.last;
          if (!name.startsWith('.') && !_skipDirs.contains(name)) {
            onProgress?.call(entity.path, result.length);
            await _scanDeep(entity, result, onProgress);
          }
        }
      }
    } catch (_) {}
  }

  static Future<void> _tryAddFile(File file, List<LocalTrack> result) async {
    try {
      final ext = file.path.split('.').last.toLowerCase();
      if (!_audioExtensions.contains(ext)) return;
      final track = await _parseFile(file);
      if (track != null) result.add(track);
    } catch (_) {}
  }

  static Future<LocalTrack?> _parseFile(File file) async {
    try {
      final uri = file.uri;
      final name = uri.pathSegments.last;
      final nameWithoutExt = name.substring(0, name.lastIndexOf('.'));

      String title = nameWithoutExt.replaceAll(RegExp(r'[_.]'), ' ');
      String artist = '';
      String album = '';
      int durationMs = 0;

      final dashIdx = nameWithoutExt.indexOf(' - ');
      if (dashIdx > 0) {
        artist = nameWithoutExt.substring(0, dashIdx).trim();
        title = nameWithoutExt.substring(dashIdx + 3).trim();
      }

      title = title.replaceAll(RegExp(r'\s*\[.*?\]\s*$'), '').trim();

      final ext = name.split('.').last;

      try {
        final meta = await MetadataGod.readMetadata(file: file.path);
        if ((meta.title ?? '').isNotEmpty) title = meta.title!;
        if ((meta.artist ?? '').isNotEmpty) artist = meta.artist!;
        if ((meta.album ?? '').isNotEmpty) album = meta.album!;
        if (meta.durationMs != null && meta.durationMs! > 0) {
          durationMs = meta.durationMs!.toInt();
        }
      } catch (_) {}

      return LocalTrack(
        id: nameWithoutExt.hashCode.toString(),
        filePath: file.path,
        title: title,
        artist: artist,
        extension: ext,
        durationMs: durationMs,
        album: album,
      );
    } catch (_) {
      return null;
    }
  }
}
