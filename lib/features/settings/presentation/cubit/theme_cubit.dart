import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

/// Holds the selected theme mode. Persistence to the `settings` table
/// arrives with the database in M1/M6.
@lazySingleton
class ThemeCubit extends Cubit<ThemeMode> {
  ThemeCubit() : super(ThemeMode.system);

  void setMode(ThemeMode mode) => emit(mode);
}
