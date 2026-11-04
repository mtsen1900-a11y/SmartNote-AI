import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_note_ai/shared/database/app_database.dart';
import 'package:smart_note_ai/shared/repositories/local_note_repository.dart';
import 'package:uuid/uuid.dart';

void main() {
  late AppDatabase db;
  const uuid = Uuid();

  setUp(() {
    // Sử dụng in-memory database để kiểm thử độc lập và tức thì
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('Drift Local Database Test Suite', () {
    test('1. Tạo và truy vấn ghi chú (LocalNotes)', () async {
      final noteId = uuid.v4();
      final now = DateTime.now();

      await db.into(db.localNotes).insert(
            LocalNotesCompanion.insert(
              id: noteId,
              title: 'Ghi chú kiến trúc mới',
              content: const Value('Nội dung thử nghiệm Drift SQLite'),
              folder: const Value('Công việc'),
              syncStatus: const Value('pending_create'),
              version: const Value(1),
              createdAt: Value(now),
              updatedAt: Value(now),
            ),
          );

      final notes = await db.select(db.localNotes).get();
      expect(notes.length, equals(1));
      expect(notes.first.id, equals(noteId));
      expect(notes.first.title, equals('Ghi chú kiến trúc mới'));
      expect(notes.first.syncStatus, equals('pending_create'));
      expect(notes.first.version, equals(1));
    });

    test('2. Cập nhật ghi chú và tăng phiên bản (Version Lamport)', () async {
      final noteId = uuid.v4();
      await db.into(db.localNotes).insert(
            LocalNotesCompanion.insert(
              id: noteId,
              title: 'Tiêu đề ban đầu',
              content: const Value('Nội dung 1'),
            ),
          );

      // Cập nhật
      await (db.update(db.localNotes)..where((tbl) => tbl.id.equals(noteId))).write(
        const LocalNotesCompanion(
          title: Value('Tiêu đề đã sửa'),
          version: Value(2),
          syncStatus: Value('pending_update'),
        ),
      );

      final updated = await (db.select(db.localNotes)..where((tbl) => tbl.id.equals(noteId))).getSingle();
      expect(updated.title, equals('Tiêu đề đã sửa'));
      expect(updated.version, equals(2));
      expect(updated.syncStatus, equals('pending_update'));
    });

    test('3. Xóa mềm (Tombstone pattern)', () async {
      final noteId = uuid.v4();
      await db.into(db.localNotes).insert(
            LocalNotesCompanion.insert(
              id: noteId,
              title: 'Ghi chú chuẩn bị xóa',
            ),
          );

      // Soft delete
      await (db.update(db.localNotes)..where((tbl) => tbl.id.equals(noteId))).write(
        const LocalNotesCompanion(
          isDeleted: Value(true),
          syncStatus: Value('pending_delete'),
          version: Value(2),
        ),
      );

      // Khi truy vấn thông thường (chỉ lấy note chưa xóa)
      final activeNotes = await (db.select(db.localNotes)..where((tbl) => tbl.isDeleted.equals(false))).get();
      expect(activeNotes.length, equals(0));

      // Bản ghi vẫn tồn tại trong local DB dưới dạng tombstone phục vụ đồng bộ
      final allNotes = await db.select(db.localNotes).get();
      expect(allNotes.length, equals(1));
      expect(allNotes.first.isDeleted, isTrue);
    });

    test('4. Ghi nhận hàng đợi đồng bộ (SyncQueue)', () async {
      final noteId = uuid.v4();
      await db.into(db.localSyncQueue).insert(
            LocalSyncQueueCompanion.insert(
              entityType: 'note',
              entityId: noteId,
              action: 'CREATE',
              payload: '{"id": "$noteId", "title": "Test Sync"}',
              retryCount: const Value(0),
            ),
          );

      final queue = await db.select(db.localSyncQueue).get();
      expect(queue.length, equals(1));
      expect(queue.first.entityType, equals('note'));
      expect(queue.first.action, equals('CREATE'));
      expect(queue.first.entityId, equals(noteId));
    });

    test('5. Kiểm thử LocalNoteRepository (CRUD, Stream, SyncQueue)', () async {
      final repo = LocalNoteRepository(db);

      // Tạo note
      final created = await repo.createNote(
        title: 'Ghi chú Repo',
        content: 'Nội dung qua repository',
        folder: 'Ý tưởng',
        isPinned: true,
      );
      expect(created.title, equals('Ghi chú Repo'));
      expect(created.version, equals(1));
      expect(created.isPinned, isTrue);

      // Cập nhật note
      final updated = await repo.updateNote(
        id: created.id,
        title: 'Ghi chú Repo đã sửa',
      );
      expect(updated?.title, equals('Ghi chú Repo đã sửa'));
      expect(updated?.version, equals(2));

      // Kiểm tra hàng đợi đồng bộ phải có 2 sự kiện (CREATE, UPDATE)
      final queueEvents = await repo.getPendingSyncEvents();
      expect(queueEvents.length, equals(2));
      expect(queueEvents[0].action, equals('CREATE'));
      expect(queueEvents[1].action, equals('UPDATE'));

      // Xóa mềm note
      final deletedOk = await repo.softDeleteNote(created.id);
      expect(deletedOk, isTrue);

      // Danh sách active note qua stream không còn chứa note vừa xóa
      final activeNotes = await repo.watchActiveNotes().first;
      expect(activeNotes.length, equals(0));

      // Hàng đợi đồng bộ có thêm sự kiện DELETE
      final updatedQueue = await repo.getPendingSyncEvents();
      expect(updatedQueue.length, equals(3));
      expect(updatedQueue[2].action, equals('DELETE'));
    });
  });
}
