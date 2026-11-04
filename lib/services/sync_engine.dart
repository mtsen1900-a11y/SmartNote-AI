import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:http/http.dart' as http;
import '../core/app_config.dart';
import '../shared/database/app_database.dart';

class SyncResult {
  final int pushedCount;
  final int pulledCount;
  final int conflictCount;
  final bool success;
  final String? errorMessage;

  SyncResult({
    required this.pushedCount,
    required this.pulledCount,
    required this.conflictCount,
    required this.success,
    this.errorMessage,
  });
}

class SyncEngine {
  final AppDatabase db;
  final String baseUrl;
  final String? Function() getAuthToken;
  final http.Client httpClient;
  int lastServerCursor = 0;

  SyncEngine({
    required this.db,
    String? baseUrl,
    required this.getAuthToken,
    http.Client? client,
  })  : baseUrl = baseUrl ?? AppConfig.baseUrl,
        httpClient = client ?? http.Client();

  /// Thực hiện quy trình đồng bộ 2 chiều: PUSH trước, sau đó PULL
  Future<SyncResult> sync() async {
    final token = getAuthToken();
    if (token == null || token.isEmpty) {
      return SyncResult(
        pushedCount: 0,
        pulledCount: 0,
        conflictCount: 0,
        success: false,
        errorMessage: 'Chưa đăng nhập, không thể đồng bộ.',
      );
    }

    try {
      // 1. PUSH local changes
      final pushRes = await pushPendingChanges(token);

      // 2. PULL remote changes
      final pulledCount = await pullRemoteChanges(token);

      return SyncResult(
        pushedCount: pushRes['pushed'] ?? 0,
        pulledCount: pulledCount,
        conflictCount: pushRes['conflicts'] ?? 0,
        success: true,
      );
    } catch (e) {
      return SyncResult(
        pushedCount: 0,
        pulledCount: 0,
        conflictCount: 0,
        success: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// PUSH các sự kiện đang chờ từ LocalSyncQueue lên server
  Future<Map<String, int>> pushPendingChanges(String token) async {
    final pendingItems = await db.select(db.localSyncQueue).get();
    if (pendingItems.isEmpty) {
      return {'pushed': 0, 'conflicts': 0};
    }

    final itemsPayload = pendingItems.map((item) {
      final payloadMap = jsonDecode(item.payload) as Map<String, dynamic>;
      final version = payloadMap['version'] is int ? payloadMap['version'] as int : 1;
      return {
        'client_event_id': item.id.toString(),
        'entity_type': item.entityType,
        'entity_id': item.entityId,
        'action': item.action,
        'version': version,
        'payload': payloadMap,
      };
    }).toList();

    final response = await httpClient.post(
      Uri.parse('$baseUrl/api/sync/push'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'items': itemsPayload}),
    );

    if (response.statusCode != 200) {
      throw Exception('Lỗi API sync push: HTTP ${response.statusCode}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final results = data['results'] as List<dynamic>;

    int pushed = 0;
    int conflicts = 0;

    for (var r in results) {
      final entityId = r['entity_id'] as String;
      final status = r['status'] as String;
      final serverVersion = r['server_version'] as int;

      if (status == 'SUCCESS') {
        pushed++;
        // Cập nhật trạng thái note thành 'synced'
        await (db.update(db.localNotes)..where((tbl) => tbl.id.equals(entityId))).write(
          LocalNotesCompanion(
            syncStatus: const Value('synced'),
            version: Value(serverVersion),
          ),
        );
        // Xóa item khỏi queue
        await (db.delete(db.localSyncQueue)..where((tbl) => tbl.entityId.equals(entityId))).go();
      } else if (status == 'CONFLICT') {
        conflicts++;
        // Đánh dấu note bị xung đột
        await (db.update(db.localNotes)..where((tbl) => tbl.id.equals(entityId))).write(
          const LocalNotesCompanion(
            syncStatus: Value('conflict'),
          ),
        );
      }
    }

    return {'pushed': pushed, 'conflicts': conflicts};
  }

  /// PULL các thay đổi mới từ máy chủ và lưu vào Drift database qua transaction
  Future<int> pullRemoteChanges(String token) async {
    final response = await httpClient.get(
      Uri.parse('$baseUrl/api/sync/pull?cursor=$lastServerCursor'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Lỗi API sync pull: HTTP ${response.statusCode}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final events = data['events'] as List<dynamic>;
    final newCursor = data['new_cursor'] as int;

    if (events.isEmpty) {
      lastServerCursor = newCursor;
      return 0;
    }

    await db.transaction(() async {
      for (var ev in events) {
        final entityType = ev['entity_type'] as String;
        final entityId = ev['entity_id'] as String;
        final action = ev['action'] as String;
        final version = ev['version'] as int;
        final entityData = ev['data'] as Map<String, dynamic>?;

        if (entityType == 'note' && entityData != null) {
          final existing = await (db.select(db.localNotes)..where((tbl) => tbl.id.equals(entityId))).getSingleOrNull();

          // Không ghi đè nếu local đang pending sửa (tránh mất dữ liệu chưa push)
          if (existing != null && existing.syncStatus.startsWith('pending')) {
            continue;
          }

          final isDeleted = entityData['is_deleted'] == true || action == 'DELETE';

          await db.into(db.localNotes).insertOnConflictUpdate(
                LocalNotesCompanion(
                  id: Value(entityId),
                  title: Value(entityData['title'] ?? 'Ghi chú'),
                  content: Value(entityData['content'] ?? ''),
                  folder: Value(entityData['folder'] ?? 'Cá nhân'),
                  isPinned: Value(entityData['is_pinned'] == true),
                  isArchived: Value(entityData['is_archived'] == true),
                  isDeleted: Value(isDeleted),
                  version: Value(version),
                  syncStatus: const Value('synced'),
                  updatedAt: Value(DateTime.now()),
                ),
              );
        }
      }
      lastServerCursor = newCursor;
    });

    return events.length;
  }
}
