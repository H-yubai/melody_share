class LocalTrack {
  final String id;
  final String filePath;
  final String title;
  final String artist;
  final String extension;

  const LocalTrack({
    required this.id,
    required this.filePath,
    required this.title,
    required this.artist,
    required this.extension,
  });

  String get displayTitle => title;
  String get displayArtist => artist.isEmpty ? 'Unknown Artist' : artist;

  factory LocalTrack.fromJson(Map<String, dynamic> json) {
    return LocalTrack(
      id: json['id'] as String,
      filePath: json['filePath'] as String,
      title: json['title'] as String,
      artist: json['artist'] as String,
      extension: json['extension'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'filePath': filePath,
      'title': title,
      'artist': artist,
      'extension': extension,
    };
  }
}
