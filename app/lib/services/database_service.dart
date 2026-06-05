import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

import '../models/group.dart';
import '../models/local_track.dart';

class DatabaseService {
  DatabaseService._();
  static Database? _db;
  static const int _targetVersion = 4;

  static Future<Database> get database async {
    _db ??= await _open();
    return _db!;
  }

  static Future<Database> _open() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, 'guangling.db');
    final db = sqlite3.open(path);
    db.execute('PRAGMA busy_timeout = 5000');
    db.execute('PRAGMA foreign_keys = ON');

    final currentVersion = db.userVersion;
    if (currentVersion == 0) {
      _createTables(db);
    }
    if (currentVersion < _targetVersion) {
      _migrate(db, currentVersion);
    }
    if (currentVersion != _targetVersion) {
      db.userVersion = _targetVersion;
    }
    return db;
  }

  static List<Map<String, dynamic>> _toList(ResultSet rs) {
    final cols = rs.columnNames;
    return [
      for (final row in rs) {for (final name in cols) name: row[name]},
    ];
  }

  static void _createTables(Database db) {
    db.execute('''
      CREATE TABLE IF NOT EXISTS song_groups (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        created_at TEXT NOT NULL DEFAULT (datetime('now')),
        updated_at TEXT NOT NULL DEFAULT (datetime('now'))
      )
    ''');
    db.execute('''
      CREATE TABLE IF NOT EXISTS group_tracks (
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
    db.execute(
      'CREATE INDEX IF NOT EXISTS idx_group_tracks_group ON group_tracks(group_id)',
    );
    db.execute(
      'CREATE INDEX IF NOT EXISTS idx_group_tracks_track ON group_tracks(track_id)',
    );
    db.execute('''
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
    db.execute('''
      CREATE TABLE IF NOT EXISTS track_ratings (
        track_id TEXT PRIMARY KEY,
        rating INTEGER NOT NULL DEFAULT 0,
        updated_at TEXT NOT NULL DEFAULT (datetime('now'))
      )
    ''');
  }

  static void _migrate(Database db, int oldVersion) {
    if (oldVersion < 2) {
      db.execute('''
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
      db.execute('''
        CREATE TABLE IF NOT EXISTS track_ratings (
          track_id TEXT PRIMARY KEY,
          rating INTEGER NOT NULL DEFAULT 0,
          updated_at TEXT NOT NULL DEFAULT (datetime('now'))
        )
      ''');
    }
    if (oldVersion < 4) {
      for (final sql in [
        "ALTER TABLE scanned_tracks ADD COLUMN album TEXT DEFAULT ''",
        'ALTER TABLE scanned_tracks ADD COLUMN duration_ms INTEGER DEFAULT 0',
        "ALTER TABLE group_tracks ADD COLUMN track_album TEXT DEFAULT ''",
        'ALTER TABLE group_tracks ADD COLUMN track_duration_ms INTEGER DEFAULT 0',
      ]) {
        try {
          db.execute(sql);
        } catch (_) {}
      }
    }
  }

  // ─── Groups ─────────────────────────────────────────────────

  static Future<List<Group>> getGroups() async {
    final db = await database;
    final rows = _toList(
      db.select('''
      SELECT sg.*, COUNT(gt.id) AS track_count
      FROM song_groups sg
      LEFT JOIN group_tracks gt ON gt.group_id = sg.id
      GROUP BY sg.id
      ORDER BY sg.updated_at DESC
    '''),
    );
    return rows.map((r) => Group.fromMap(r)).toList();
  }

  static Future<int> createGroup(String name) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    db.execute(
      'INSERT INTO song_groups(name, created_at, updated_at) VALUES (?, ?, ?)',
      [name, now, now],
    );
    return db.lastInsertRowId;
  }

  static Future<void> renameGroup(int id, String name) async {
    final db = await database;
    db.execute('UPDATE song_groups SET name = ?, updated_at = ? WHERE id = ?', [
      name,
      DateTime.now().toIso8601String(),
      id,
    ]);
  }

  static Future<void> deleteGroup(int id) async {
    final db = await database;
    db.execute('DELETE FROM group_tracks WHERE group_id = ?', [id]);
    db.execute('DELETE FROM song_groups WHERE id = ?', [id]);
  }

  // ─── Group Tracks ────────────────────────────────────────────

  static Future<List<LocalTrack>> getGroupTracks(int groupId) async {
    final db = await database;
    final rows = _toList(
      db.select(
        'SELECT * FROM group_tracks WHERE group_id = ? ORDER BY sort_order ASC, added_at ASC',
        [groupId],
      ),
    );
    return rows
        .map(
          (r) => LocalTrack(
            id: r['track_id'] as String,
            filePath: r['track_path'] as String,
            title: r['track_title'] as String,
            artist: r['track_artist'] as String,
            extension: r['track_ext'] as String,
            album: (r['track_album'] as String?) ?? '',
            durationMs: (r['track_duration_ms'] as int?) ?? 0,
          ),
        )
        .toList();
  }

  static Future<bool> isTrackInGroup(int groupId, String trackId) async {
    final db = await database;
    final result = db.select(
      'SELECT 1 FROM group_tracks WHERE group_id = ? AND track_id = ? LIMIT 1',
      [groupId, trackId],
    );
    return result.isNotEmpty;
  }

  static Future<Set<String>> getGroupTrackIds(int groupId) async {
    final db = await database;
    final rows = _toList(
      db.select('SELECT track_id FROM group_tracks WHERE group_id = ?', [
        groupId,
      ]),
    );
    return rows.map((r) => r['track_id'] as String).toSet();
  }

  static Future<void> addTrackToGroup(int groupId, LocalTrack track) async {
    if (await isTrackInGroup(groupId, track.id)) return;
    final db = await database;
    final maxOrder =
        db
                .select(
                  'SELECT COALESCE(MAX(sort_order), -1) FROM group_tracks WHERE group_id = ?',
                  [groupId],
                )
                .first
                .columnAt(0)
            as int;
    db.execute(
      '''
      INSERT INTO group_tracks(
        group_id, track_id, track_path, track_title, track_artist,
        track_album, track_duration_ms, track_ext, sort_order
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
    ''',
      [
        groupId,
        track.id,
        track.filePath,
        track.title,
        track.artist,
        track.album,
        track.durationMs,
        track.extension,
        maxOrder + 1,
      ],
    );
    db.execute('UPDATE song_groups SET updated_at = ? WHERE id = ?', [
      DateTime.now().toIso8601String(),
      groupId,
    ]);
  }

  static Future<void> removeTrackFromAllGroups(String trackId) async {
    final db = await database;
    db.execute('DELETE FROM group_tracks WHERE track_id = ?', [trackId]);
  }

  static Future<void> removeTrackFromGroup(int groupId, String trackId) async {
    final db = await database;
    db.execute('DELETE FROM group_tracks WHERE group_id = ? AND track_id = ?', [
      groupId,
      trackId,
    ]);
    db.execute('UPDATE song_groups SET updated_at = ? WHERE id = ?', [
      DateTime.now().toIso8601String(),
      groupId,
    ]);
  }

  static Future<void> reorderTrack(
    int groupId,
    String trackId,
    int newOrder,
  ) async {
    final db = await database;
    db.execute(
      'UPDATE group_tracks SET sort_order = ? WHERE group_id = ? AND track_id = ?',
      [newOrder, groupId, trackId],
    );
  }

  // ─── Scanned Tracks ──────────────────────────────────────────

  static Future<void> deleteScannedTrack(String trackId) async {
    final db = await database;
    db.execute('DELETE FROM scanned_tracks WHERE id = ?', [trackId]);
  }

  static Future<void> saveScannedTracks(List<LocalTrack> tracks) async {
    final db = await database;
    db.execute('BEGIN');
    try {
      db.execute('DELETE FROM scanned_tracks');
      for (final track in tracks) {
        db.execute(
          'INSERT INTO scanned_tracks(id, file_path, title, artist, album, duration_ms, ext) VALUES (?, ?, ?, ?, ?, ?, ?)',
          [
            track.id,
            track.filePath,
            track.title,
            track.artist,
            track.album,
            track.durationMs,
            track.extension,
          ],
        );
      }
      db.execute('COMMIT');
    } catch (e) {
      db.execute('ROLLBACK');
      rethrow;
    }
  }

  static Future<List<LocalTrack>> loadScannedTracks() async {
    final db = await database;
    final rows = _toList(
      db.select('SELECT * FROM scanned_tracks ORDER BY rowid ASC'),
    );
    return rows
        .map(
          (r) => LocalTrack(
            id: r['id'] as String,
            filePath: r['file_path'] as String,
            title: r['title'] as String,
            artist: r['artist'] as String,
            extension: r['ext'] as String,
            album: (r['album'] as String?) ?? '',
            durationMs: (r['duration_ms'] as int?) ?? 0,
          ),
        )
        .toList();
  }

  // ─── Track Ratings ────────────────────────────────────────────

  static Future<int> getRating(String trackId) async {
    final db = await database;
    final rows = _toList(
      db.select('SELECT rating FROM track_ratings WHERE track_id = ?', [
        trackId,
      ]),
    );
    if (rows.isEmpty) return 0;
    return rows.first['rating'] as int;
  }

  static Future<void> setRating(String trackId, int rating) async {
    final db = await database;
    rating = rating.clamp(0, 3);
    db.execute(
      'INSERT OR REPLACE INTO track_ratings(track_id, rating, updated_at) VALUES (?, ?, ?)',
      [trackId, rating, DateTime.now().toIso8601String()],
    );
  }

  static Future<Map<String, int>> getAllRatings() async {
    final db = await database;
    final rows = _toList(
      db.select('SELECT track_id, rating FROM track_ratings'),
    );
    return {for (final r in rows) r['track_id'] as String: r['rating'] as int};
  }
}
