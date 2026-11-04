import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../database/app_database.dart';

class LocalNoteRepository {
  final AppDatabase _db;
  static const _uuid = Uuid();

  LocalNoteRepository(this._db);

  /// Theo dõi danh sách ghi chú theo thời gian thực (chỉ lấy ghi chú chưa bị xóa mềm)
  Stream<List<LocalNote>> watchActiveNotes({String? searchQuery, String? folder}) {
    final query = _db.select(_db.localNotes)
      ..where((tbl) => tbl.isDeleted.equals(false))
      ..orderBy([
        (tbl) => OrderingTerm.desc(tbl.isPinned),
        (tbl) => OrderingTerm.desc(tbl.updatedAt),
      ]);

    if (folder != null && folder.isNotEmpty) {
      query.where((tbl) => tbl.folder.equals(folder));
    }

    if (searchQuery != null && searchQuery.isNotEmpty) {
      final term = '%$searchQuery%';
      query.where((tbl) => tbl.title.like(term) | tbl.content.like(term));
    }

    return query.watch();
  }

  /// Lấy chi tiết 1 ghi chú theo ID (UUID)
  Future<LocalNote?> getNoteById(String id) {
    return (_db.select(_db.localNotes)..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
  }

  /// Tạo mới ghi chú cục bộ và đẩy vào Sync Queue
  Future<LocalNote> createNote({
    required String title,
    required String content,
    String? folder,
    bool isPinned = false,
  }) async {
    final noteId = _uuid.v4();
    final now = DateTime.now();

    final companion = LocalNotesCompanion.insert(
      id: noteId,
      title: title,
      content: Value(content),
      folder: Value(folder),
      isPinned: Value(isPinned),
      isDeleted: const Value(false),
      version: const Value(1),
      syncStatus: const Value('pending_create'),
      createdAt: Value(now),
      updatedAt: Value(now),
    );

    await _db.into(_db.localNotes).insert(companion);

    // Ghi nhận vào hàng đợi đồng bộ SyncQueue
    await _db.into(_db.localSyncQueue).insert(
          LocalSyncQueueCompanion.insert(
            entityType: 'note',
            entityId: noteId,
            action: 'CREATE',
            payload: jsonEncode({
              'uuid': noteId,
              'title': title,
              'content': content,
              'folder': folder,
              'is_pinned': isPinned,
              'version': 1,
            }),
          ),
        );

    final created = await getNoteById(noteId);
    return created!;
  }

  /// Cập nhật ghi chú và tăng phiên bản (Lamport versioning)
  Future<LocalNote?> updateNote({
    required String id,
    String? title,
    String? content,
    String? folder,
    bool? isPinned,
    bool? isArchived,
  }) async {
    final existing = await getNoteById(id);
    if (existing == null) return null;

    final newVersion = existing.version + 1;
    final now = DateTime.now();

    final companion = LocalNotesCompanion(
      title: title != null ? Value(title) : const Value.absent(),
      content: content != null ? Value(content) : const Value.absent(),
      folder: folder != null ? Value(folder) : const Value.absent(),
      isPinned: isPinned != null ? Value(isPinned) : const Value.absent(),
      isArchived: isArchived != null ? Value(isArchived) : const Value.absent(),
      version: Value(newVersion),
      syncStatus: const Value('pending_update'),
      updatedAt: Value(now),
    );

    await (_db.update(_db.localNotes)..where((tbl) => tbl.id.equals(id))).write(companion);

    // Đẩy sự kiện cập nhật vào SyncQueue
    await _db.into(_db.localSyncQueue).insert(
          LocalSyncQueueCompanion.insert(
            entityType: 'note',
            entityId: id,
            action: 'UPDATE',
            payload: jsonEncode({
              'uuid': id,
              'title': title ?? existing.title,
              'content': content ?? existing.content,
              'folder': folder ?? existing.folder,
              'is_pinned': isPinned ?? existing.isPinned,
              'is_archived': isArchived ?? existing.isArchived,
              'version': newVersion,
            }),
          ),
        );

    return getNoteById(id);
  }

  /// Xóa mềm ghi chú (Tombstone)
  Future<bool> softDeleteNote(String id) async {
    final existing = await getNoteById(id);
    if (existing == null) return false;

    final newVersion = existing.version + 1;

    await (_db.update(_db.localNotes)..where((tbl) => tbl.id.equals(id))).write(
      LocalNotesCompanion(
        isDeleted: const Value(true),
        version: Value(newVersion),
        syncStatus: const Value('pending_delete'),
        updatedAt: Value(DateTime.now()),
      ),
    );

    await _db.into(_db.localSyncQueue).insert(
          LocalSyncQueueCompanion.insert(
            entityType: 'note',
            entityId: id,
            action: 'DELETE',
            payload: jsonEncode({'uuid': id, 'version': newVersion}),
          ),
        );

    return true;
  }

  /// Đánh dấu ghi chú đã đồng bộ thành công với server
  Future<void> markSynced(String id, int serverVersion) async {
    await (_db.update(_db.localNotes)..where((tbl) => tbl.id.equals(id))).write(
      LocalNotesCompanion(
        syncStatus: const Value('synced'),
        version: Value(serverVersion),
      ),
    );
  }

  /// Lấy tất cả sự kiện trong hàng đợi đồng bộ
  Future<List<LocalSyncQueueData>> getPendingSyncEvents() {
    return _db.select(_db.localSyncQueue).get();
  }

  /// Xóa sự kiện khỏi hàng đợi sau khi đồng bộ thành công
  Future<int> removeSyncEvent(int eventId) {
    return (_db.delete(_db.localSyncQueue)..where((tbl) => tbl.id.equals(eventId))).go();
  }
}
