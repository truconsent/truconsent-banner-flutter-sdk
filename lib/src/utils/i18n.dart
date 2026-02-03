import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'locales/en.dart';
import 'locales/ta.dart';
import 'locales/hi.dart';

/// Internationalization (i18n) utility for the TruConsent SDK.
///
/// Provides translation support for multiple languages (English, Hindi, Tamil).
/// Manages locale settings and provides translation methods.
///
/// Example:
/// ```dart
/// I18n.setLocale(const Locale('hi'));
/// final text = I18n.translate('consent.banner.title');
/// ```
class I18n {
  static Locale _currentLocale = const Locale('en');
  static final Map<String, Map<String, String>> _translations = {
    'en': enTranslations,
    'ta': taTranslations,
    'hi': hiTranslations,
  };

  /// Gets the current locale
  static Locale get currentLocale => _currentLocale;

  /// Sets the current locale for translations.
  ///
  /// Changes the active language for all subsequent translation calls.
  ///
  /// Example:
  /// ```dart
  /// I18n.setLocale(const Locale('hi')); // Switch to Hindi
  /// ```
  static void setLocale(Locale locale) {
    _currentLocale = locale;
    Intl.defaultLocale = locale.languageCode;
  }

  /// Translates a key to the current locale's text.
  ///
  /// Returns the translated text, or the key itself if translation is not found.
  /// Supports parameter substitution using `{{paramName}}` syntax.
  ///
  /// Example:
  /// ```dart
  /// final text = I18n.translate('consent.banner.title');
  /// final withParams = I18n.translate('welcome', params: {'name': 'John'});
  /// ```
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

  /// Short alias for [translate].
  ///
  /// Example:
  /// ```dart
  /// final text = I18n.t('consent.banner.title');
  /// ```
  static String t(String key, {Map<String, String>? params}) {
    return translate(key, params: params);
  }
}

