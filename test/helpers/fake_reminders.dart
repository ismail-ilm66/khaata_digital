import 'package:khaata_digital/features/recurring/domain/recurring_rule.dart';

/// Records reminder syncs instead of scheduling OS notifications.
class FakeReminderScheduler implements ReminderScheduler {
  final List<List<RecurringRule>> syncs = [];

  List<RecurringRule> get last => syncs.isEmpty ? const [] : syncs.last;

  int permissionRequests = 0;

  @override
  Future<void> sync(List<RecurringRule> rules) async => syncs.add(rules);

  @override
  Future<bool> requestPermission() async {
    permissionRequests++;
    return true;
  }
}
