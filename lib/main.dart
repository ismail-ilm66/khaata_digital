import 'package:flutter/material.dart';

import 'app.dart';
import 'core/di/injection.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  configureDependencies();
  // M1: open the Drift database and run the integrity check here.
  runApp(const KharchaApp());
}
