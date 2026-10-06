/// How a transaction moves money. `amount_minor` is always positive except
/// for [adjustment], whose sign is the direction (positive = into account).
enum TransactionType { expense, income, transfer, adjustment }
