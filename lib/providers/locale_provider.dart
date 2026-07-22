import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier() : super(const Locale('bn', 'BD'));

  void toggleLocale() {
    if (state.languageCode == 'bn') {
      state = const Locale('en', 'US');
    } else {
      state = const Locale('bn', 'BD');
    }
  }

  void setLocale(String languageCode) {
    if (languageCode == 'en') {
      state = const Locale('en', 'US');
    } else {
      state = const Locale('bn', 'BD');
    }
  }
}

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  return LocaleNotifier();
});
