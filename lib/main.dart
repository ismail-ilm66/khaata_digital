import 'package:flutter/material.dart';

import 'app.dart';
import 'bootstrap.dart';
import 'core/di/injection.dart';
import 'features/recurring/data/recurring_maintenance.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  configureDependencies();
  await bootstrap();
  await registerRecurringBackgroundJob();
  runApp(const KharchaApp());
}
