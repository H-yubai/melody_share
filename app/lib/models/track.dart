class Track {
  final String id;
  final String title;
  final String artist;
  final String filename;
  final String uploadedAt;

  const Track({
    required this.id,
    required this.title,
    required this.artist,
    required this.filename,
    required this.uploadedAt,
  });

  factory Track.fromJson(Map<String, dynamic> json) {
    return Track(
      id: json['id'] as String,
      title: json['title'] as String,
      artist: json['artist'] as String? ?? '',
      filename: json['filename'] as String,
      uploadedAt: json['uploaded_at'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'filename': filename,
      'uploaded_at': uploadedAt,
    };
  }
}
