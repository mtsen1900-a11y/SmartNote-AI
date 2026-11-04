import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_note_ai/shared/database/app_database.dart';
import 'package:smart_note_ai/shared/repositories/local_note_repository.dart';
import 'package:uuid/uuid.dart';

void main() {
  const uuid = Uuid();

  group('Phase 4 Comprehensive Flutter Local Database & Repository Tests', () {
    late AppDatabase db;
    late LocalNoteRepository repo;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      repo = LocalNoteRepository(db);
    });

    tearDown(() async {
      await db.close();
    });

    test('1. Database Transaction và Rollback khi gặp lỗi', () async {
      final noteId1 = uuid.v4();

      try {
        await db.transaction(() async {
          // Thêm note 1 thành công
          await db.into(db.localNotes).insert(
                LocalNotesCompanion.insert(
                  id: noteId1,
                  title: 'Ghi chú transaction',
                  content: const Value('Nội dung hợp lệ'),
                ),
              );

          // Cố tình gây lỗi trong transaction (ví dụ ném Exception)
          throw Exception('Lỗi giả lập gây rollback');
        });
      } catch (e) {
        // Bắt lỗi mong đợi
      }

      // Xác minh note 1 đã được rollback hoàn toàn, không lưu vào DB
      final notes = await db.select(db.localNotes).get();
      expect(notes.isEmpty, isTrue);
    });

    test('2. Folder CRUD, Hierarchy và Soft Delete', () async {
      final folderId = uuid.v4();
      final now = DateTime.now();

      // Tạo Folder
      await db.into(db.localFolders).insert(
            LocalFoldersCompanion.insert(
              id: folderId,
              name: 'Dự án Flutter',
              color: const Value('#4A90E2'),
              icon: const Value('folder'),
              version: const Value(1),
              createdAt: Value(now),
              updatedAt: Value(now),
            ),
          );

      var folders = await db.select(db.localFolders).get();
      expect(folders.length, equals(1));
      expect(folders.first.name, equals('Dự án Flutter'));

      // Cập nhật Folder
      await (db.update(db.localFolders)..where((tbl) => tbl.id.equals(folderId))).write(
        const LocalFoldersCompanion(
          name: Value('Dự án Flutter & Dart'),
          version: Value(2),
        ),
      );

      var updated = await (db.select(db.localFolders)..where((tbl) => tbl.id.equals(folderId))).getSingle();
      expect(updated.name, equals('Dự án Flutter & Dart'));
      expect(updated.version, equals(2));

      // Xóa mềm Folder (Tombstone)
      await (db.update(db.localFolders)..where((tbl) => tbl.id.equals(folderId))).write(
        const LocalFoldersCompanion(
          isDeleted: Value(true),
          version: Value(3),
        ),
      );

      final activeFolders = await (db.select(db.localFolders)..where((tbl) => tbl.isDeleted.equals(false))).get();
      expect(activeFolders.isEmpty, isTrue);

      final allFolders = await db.select(db.localFolders).get();
      expect(allFolders.first.isDeleted, isTrue);
    });

    test('3. Tag CRUD và Note-Tag Many-to-Many Relationship', () async {
      final noteId = uuid.v4();
      final tagId1 = uuid.v4();
      final tagId2 = uuid.v4();

      // Tạo note
      await db.into(db.localNotes).insert(
            LocalNotesCompanion.insert(
              id: noteId,
              title: 'Ghi chú có thẻ',
            ),
          );

      // Tạo 2 tags
      await db.into(db.localTags).insert(
            LocalTagsCompanion.insert(id: tagId1, name: 'Khẩn cấp', color: const Value('#e74c3c')),
          );
      await db.into(db.localTags).insert(
            LocalTagsCompanion.insert(id: tagId2, name: 'Cá nhân', color: const Value('#2ecc71')),
          );

      // Gán tag cho note qua bảng trung gian LocalNoteTags
      await db.into(db.localNoteTags).insert(
            LocalNoteTagsCompanion.insert(noteId: noteId, tagId: tagId1),
          );
      await db.into(db.localNoteTags).insert(
            LocalNoteTagsCompanion.insert(noteId: noteId, tagId: tagId2),
          );

      // Truy vấn các tag thuộc về noteId
      final noteTagsQuery = db.select(db.localNoteTags).join([
        innerJoin(db.localTags, db.localTags.id.equalsExp(db.localNoteTags.tagId)),
      ])..where(db.localNoteTags.noteId.equals(noteId));

      final rows = await noteTagsQuery.get();
      expect(rows.length, equals(2));

      final tagNames = rows.map((r) => r.readTable(db.localTags).name).toList();
      expect(tagNames, containsAll(['Khẩn cấp', 'Cá nhân']));

      // Bỏ gán 1 tag
      await (db.delete(db.localNoteTags)
            ..where((tbl) => tbl.noteId.equals(noteId) & tbl.tagId.equals(tagId1)))
          .go();

      final remainingRows = await noteTagsQuery.get();
      expect(remainingRows.length, equals(1));
      expect(remainingRows.first.readTable(db.localTags).name, equals('Cá nhân'));
    });

    test('4. Local Note Search theo Title và Content', () async {
      await repo.createNote(title: 'Học Drift ORM', content: 'Cơ sở dữ liệu SQLite cục bộ');
      await repo.createNote(title: 'FastAPI Backend', content: 'Xây dựng API RESTful');
      await repo.createNote(title: 'Kiến trúc AI RAG', content: 'Sử dụng ChromaDB và Ollama');

      // Tìm kiếm từ khóa 'Drift'
      final driftResults = await repo.watchActiveNotes(searchQuery: 'Drift').first;
      expect(driftResults.length, equals(1));
      expect(driftResults.first.title, equals('Học Drift ORM'));

      // Tìm kiếm từ khóa trong content 'ChromaDB'
      final aiResults = await repo.watchActiveNotes(searchQuery: 'ChromaDB').first;
      expect(aiResults.length, equals(1));
      expect(aiResults.first.title, equals('Kiến trúc AI RAG'));

      // Tìm kiếm từ khóa chung 'cục bộ'
      final localResults = await repo.watchActiveNotes(searchQuery: 'cục bộ').first;
      expect(localResults.length, equals(1));
    });

    test('5. Ghim ghi chú (isPinned) và sắp xếp hiển thị', () async {
      await repo.createNote(title: 'Ghi chú thường 1', content: 'Nội dung 1');
      final note2 = await repo.createNote(title: 'Ghi chú được ghim', content: 'Quan trọng', isPinned: true);
      await repo.createNote(title: 'Ghi chú thường 2', content: 'Nội dung 2');

      final notes = await repo.watchActiveNotes().first;
      expect(notes.length, equals(3));
      // Ghi chú được ghim phải đứng đầu tiên
      expect(notes.first.id, equals(note2.id));
      expect(notes.first.isPinned, isTrue);
    });

    test('6. Lọc ghi chú theo Folder', () async {
      await repo.createNote(title: 'Note Folder A', content: 'Cont A', folder: 'Work');
      await repo.createNote(title: 'Note Folder B', content: 'Cont B', folder: 'Personal');

      final workNotes = await repo.watchActiveNotes(folder: 'Work').first;
      expect(workNotes.length, equals(1));
      expect(workNotes.first.title, equals('Note Folder A'));

      final personalNotes = await repo.watchActiveNotes(folder: 'Personal').first;
      expect(personalNotes.length, equals(1));
      expect(personalNotes.first.title, equals('Note Folder B'));
    });
  });
}
