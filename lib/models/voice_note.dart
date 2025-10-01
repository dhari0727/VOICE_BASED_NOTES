class VoiceNote {
  final int? id;
  final String title;
  final String description;
  final String filePath;
  final Duration duration;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? transcript;
  final String? languageCode;
  final bool isFavorite;
  final bool isPinned;
  final String? summary;
  final String? remoteId;
  final DateTime? lastSyncedAt;
  final bool isEncrypted;

  VoiceNote({
    this.id,
    required this.title,
    required this.description,
    required this.filePath,
    required this.duration,
    required this.tags,
    required this.createdAt,
    required this.updatedAt,
    this.transcript,
    this.languageCode,
    this.isFavorite = false,
    this.isPinned = false,
    this.summary,
    this.remoteId,
    this.lastSyncedAt,
    this.isEncrypted = false,
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
      'transcript': transcript,
      'languageCode': languageCode,
      'isFavorite': isFavorite ? 1 : 0,
      'isPinned': isPinned ? 1 : 0,
      'summary': summary,
      'remoteId': remoteId,
      'lastSyncedAt': lastSyncedAt?.millisecondsSinceEpoch,
      'isEncrypted': isEncrypted ? 1 : 0,
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
      transcript: map['transcript'],
      languageCode: map['languageCode'],
      isFavorite: (map['isFavorite'] ?? 0) == 1,
      isPinned: (map['isPinned'] ?? 0) == 1,
      summary: map['summary'],
      remoteId: map['remoteId'],
      lastSyncedAt: map['lastSyncedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['lastSyncedAt'])
          : null,
      isEncrypted: (map['isEncrypted'] ?? 0) == 1,
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
    String? transcript,
    String? languageCode,
    bool? isFavorite,
    bool? isPinned,
    String? summary,
    String? remoteId,
    DateTime? lastSyncedAt,
    bool? isEncrypted,
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
      transcript: transcript ?? this.transcript,
      languageCode: languageCode ?? this.languageCode,
      isFavorite: isFavorite ?? this.isFavorite,
      isPinned: isPinned ?? this.isPinned,
      summary: summary ?? this.summary,
      remoteId: remoteId ?? this.remoteId,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      isEncrypted: isEncrypted ?? this.isEncrypted,
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
      transcript,
      languageCode,
      isFavorite,
      isPinned,
      summary,
      remoteId,
      lastSyncedAt,
      isEncrypted,
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
