import 'package:drift/drift.dart';

import '../../../core/db/app_database.dart';
import '../../../core/db/tables.dart';

part 'attachments_dao.g.dart';

@DriftAccessor(tables: [Attachments])
class AttachmentsDao extends DatabaseAccessor<AppDatabase>
    with _$AttachmentsDaoMixin {
  AttachmentsDao(super.attachedDatabase);

  Future<void> add(AttachmentsCompanion row) => into(attachments).insert(row);

  /// Attachments for each of [transactionIds], oldest first.
  Future<Map<String, List<AttachmentRow>>> forTransactions(
    Iterable<String> transactionIds,
  ) async {
    final ids = transactionIds.toSet();
    if (ids.isEmpty) return const {};
    final rows =
        await (select(attachments)
              ..where((a) => a.transactionId.isIn(ids))
              ..orderBy([(a) => OrderingTerm.asc(a.createdAt)]))
            .get();
    final out = <String, List<AttachmentRow>>{};
    for (final r in rows) {
      out.putIfAbsent(r.transactionId, () => []).add(r);
    }
    return out;
  }

  /// Removes rows for [transactionId] whose ids are not in [keep]; returns
  /// the removed rows so their files can be deleted.
  Future<List<AttachmentRow>> removeExcept(
    String transactionId,
    Set<String> keep,
  ) async {
    final doomed =
        await (select(attachments)..where(
              (a) => a.transactionId.equals(transactionId) & a.id.isNotIn(keep),
            ))
            .get();
    if (doomed.isNotEmpty) {
      await (delete(
        attachments,
      )..where((a) => a.id.isIn(doomed.map((d) => d.id)))).go();
    }
    return doomed;
  }
}
