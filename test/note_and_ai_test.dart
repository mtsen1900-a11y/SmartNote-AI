import 'package:flutter_test/flutter_test.dart';
import 'package:smart_note_ai/models/note.dart';
import 'package:smart_note_ai/services/demo_ai_service.dart';

void main() {
  final now = DateTime(2026, 1, 1);
  final note = Note(
    id: 'test',
    title: 'Flutter AI',
    content: 'Xây dựng giao diện Flutter. Tích hợp LLM API. Lưu trên PostgreSQL.',
    tags: ['project'],
    createdAt: now,
    updatedAt: now,
  );

  test('Note serialize / deserialize', () {
    final restored = Note.fromJson(note.toJson());
    expect(restored.title, note.title);
    expect(restored.content, note.content);
    expect(restored.tags, note.tags);
    expect(restored.wordCount, 12);
  });

  test('Demo AI sinh tóm tắt và thẻ offline', () {
    expect(DemoAiService.summarize(note), contains('Flutter'));
    final tags = DemoAiService.suggestTags(note);
    expect(tags, contains('flutter'));
    expect(tags, contains('ai'));
    expect(tags, contains('database'));
  });
}
