import 'package:flutter/material.dart';
import 'app_localizations.dart';
import 'app_localizations_ps.dart';
import 'app_localizations_en.dart';
import 'app_localizations_ur.dart';
import 'app_localizations_ar.dart';

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    // Support Pashto, English, Urdu, and Arabic
    return ['ps', 'en', 'ur', 'ar'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    switch (locale.languageCode) {
      case 'ps':
        return AppLocalizationsPs();
      case 'en':
        return AppLocalizationsEn();
      case 'ur':
        return AppLocalizationsUr();
      case 'ar':
        return AppLocalizationsAr();
      default:
        return AppLocalizationsPs(); // Default to Pashto
    }
  }

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
} 