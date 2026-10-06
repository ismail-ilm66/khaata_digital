/// The one definition of how a transaction row (aliased `t`) moves money.
/// Every balance query composes these, so the sign rules live in one place.
abstract final class LedgerSql {
  /// Effect on the source account (`t.account_id`): income and adjustments
  /// add (adjustments are signed); expenses and outgoing transfers subtract.
  static const String sourceDelta =
      "CASE t.type WHEN 'income' THEN t.amount_minor "
      "WHEN 'adjustment' THEN t.amount_minor "
      'ELSE -t.amount_minor END';

  /// Credit to a transfer's destination (`t.to_account_id`), in the
  /// destination's currency when the transfer crossed currencies.
  static const String destinationCredit =
      'COALESCE(t.to_amount_minor, t.amount_minor)';

  /// Udhaar effect on a person: money I gave (expense) is owed to me (+),
  /// money I received (income) is owed by me (−).
  static const String personDelta =
      "CASE t.type WHEN 'expense' THEN t.amount_minor "
      "WHEN 'income' THEN -t.amount_minor ELSE 0 END";

  static const String live = 't.deleted_at IS NULL';
}
