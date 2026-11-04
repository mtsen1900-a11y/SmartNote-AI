import '../models/note.dart';
import '../shared/database/app_database.dart';
import '../shared/repositories/local_note_repository.dart';

class NoteStorage {
  final LocalNoteRepository _repo;

  NoteStorage([AppDatabase? db]) : _repo = LocalNoteRepository(db ?? AppDatabase());

  LocalNoteRepository get repository => _repo;

  /// Tải danh sách ghi chú từ Drift Local Database
  Future<List<Note>?> load() async {
    final localList = await _repo.watchActiveNotes().first;
    if (localList.isEmpty) return null;

    return localList.map((l) {
      List<String> tags = [];
      if (l.folder != null && l.folder!.isNotEmpty) {
        tags.add(l.folder!);
      }
      return Note(
        id: l.id,
        title: l.title,
        content: l.content,
        tags: tags,
        folder: l.folder ?? 'Cá nhân',
        isPinned: l.isPinned,
        createdAt: l.createdAt,
        updatedAt: l.updatedAt,
      );
    }).toList();
  }

  /// Lưu hoặc cập nhật ghi chú vào Drift Local Database (và tự động ghi vào LocalSyncQueue)
  Future<void> save(List<Note> notes) async {
    for (final note in notes) {
      final existing = await _repo.getNoteById(note.id);
      final folder = note.folder.isNotEmpty ? note.folder : (note.tags.isNotEmpty ? note.tags.first : 'Cá nhân');
      if (existing == null) {
        await _repo.createNote(
          title: note.title,
          content: note.content,
          folder: folder,
          isPinned: note.isPinned,
        );
      } else {
        await _repo.updateNote(
          id: note.id,
          title: note.title,
          content: note.content,
          folder: folder,
          isPinned: note.isPinned,
        );
      }
    }
  }

  /// Xóa mềm ghi chú (Tombstone)
  Future<void> deleteNote(String id) async {
    await _repo.softDeleteNote(id);
  }
}
