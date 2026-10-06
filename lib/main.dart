import 'package:flutter/material.dart';

import 'app.dart';
import 'bootstrap.dart';
import 'core/di/injection.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  configureDependencies();
  await bootstrap();
  runApp(const KharchaApp());
}
