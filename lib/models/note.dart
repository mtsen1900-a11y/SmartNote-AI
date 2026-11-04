class Note {
  const Note({
    required this.id,
    required this.title,
    required this.content,
    required this.tags,
    required this.createdAt,
    required this.updatedAt,
    this.folder = 'Cá nhân',
    this.isPinned = false,
  });

  final String id;
  final String title;
  final String content;
  final List<String> tags;
  final String folder;
  final bool isPinned;
  final DateTime createdAt;
  final DateTime updatedAt;

  Note copyWith({
    String? title,
    String? content,
    List<String>? tags,
    String? folder,
    bool? isPinned,
    DateTime? updatedAt,
  }) {
    return Note(
      id: id,
      title: title ?? this.title,
      content: content ?? this.content,
      tags: tags ?? this.tags,
      folder: folder ?? this.folder,
      isPinned: isPinned ?? this.isPinned,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'content': content,
        'tags': tags,
        'folder': folder,
        'isPinned': isPinned,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory Note.fromJson(Map<String, dynamic> json) => Note(
        id: json['id'] as String,
        title: json['title'] as String? ?? '',
        content: json['content'] as String? ?? '',
        tags: (json['tags'] as List<dynamic>? ?? [])
            .map((tag) => tag.toString())
            .toList(),
        folder: json['folder'] as String? ?? 'Cá nhân',
        isPinned: json['isPinned'] as bool? ?? false,
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String)
            : DateTime.now(),
        updatedAt: json['updatedAt'] != null
            ? DateTime.parse(json['updatedAt'] as String)
            : DateTime.now(),
      );

  String get displayTitle =>
      title.trim().isEmpty ? 'Ghi chú chưa có tiêu đề' : title.trim();

  int get wordCount {
    final trimmed = content.trim();
    if (trimmed.isEmpty) return 0;
    return trimmed.split(RegExp(r'\s+')).length;
  }
}
