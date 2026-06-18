import '../services/language_service.dart';

abstract final class AppStrings {
  static String get _lang => LanguageService.instance.code;

  static String _t(String fallback, Map<String, String> values) =>
      values[_lang] ?? fallback;

  static String get appTitle => 'NailLab AI';

  static String get continueLabel => _t('Continue', {
    'zh': '继续',
    'hi': 'जारी रखें',
    'es': 'Continuar',
    'fr': 'Continuer',
    'de': 'Weiter',
    'ru': 'Продолжить',
    'pt': 'Continuar',
    'it': 'Continua',
    'ro': 'Continuă',
    'nl': 'Doorgaan',
    'ar': 'متابعة',
  });

  static String get settingsLanguageLabel => _t('Language', {
    'zh': '语言',
    'hi': 'भाषा',
    'es': 'Idioma',
    'fr': 'Langue',
    'de': 'Sprache',
    'ru': 'Язык',
    'pt': 'Idioma',
    'it': 'Lingua',
    'ro': 'Limbă',
    'nl': 'Taal',
    'ar': 'اللغة',
  });

  static String get onboardingOneHeadline => _t('Endless Nail Inspo', {
    'zh': '无尽美甲灵感',
    'hi': 'अनंत नेल प्रेरणा',
    'es': 'Inspiración infinita para uñas',
    'fr': 'Inspiration ongles infinie',
    'de': 'Endlose Nagel-Inspiration',
    'ru': 'Бесконечное вдохновение для маникюра',
    'pt': 'Inspiração infinita para unhas',
    'it': 'Ispirazione unghie infinita',
    'ro': 'Inspirație infinită pentru unghii',
    'nl': 'Eindeloze nagel-inspiratie',
    'ar': 'إلهام لا نهائي للأظافر',
  });

  static String get onboardingTwoHeadline => _t('Your Nails, Your Vibe', {
    'zh': '你的美甲，你的风格',
    'hi': 'आपके नाखून, आपकी स्टाइल',
    'es': 'Tus uñas, tu estilo',
    'fr': 'Tes ongles, ton style',
    'de': 'Deine Nägel, dein Vibe',
    'ru': 'Твои ногти, твой стиль',
    'pt': 'As tuas unhas, o teu estilo',
    'it': 'Le tue unghie, il tuo stile',
    'ro': 'Unghiile tale, stilul tău',
    'nl': 'Jouw nagels, jouw vibe',
    'ar': 'أظافرك، أسلوبك',
  });
}
