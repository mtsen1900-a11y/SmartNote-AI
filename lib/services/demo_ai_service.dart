import '../models/note.dart';

enum AiAction { summarize, keyPoints, suggestTags }

/// Giao dien AI ban dau chay demo offline.
/// KHONG goi LLM; thay class nay bang API thuc khi co backend.
class DemoAiService {
  static List<String> _sentences(String content) {
    return content
        .replaceAll('\n', ' ')
        .split(RegExp(r'[.!?]+\s*'))
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList();
  }

  static String summarize(Note note) {
    final sentences = _sentences(note.content);
    if (sentences.isEmpty) return 'Hãy viết nội dung trước khi tóm tắt.';
    return '${sentences.take(2).join('. ')}.';
  }

  static List<String> keyPoints(Note note) {
    final paragraphs = note.content
        .split(RegExp(r'\n+'))
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList();
    if (paragraphs.length >= 2) return paragraphs.take(4).toList();
    return _sentences(note.content).take(4).toList();
  }

  static List<String> suggestTags(Note note) {
    final text = '${note.title} ${note.content}'.toLowerCase();
    const keywords = <String, List<String>>{
      'flutter': ['flutter', 'dart', 'responsive'],
      'ai': ['ai', 'llm', 'gpt', 'trí tuệ nhân tạo', 'tóm tắt'],
      'backend': ['spring boot', 'backend', 'api', 'server'],
      'database': ['postgresql', 'sql', 'cơ sở dữ liệu'],
      'design': ['figma', 'giao diện', 'thiết kế', 'ui'],
      'planning': ['kế hoạch', 'triển khai', 'giai đoạn', 'mục tiêu'],
      'study': ['học tập', 'bài tập', 'ôn thi', 'môn học'],
    };
    final result = <String>[];
    for (final entry in keywords.entries) {
      if (entry.value.any(text.contains)) result.add(entry.key);
    }
    if (result.isEmpty) result.addAll(note.tags.take(3));
    if (result.isEmpty) result.add('general');
    return result.take(5).toList();
  }
}
