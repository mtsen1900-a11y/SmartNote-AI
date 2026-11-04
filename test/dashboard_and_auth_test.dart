import 'package:flutter_test/flutter_test.dart';
import 'package:smart_note_ai/models/note.dart';
import 'package:smart_note_ai/services/auth_service.dart';

void main() {
  group('SmartNoteAI Next-Gen Platform Tests', () {
    test('1. Note Model attributes (Folder, isPinned, WordCount, JSON serialization)', () {
      final note = Note(
        id: '101',
        title: 'Ghi chú kiến trúc',
        content: 'Nội dung kiến trúc với checklist:\n- [ ] Task 1\n- [ ] Task 2',
        folder: 'Kiến trúc',
        tags: const ['tech', 'flutter'],
        isPinned: true,
        createdAt: DateTime(2026, 11, 4),
        updatedAt: DateTime(2026, 11, 4, 1, 0),
      );

      expect(note.folder, 'Kiến trúc');
      expect(note.isPinned, isTrue);
      expect(note.wordCount, greaterThan(5));

      final json = note.toJson();
      expect(json['folder'], 'Kiến trúc');
      expect(json['isPinned'], isTrue);

      final deserialized = Note.fromJson(json);
      expect(deserialized.id, '101');
      expect(deserialized.folder, 'Kiến trúc');
      expect(deserialized.isPinned, isTrue);
    });

    test('2. AuthService initial state is unauthenticated', () {
      final auth = AuthService();
      expect(auth.isAuthenticated, isFalse);
      expect(auth.currentUser, isNull);
      expect(auth.accessToken, isNull);
    });
  });
}
