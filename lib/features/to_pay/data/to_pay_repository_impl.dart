import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';

import '../../../core/dates/calendar_day.dart';
import '../../../core/db/app_database.dart';
import '../../../core/error/app_failure.dart';
import '../../../core/money/currency.dart';
import '../../../core/money/money.dart';
import '../domain/planned_payment.dart';

extension PlannedPaymentRowMapping on PlannedPaymentRow {
  PlannedPayment toDomain() => PlannedPayment(
    id: id,
    title: title,
    amount: Money(amountMinor, Currency.of(currencyCode)),
    categoryId: categoryId,
    dueOn: dueOn == null ? null : CalendarDay.fromStorage(dueOn!),
    note: note,
    paidAt: paidAt,
    transactionId: transactionId,
  );
}

@LazySingleton(as: ToPayRepository)
class ToPayRepositoryImpl implements ToPayRepository {
  ToPayRepositoryImpl(this._db);

  final AppDatabase _db;

  @override
  Stream<List<PlannedPayment>> watchOpen() => _db.toPayDao.watchOpen().map(
    (rows) => [for (final r in rows) r.toDomain()],
  );

  @override
  Stream<List<PlannedPayment>> watchPaid() => _db.toPayDao.watchPaid().map(
    (rows) => [for (final r in rows) r.toDomain()],
  );

  @override
  Future<String> add(PlannedPaymentDraft draft) {
    _check(draft);
    return _db.toPayDao.create(
      PlannedPaymentsCompanion.insert(
        title: draft.title.trim(),
        amountMinor: draft.amount.minor,
        currencyCode: draft.amount.currency.code,
        categoryId: Value(draft.categoryId),
        dueOn: Value(draft.dueOn?.toStorage()),
        note: Value(draft.note.trim()),
      ),
    );
  }

  @override
  Future<void> update(String id, PlannedPaymentDraft draft) {
    _check(draft);
    return _db.toPayDao.change(
      id,
      PlannedPaymentsCompanion(
        title: Value(draft.title.trim()),
        amountMinor: Value(draft.amount.minor),
        currencyCode: Value(draft.amount.currency.code),
        categoryId: Value(draft.categoryId),
        dueOn: Value(draft.dueOn?.toStorage()),
        note: Value(draft.note.trim()),
      ),
    );
  }

  @override
  Future<void> remove(String id) => _db.toPayDao.softDelete(id);

  @override
  Future<void> markPaid(String id, {String? transactionId, DateTime? at}) =>
      _db.toPayDao.change(
        id,
        PlannedPaymentsCompanion(
          paidAt: Value((at ?? DateTime.now()).toUtc()),
          transactionId: Value(transactionId),
        ),
      );

  @override
  Future<void> markUnpaid(String id) => _db.toPayDao.change(
    id,
    const PlannedPaymentsCompanion(
      paidAt: Value(null),
      transactionId: Value(null),
    ),
  );

  static void _check(PlannedPaymentDraft d) {
    if (d.title.trim().isEmpty || !d.amount.isPositive) {
      throw const ValidationFailure(EntryProblem.amountRequired);
    }
  }
}
