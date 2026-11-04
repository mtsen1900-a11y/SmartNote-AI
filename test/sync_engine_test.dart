import 'dart:convert';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:smart_note_ai/services/sync_engine.dart';
import 'package:smart_note_ai/shared/database/app_database.dart';
import 'package:smart_note_ai/shared/repositories/local_note_repository.dart';
import 'package:uuid/uuid.dart';

void main() {
  const uuid = Uuid();
  late AppDatabase db;
  late LocalNoteRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = LocalNoteRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('Phase 5 Flutter SyncEngine Unit Tests', () {
    test('1. Push local changes thành công -> Cập nhật synced & xóa khỏi queue', () async {
      // 1. Tạo note local (sẽ tự động đưa vào LocalSyncQueue với action CREATE)
      final note = await repo.createNote(
        title: 'Offline Note Push',
        content: 'Chờ đồng bộ lên server',
      );

      final queueBefore = await repo.getPendingSyncEvents();
      expect(queueBefore.length, equals(1));

      // 2. Mock HTTP client giả lập phản hồi của /api/sync/push
      final mockClient = MockClient((request) async {
        if (request.url.path == '/api/sync/push') {
          return http.Response(
            jsonEncode({
              'results': [
                {
                  'entity_id': note.id,
                  'entity_type': 'note',
                  'status': 'SUCCESS',
                  'server_version': 1,
                }
              ]
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('Not Found', 404);
      });

      final syncEngine = SyncEngine(
        db: db,
        baseUrl: 'http://testserver',
        getAuthToken: () => 'fake-jwt-token',
        client: mockClient,
      );

      final pushResult = await syncEngine.pushPendingChanges('fake-jwt-token');
      expect(pushResult['pushed'], equals(1));
      expect(pushResult['conflicts'], equals(0));

      // Hàng đợi local phải được xóa sạch sau khi push thành công
      final queueAfter = await repo.getPendingSyncEvents();
      expect(queueAfter.isEmpty, isTrue);

      // Trạng thái của note trong local DB chuyển sang 'synced'
      final syncedNote = await repo.getNoteById(note.id);
      expect(syncedNote?.syncStatus, equals('synced'));
    });

    test('2. Push phát hiện CONFLICT -> Chuyển syncStatus thành conflict', () async {
      final note = await repo.createNote(
        title: 'Conflict Note',
        content: 'Sửa khi offline',
      );

      final mockClient = MockClient((request) async {
        if (request.url.path == '/api/sync/push') {
          return http.Response(
            jsonEncode({
              'results': [
                {
                  'entity_id': note.id,
                  'entity_type': 'note',
                  'status': 'CONFLICT',
                  'server_version': 3,
                }
              ]
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('Not Found', 404);
      });

      final syncEngine = SyncEngine(
        db: db,
        baseUrl: 'http://testserver',
        getAuthToken: () => 'fake-jwt-token',
        client: mockClient,
      );

      final pushResult = await syncEngine.pushPendingChanges('fake-jwt-token');
      expect(pushResult['conflicts'], equals(1));

      final conflictNote = await repo.getNoteById(note.id);
      expect(conflictNote?.syncStatus, equals('conflict'));
    });

    test('3. Pull remote changes -> Áp dụng ghi chú mới từ server vào Local DB', () async {
      final remoteNoteId = uuid.v4();

      final mockClient = MockClient((request) async {
        if (request.url.path == '/api/sync/pull') {
          return http.Response(
            jsonEncode({
              'events': [
                {
                  'id': 101,
                  'entity_type': 'note',
                  'entity_id': remoteNoteId,
                  'action': 'CREATE',
                  'version': 1,
                  'data': {
                    'uuid': remoteNoteId,
                    'title': 'Ghi chú từ thiết bị khác',
                    'content': 'Được kéo về qua Sync Pull',
                    'folder': 'Dự án',
                    'is_pinned': true,
                    'is_deleted': false,
                  }
                }
              ],
              'new_cursor': 101,
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('Not Found', 404);
      });

      final syncEngine = SyncEngine(
        db: db,
        baseUrl: 'http://testserver',
        getAuthToken: () => 'fake-jwt-token',
        client: mockClient,
      );

      final pulledCount = await syncEngine.pullRemoteChanges('fake-jwt-token');
      expect(pulledCount, equals(1));
      expect(syncEngine.lastServerCursor, equals(101));

      // Kiểm tra note đã được lưu vào Local DB
      final note = await repo.getNoteById(remoteNoteId);
      expect(note, isNotNull);
      expect(note?.title, equals('Ghi chú từ thiết bị khác'));
      expect(note?.isPinned, isTrue);
      expect(note?.syncStatus, equals('synced'));
    });
  });
}
