import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart' as ffi;

import '../models/group.dart';
import '../models/local_track.dart';

class DatabaseService {
  DatabaseService._();
  static Future<Database>? _dbFuture;

  static Future<Database> get database async {
    _dbFuture ??= _open();
    return _dbFuture!;
  }

  static Future<Database> _open() async {
    // Use sqflite_common_ffi only on desktop (Windows, macOS, Linux)
    // On Android/iOS the platform sqflite works out of the box
    if (!kIsWeb && !Platform.isAndroid && !Platform.isIOS) {
      ffi.sqfliteFfiInit();
      databaseFactory = ffi.databaseFactoryFfi;
    }
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'melody_share.db');
    return _openDb(path);
  }

  static Future<Database> _openDb(String path) {
    return openDatabase(
      path,
      version: 4,
      onConfigure: (db) async {
        await db.rawQuery('PRAGMA busy_timeout = 5000');
      },
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE song_groups (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        created_at TEXT NOT NULL DEFAULT (datetime('now')),
        updated_at TEXT NOT NULL DEFAULT (datetime('now'))
      )
    ''');
    await db.execute('''
      CREATE TABLE group_tracks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        group_id INTEGER NOT NULL,
        track_id TEXT NOT NULL,
        track_path TEXT NOT NULL,
        track_title TEXT NOT NULL,
        track_artist TEXT DEFAULT '',
        track_album TEXT DEFAULT '',
        track_duration_ms INTEGER DEFAULT 0,
        track_ext TEXT NOT NULL,
        sort_order INTEGER NOT NULL DEFAULT 0,
        added_at TEXT NOT NULL DEFAULT (datetime('now')),
        FOREIGN KEY (group_id) REFERENCES song_groups(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE INDEX idx_group_tracks_group ON group_tracks(group_id)
    ''');
    await db.execute('''
      CREATE INDEX idx_group_tracks_track ON group_tracks(track_id)
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS scanned_tracks (
        id TEXT PRIMARY KEY,
        file_path TEXT NOT NULL,
        title TEXT NOT NULL,
        artist TEXT DEFAULT '',
        album TEXT DEFAULT '',
        duration_ms INTEGER DEFAULT 0,
        ext TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS track_ratings (
        track_id TEXT PRIMARY KEY,
        rating INTEGER NOT NULL DEFAULT 0,
        updated_at TEXT NOT NULL DEFAULT (datetime('now'))
      )
    ''');
  }

  static Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS scanned_tracks (
          id TEXT PRIMARY KEY,
          file_path TEXT NOT NULL,
          title TEXT NOT NULL,
          artist TEXT DEFAULT '',
          ext TEXT NOT NULL
        )
      ''');
    }
    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS track_ratings (
          track_id TEXT PRIMARY KEY,
          rating INTEGER NOT NULL DEFAULT 0,
          updated_at TEXT NOT NULL DEFAULT (datetime('now'))
        )
      ''');
    }
    if (oldVersion < 4) {
      try {
        await db.execute('ALTER TABLE scanned_tracks ADD COLUMN album TEXT DEFAULT \'\'');
      } catch (_) {}
      try {
        await db.execute('ALTER TABLE scanned_tracks ADD COLUMN duration_ms INTEGER DEFAULT 0');
      } catch (_) {}
      try {
        await db.execute('ALTER TABLE group_tracks ADD COLUMN track_album TEXT DEFAULT \'\'');
      } catch (_) {}
      try {
        await db.execute('ALTER TABLE group_tracks ADD COLUMN track_duration_ms INTEGER DEFAULT 0');
      } catch (_) {}
    }
  }

  // ─── Groups ─────────────────────────────────────────────────

  static Future<List<Group>> getGroups() async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT sg.*, COUNT(gt.id) AS track_count
      FROM song_groups sg
      LEFT JOIN group_tracks gt ON gt.group_id = sg.id
      GROUP BY sg.id
      ORDER BY sg.updated_at DESC
    ''');
    return rows.map((r) => Group.fromMap(r)).toList();
  }

  static Future<int> createGroup(String name) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    return db.insert('song_groups', {
      'name': name,
      'created_at': now,
      'updated_at': now,
    });
  }

  static Future<void> renameGroup(int id, String name) async {
    final db = await database;
    await db.update(
      'song_groups',
      {'name': name, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<void> deleteGroup(int id) async {
    final db = await database;
    await db.delete('group_tracks', where: 'group_id = ?', whereArgs: [id]);
    await db.delete('song_groups', where: 'id = ?', whereArgs: [id]);
  }

  // ─── Group Tracks ────────────────────────────────────────────

  static Future<List<LocalTrack>> getGroupTracks(int groupId) async {
    final db = await database;
    final rows = await db.query(
      'group_tracks',
      where: 'group_id = ?',
      whereArgs: [groupId],
      orderBy: 'sort_order ASC, added_at ASC',
    );
    return rows.map((r) => LocalTrack(
      id: r['track_id'] as String,
      filePath: r['track_path'] as String,
      title: r['track_title'] as String,
      artist: r['track_artist'] as String,
      extension: r['track_ext'] as String,
      album: (r['track_album'] as String?) ?? '',
      durationMs: (r['track_duration_ms'] as int?) ?? 0,
    )).toList();
  }

  static Future<bool> isTrackInGroup(int groupId, String trackId) async {
    final db = await database;
    final result = await db.query(
      'group_tracks',
      where: 'group_id = ? AND track_id = ?',
      whereArgs: [groupId, trackId],
      limit: 1,
    );
    return result.isNotEmpty;
  }

  static Future<Set<String>> getGroupTrackIds(int groupId) async {
    final db = await database;
    final rows = await db.query(
      'group_tracks',
      columns: ['track_id'],
      where: 'group_id = ?',
      whereArgs: [groupId],
    );
    return rows.map((r) => r['track_id'] as String).toSet();
  }

  static Future<void> addTrackToGroup(int groupId, LocalTrack track) async {
    final already = await isTrackInGroup(groupId, track.id);
    if (already) return;
    final db = await database;
    final rows = await db.rawQuery(
      'SELECT COALESCE(MAX(sort_order), -1) FROM group_tracks WHERE group_id = ?',
      [groupId],
    );
    final maxOrder = rows.isNotEmpty ? rows.first.values.first as int? : null;
    await db.insert('group_tracks', {
      'group_id': groupId,
      'track_id': track.id,
      'track_path': track.filePath,
      'track_title': track.title,
      'track_artist': track.artist,
      'track_album': track.album,
      'track_duration_ms': track.durationMs,
      'track_ext': track.extension,
      'sort_order': (maxOrder ?? -1) + 1,
    });
    await db.update(
      'song_groups',
      {'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [groupId],
    );
  }

  static Future<void> removeTrackFromAllGroups(String trackId) async {
    final db = await database;
    await db.delete('group_tracks', where: 'track_id = ?', whereArgs: [trackId]);
  }

  static Future<void> removeTrackFromGroup(int groupId, String trackId) async {
    final db = await database;
    await db.delete(
      'group_tracks',
      where: 'group_id = ? AND track_id = ?',
      whereArgs: [groupId, trackId],
    );
    await db.update(
      'song_groups',
      {'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [groupId],
    );
  }

  static Future<void> reorderTrack(int groupId, String trackId, int newOrder) async {
    final db = await database;
    await db.update(
      'group_tracks',
      {'sort_order': newOrder},
      where: 'group_id = ? AND track_id = ?',
      whereArgs: [groupId, trackId],
    );
  }

  // ─── Scanned Tracks ──────────────────────────────────────────

  static Future<void> deleteScannedTrack(String trackId) async {
    final db = await database;
    await db.delete('scanned_tracks', where: 'id = ?', whereArgs: [trackId]);
  }

  static Future<void> saveScannedTracks(List<LocalTrack> tracks) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('scanned_tracks');
      final batch = txn.batch();
      for (final track in tracks) {
        batch.insert('scanned_tracks', {
          'id': track.id,
          'file_path': track.filePath,
          'title': track.title,
          'artist': track.artist,
          'album': track.album,
          'duration_ms': track.durationMs,
          'ext': track.extension,
        });
      }
      await batch.commit(noResult: true);
    });
  }

  static Future<List<LocalTrack>> loadScannedTracks() async {
    final db = await database;
    final rows = await db.query('scanned_tracks', orderBy: 'rowid ASC');
    return rows.map((r) => LocalTrack(
      id: r['id'] as String,
      filePath: r['file_path'] as String,
      title: r['title'] as String,
      artist: r['artist'] as String,
      extension: r['ext'] as String,
      album: (r['album'] as String?) ?? '',
      durationMs: (r['duration_ms'] as int?) ?? 0,
    )).toList();
  }

  // ─── Track Ratings ────────────────────────────────────────────

  static Future<int> getRating(String trackId) async {
    final db = await database;
    final rows = await db.query(
      'track_ratings',
      columns: ['rating'],
      where: 'track_id = ?',
      whereArgs: [trackId],
    );
    if (rows.isEmpty) return 0;
    return rows.first['rating'] as int;
  }

  static Future<void> setRating(String trackId, int rating) async {
    final db = await database;
    rating = rating.clamp(0, 3);
    await db.insert(
      'track_ratings',
      {
        'track_id': trackId,
        'rating': rating,
        'updated_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<Map<String, int>> getAllRatings() async {
    final db = await database;
    final rows = await db.query('track_ratings');
    return {for (final r in rows) r['track_id'] as String: r['rating'] as int};
  }
}
