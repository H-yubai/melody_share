class Group {
  final int id;
  final String name;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int trackCount;

  const Group({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    this.trackCount = 0,
  });

  factory Group.fromMap(Map<String, dynamic> map) {
    return Group(
      id: map['id'] as int,
      name: map['name'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      trackCount: (map['track_count'] as int?) ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'updated_at': updatedAt.toIso8601String(),
  };
}
