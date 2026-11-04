import 'package:drift/drift.dart';

class LocalTags extends Table {
  TextColumn get id => text()(); // UUID v4 chuỗi
  TextColumn get name => text().withLength(min: 1, max: 50)();
  TextColumn get color => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class LocalNoteTags extends Table {
  TextColumn get noteId => text()();
  TextColumn get tagId => text()();

  @override
  Set<Column> get primaryKey => {noteId, tagId};
}
