import 'package:drift/drift.dart';

import '../../../core/db/app_database.dart';
import '../../../core/db/entity_ops.dart';
import '../../../core/db/tables.dart';

part 'write_offs_dao.g.dart';

@DriftAccessor(tables: [WriteOffs, People])
class WriteOffsDao extends DatabaseAccessor<AppDatabase>
    with _$WriteOffsDaoMixin {
  WriteOffsDao(super.attachedDatabase);

  /// Live write-offs, newest first, with the person's name; for one
  /// person, or (Reports) everyone's within `[fromMillis, toMillis)`.
  Stream<List<({WriteOffRow row, String personName})>> watch({
    String? personId,
    int? fromMillis,
    int? toMillis,
  }) {
    final q = select(writeOffs).join([
      innerJoin(people, people.id.equalsExp(writeOffs.personId)),
    ])..where(writeOffs.deletedAt.isNull());
    if (personId != null) q.where(writeOffs.personId.equals(personId));
    if (fromMillis != null) {
      q.where(writeOffs.occurredAt.isBiggerOrEqualValue(fromMillis));
    }
    if (toMillis != null) {
      q.where(writeOffs.occurredAt.isSmallerThanValue(toMillis));
    }
    q.orderBy([
      OrderingTerm.desc(writeOffs.occurredAt),
      OrderingTerm.desc(writeOffs.createdAt),
    ]);
    return q.watch().map(
      (rows) => [
        for (final r in rows)
          (row: r.readTable(writeOffs), personName: r.readTable(people).name),
      ],
    );
  }

  Future<String> create(WriteOffsCompanion row) async =>
      (await into(writeOffs).insertReturning(row)).id;

  Future<void> change(String id, WriteOffsCompanion row) =>
      (update(writeOffs)..where((w) => w.id.equals(id))).write(
        row.copyWith(updatedAt: Value(DateTime.now().toUtc())),
      );

  Future<void> remove(String id) => softDelete(writeOffs, id);
  Future<void> restore(String id) => undelete(writeOffs, id);
}
