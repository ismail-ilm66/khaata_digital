import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

/// Stores [DateTime] as UTC epoch milliseconds (spec 3.3), read back as UTC.
class UtcMillisConverter extends TypeConverter<DateTime, int> {
  const UtcMillisConverter();

  @override
  DateTime fromSql(int fromDb) =>
      DateTime.fromMillisecondsSinceEpoch(fromDb, isUtc: true);

  @override
  int toSql(DateTime value) => value.millisecondsSinceEpoch;
}

const _uuid = Uuid();
String newId() => _uuid.v4();
int nowMillis() => DateTime.now().millisecondsSinceEpoch;

// Column mixins. Each schema concern is declared once and composed per
// table; the generic helpers in entity_ops.dart are typed against them.

/// UUID primary key — sync-ready ids (spec 3.4).
mixin Entity on Table {
  TextColumn get id => text().clientDefault(newId)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

mixin Timestamped on Entity {
  IntColumn get createdAt =>
      integer().map(const UtcMillisConverter()).clientDefault(nowMillis)();
  IntColumn get updatedAt =>
      integer().map(const UtcMillisConverter()).clientDefault(nowMillis)();
}

/// Soft delete: rows are hidden, never removed, so history and sync survive.
mixin SoftDelete on Timestamped {
  IntColumn get deletedAt =>
      integer().map(const UtcMillisConverter()).nullable()();
}

/// User-controlled ordering.
mixin Sortable on Entity {
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
}

mixin Named on Entity {
  TextColumn get name => text().withLength(min: 1, max: 80)();
}
