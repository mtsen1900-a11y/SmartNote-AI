import 'package:drift/drift.dart';

class LocalTasks extends Table {
  TextColumn get id => text()(); // UUID v4 chuỗi
  TextColumn get noteId => text().nullable()();
  TextColumn get title => text().withLength(min: 1, max: 255)();
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get dueDate => dateTime().nullable()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  IntColumn get version => integer().withDefault(const Constant(1))();
  TextColumn get syncStatus => text().withDefault(const Constant('synced'))();

  @override
  Set<Column> get primaryKey => {id};
}
