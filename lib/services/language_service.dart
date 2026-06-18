import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppLanguage {
  const AppLanguage({
    required this.code,
    required this.name,
    required this.flag,
    this.countryCode = 'US',
  });

  final String code;
  final String name;
  final String flag;
  final String countryCode;

  Locale get locale => Locale(code, countryCode);
}

class LanguageService extends ChangeNotifier {
  LanguageService._();

  static final LanguageService instance = LanguageService._();

  static const _prefsKey = 'app_language_code_v1';

  static const List<AppLanguage> supported = [
    AppLanguage(code: 'en', name: 'English', flag: '🇺🇸', countryCode: 'US'),
    AppLanguage(code: 'zh', name: 'Chinese', flag: '🇨🇳', countryCode: 'CN'),
    AppLanguage(code: 'hi', name: 'Hindi', flag: '🇮🇳', countryCode: 'IN'),
    AppLanguage(code: 'es', name: 'Spanish', flag: '🇪🇸', countryCode: 'ES'),
    AppLanguage(code: 'fr', name: 'French', flag: '🇫🇷', countryCode: 'FR'),
    AppLanguage(code: 'de', name: 'German', flag: '🇩🇪', countryCode: 'DE'),
    AppLanguage(code: 'ru', name: 'Russian', flag: '🇷🇺', countryCode: 'RU'),
    AppLanguage(code: 'pt', name: 'Portuguese', flag: '🇵🇹', countryCode: 'PT'),
    AppLanguage(code: 'it', name: 'Italian', flag: '🇮🇹', countryCode: 'IT'),
    AppLanguage(code: 'ro', name: 'Romanian', flag: '🇷🇴', countryCode: 'RO'),
    AppLanguage(code: 'nl', name: 'Dutch', flag: '🇳🇱', countryCode: 'NL'),
    AppLanguage(code: 'ar', name: 'Arabic', flag: '🇸🇦', countryCode: 'SA'),
  ];

  String _code = 'en';

  String get code => _code;

  AppLanguage get current => byCode(_code);

  Locale get locale => current.locale;

  bool get isRtl => _code == 'ar';

  static AppLanguage byCode(String code) {
    return supported.firstWhere(
      (language) => language.code == code,
      orElse: () => supported.first,
    );
  }

  Future<void> ensureLoaded() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefsKey);
    if (saved != null && supported.any((language) => language.code == saved)) {
      _code = saved;
    }
    notifyListeners();
  }

  Future<void> setLanguageCode(String value) async {
    if (_code == value || !supported.any((language) => language.code == value)) {
      return;
    }

    _code = value;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, value);
  }
}
