import 'package:flutter/foundation.dart';
import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'tables/notes_table.dart';
import 'tables/folders_table.dart';
import 'tables/tags_table.dart';
import 'tables/tasks_table.dart';
import 'tables/sync_queue_table.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [
  LocalNotes,
  LocalFolders,
  LocalTags,
  LocalNoteTags,
  LocalTasks,
  LocalSyncQueue,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? e]) : super(e ?? _openConnection());

  @override
  int get schemaVersion => 1;

  static QueryExecutor _openConnection() {
    return driftDatabase(
      name: 'smartnote_local_db',
      web: DriftWebOptions(
        sqlite3Wasm: Uri.parse('sqlite3.wasm'),
        driftWorker: Uri.parse('drift_worker.js'),
        onResult: (result) {
          if (result.missingFeatures.isNotEmpty) {
            debugPrint('Drift Web fallback: ${result.chosenImplementation} (thiếu: ${result.missingFeatures})');
          } else {
            debugPrint('Drift Web sử dụng giải pháp tối ưu: ${result.chosenImplementation}');
          }
        },
      ),
    );
  }
}
