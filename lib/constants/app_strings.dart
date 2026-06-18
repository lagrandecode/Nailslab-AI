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

  static String get styleFrenchTip => _t('French Tip', {
    'zh': '法式',
    'hi': 'फ्रेंच टिप',
    'es': 'Punta francesa',
    'fr': 'French',
    'de': 'French Tip',
    'ru': 'Френч',
    'pt': 'Ponta francesa',
    'it': 'French',
    'ro': 'French tip',
    'nl': 'French tip',
    'ar': 'فرنش',
  });

  static String get styleGlitterPink => _t('Glitter Pink', {
    'zh': '闪粉粉',
    'hi': 'ग्लिटर पिंक',
    'es': 'Rosa brillante',
    'fr': 'Rose pailleté',
    'de': 'Glitzer-Rosa',
    'ru': 'Розовый блеск',
    'pt': 'Rosa brilhante',
    'it': 'Rosa glitter',
    'ro': 'Roz sclipitor',
    'nl': 'Glitter roze',
    'ar': 'وردي لامع',
  });

  static String get styleMarbleBlue => _t('Marble Blue', {
    'zh': '蓝大理石',
    'hi': 'नीला मार्बल',
    'es': 'Mármol azul',
    'fr': 'Marbre bleu',
    'de': 'Blauer Marmor',
    'ru': 'Синий мрамор',
    'pt': 'Mármore azul',
    'it': 'Marmo blu',
    'ro': 'Marmură albastră',
    'nl': 'Blauw marmer',
    'ar': 'رخام أزرق',
  });

  static String get styleRedDots => _t('Red Dots', {
    'zh': '红点',
    'hi': 'लाल डॉट्स',
    'es': 'Puntos rojos',
    'fr': 'Points rouges',
    'de': 'Rote Punkte',
    'ru': 'Красные точки',
    'pt': 'Bolinhas vermelhas',
    'it': 'Pois rossi',
    'ro': 'Buline roșii',
    'nl': 'Rode stippen',
    'ar': 'نقاط حمراء',
  });

  static String get styleNudeGloss => _t('Nude Gloss', {
    'zh': '裸色光泽',
    'hi': 'न्यूड ग्लॉस',
    'es': 'Nude brillante',
    'fr': 'Nude brillant',
    'de': 'Nude-Glanz',
    'ru': 'Нюдовый глянец',
    'pt': 'Nude brilhante',
    'it': 'Nude lucido',
    'ro': 'Nude lucios',
    'nl': 'Nude glans',
    'ar': 'لمعان عاري',
  });

  static String get styleChromeLilac => _t('Chrome Lilac', {
    'zh': '铬紫',
    'hi': 'क्रोम लिलैक',
    'es': 'Cromo lila',
    'fr': 'Chrome lilas',
    'de': 'Chrom-Lila',
    'ru': 'Хром сирень',
    'pt': 'Cromo lilás',
    'it': 'Cromo lilla',
    'ro': 'Crom liliac',
    'nl': 'Chroom lila',
    'ar': 'كروم بنفسجي',
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
