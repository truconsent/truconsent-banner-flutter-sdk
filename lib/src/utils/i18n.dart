/// i18n configuration for Flutter
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'locales/en.dart';
import 'locales/ta.dart';
import 'locales/hi.dart';

class I18n {
  static Locale _currentLocale = const Locale('en');
  static final Map<String, Map<String, String>> _translations = {
    'en': enTranslations,
    'ta': taTranslations,
    'hi': hiTranslations,
  };

  static Locale get currentLocale => _currentLocale;

  static void setLocale(Locale locale) {
    _currentLocale = locale;
    Intl.defaultLocale = locale.languageCode;
  }

  static String translate(String key, {Map<String, String>? params}) {
    final translations = _translations[_currentLocale.languageCode] ?? enTranslations;
    String text = translations[key] ?? enTranslations[key] ?? key;

    // Replace parameters
    if (params != null) {
      params.forEach((key, value) {
        text = text.replaceAll('{{$key}}', value);
      });
    }

    return text;
  }

  static String t(String key, {Map<String, String>? params}) {
    return translate(key, params: params);
  }
}

