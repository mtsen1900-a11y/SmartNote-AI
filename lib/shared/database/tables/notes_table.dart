import 'package:drift/drift.dart';

class LocalNotes extends Table {
  TextColumn get id => text()(); // UUID v4 chuỗi
  TextColumn get title => text().withLength(min: 0, max: 255)();
  TextColumn get content => text().withDefault(const Constant(''))();
  TextColumn get folderId => text().nullable()();
  TextColumn get folder => text().nullable()(); // Tên folder tương thích ngược
  BoolColumn get isPinned => boolean().withDefault(const Constant(false))();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  IntColumn get version => integer().withDefault(const Constant(1))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  
  // Trạng thái đồng bộ: 'synced', 'pending_create', 'pending_update', 'pending_delete'
  TextColumn get syncStatus => text().withDefault(const Constant('synced'))();

  @override
  Set<Column> get primaryKey => {id};
}
