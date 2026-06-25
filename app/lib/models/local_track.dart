class LocalTrack {
  final String id;
  final String filePath;
  final String title;
  final String artist;
  final String extension;
  final int durationMs;
  final String album;

  const LocalTrack({
    required this.id,
    required this.filePath,
    required this.title,
    required this.artist,
    required this.extension,
    this.durationMs = 0,
    this.album = '',
  });

  String get displayTitle => title;
  String get displayArtist => artist.isEmpty ? 'Unknown Artist' : artist;
  String get displayDuration {
    if (durationMs <= 0) return '';
    final min = (durationMs ~/ 60000).toString();
    final sec = ((durationMs % 60000) ~/ 1000).toString().padLeft(2, '0');
    return '$min:$sec';
  }

  String get fileUri => Uri.file(filePath).toString();

  factory LocalTrack.fromJson(Map<String, dynamic> json) {
    return LocalTrack(
      id: json['id'] as String,
      filePath: json['filePath'] as String,
      title: json['title'] as String,
      artist: json['artist'] as String,
      extension: json['extension'] as String,
      durationMs: (json['durationMs'] as int?) ?? 0,
      album: (json['album'] as String?) ?? '',
    );
  }

  LocalTrack copyWith({
    String? id,
    String? filePath,
    String? title,
    String? artist,
    String? extension,
    int? durationMs,
    String? album,
  }) {
    return LocalTrack(
      id: id ?? this.id,
      filePath: filePath ?? this.filePath,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      extension: extension ?? this.extension,
      durationMs: durationMs ?? this.durationMs,
      album: album ?? this.album,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'filePath': filePath,
      'title': title,
      'artist': artist,
      'extension': extension,
      'durationMs': durationMs,
      'album': album,
    };
  }
}
