class VoiceNote {
  final int? id;
  final String title;
  final String description;
  final String filePath;
  final Duration duration;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;

  VoiceNote({
    this.id,
    required this.title,
    required this.description,
    required this.filePath,
    required this.duration,
    required this.tags,
    required this.createdAt,
    required this.updatedAt,
  });

  // Convert VoiceNote to Map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'filePath': filePath,
      'duration': duration.inSeconds,
      'tags': tags.join(','),
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  // Create VoiceNote from Map (database record)
  factory VoiceNote.fromMap(Map<String, dynamic> map) {
    return VoiceNote(
      id: map['id'],
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      filePath: map['filePath'] ?? '',
      duration: Duration(seconds: map['duration'] ?? 0),
      tags:
          map['tags']?.isNotEmpty == true
              ? map['tags'].split(',').cast<String>()
              : <String>[],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] ?? 0),
    );
  }

  // Create a copy with some fields updated
  VoiceNote copyWith({
    int? id,
    String? title,
    String? description,
    String? filePath,
    Duration? duration,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return VoiceNote(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      filePath: filePath ?? this.filePath,
      duration: duration ?? this.duration,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'VoiceNote{id: $id, title: $title, description: $description, '
        'filePath: $filePath, duration: $duration, tags: $tags, '
        'createdAt: $createdAt, updatedAt: $updatedAt}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is VoiceNote &&
        other.id == id &&
        other.title == title &&
        other.description == description &&
        other.filePath == filePath &&
        other.duration == duration &&
        _listEquals(other.tags, tags) &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      title,
      description,
      filePath,
      duration,
      tags,
      createdAt,
      updatedAt,
    );
  }

  // Helper method to compare lists
  bool _listEquals<T>(List<T>? a, List<T>? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    for (int index = 0; index < a.length; index += 1) {
      if (a[index] != b[index]) return false;
    }
    return true;
  }
}
