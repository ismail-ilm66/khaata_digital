import 'package:drift/drift.dart';

import '../../../core/db/app_database.dart';
import '../../../core/db/tables.dart';

part 'to_pay_dao.g.dart';

@DriftAccessor(tables: [PlannedPayments])
class ToPayDao extends DatabaseAccessor<AppDatabase> with _$ToPayDaoMixin {
  ToPayDao(super.attachedDatabase);

  Stream<List<PlannedPaymentRow>> watchOpen() =>
      (select(plannedPayments)
            ..where((p) => p.deletedAt.isNull() & p.paidAt.isNull())
            ..orderBy([
              (p) => OrderingTerm(expression: p.dueOn.isNull()),
              (p) => OrderingTerm(expression: p.dueOn),
              (p) => OrderingTerm(expression: p.createdAt),
            ]))
          .watch();

  Stream<List<PlannedPaymentRow>> watchPaid({int limit = 50}) =>
      (select(plannedPayments)
            ..where((p) => p.deletedAt.isNull() & p.paidAt.isNotNull())
            ..orderBy([
              (p) =>
                  OrderingTerm(expression: p.paidAt, mode: OrderingMode.desc),
            ])
            ..limit(limit))
          .watch();

  Future<String> create(PlannedPaymentsCompanion row) async =>
      (await into(plannedPayments).insertReturning(row)).id;

  Future<void> change(String id, PlannedPaymentsCompanion row) =>
      (update(plannedPayments)..where((p) => p.id.equals(id))).write(
        row.copyWith(updatedAt: Value(DateTime.now().toUtc())),
      );

  Future<void> softDelete(String id) => change(
    id,
    PlannedPaymentsCompanion(deletedAt: Value(DateTime.now().toUtc())),
  );
}
