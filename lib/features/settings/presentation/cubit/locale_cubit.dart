import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

/// Holds the selected app locale (English or Urdu). Persistence to the
/// `settings` table arrives with the database in M1/M6.
@lazySingleton
class LocaleCubit extends Cubit<Locale> {
  LocaleCubit() : super(english);

  static const Locale english = Locale('en');
  static const Locale urdu = Locale('ur');
  static const List<Locale> supported = [english, urdu];

  void setLocale(Locale locale) {
    assert(supported.contains(locale), 'Unsupported locale $locale');
    emit(locale);
  }
}
