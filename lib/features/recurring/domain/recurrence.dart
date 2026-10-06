enum RecurrenceFrequency { daily, weekly, monthly, yearly }

/// What to do when the anchor day doesn't exist in a month (e.g. the 31st
/// in February). Only clamping exists today; the enum leaves room for more.
enum DayRule { clampToMonthEnd }
