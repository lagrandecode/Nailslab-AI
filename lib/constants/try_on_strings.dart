import '../services/language_service.dart';

abstract final class TryOnStrings {
  static String get _lang => LanguageService.instance.code;

  static String _t(String fallback, Map<String, String> values) =>
      values[_lang] ?? fallback;

  static String get tryItHeadline => _t('Try It Out', {
    'zh': '亲自体验',
    'hi': 'आज़माएँ',
    'es': 'Pruébalo',
    'fr': 'Essayez',
    'de': 'Ausprobieren',
    'ru': 'Попробуйте',
    'pt': 'Experimente',
    'it': 'Provalo',
    'ro': 'Încearcă',
    'nl': 'Probeer het',
    'ar': 'جرّبها',
  });

  static String get snapHandHint => _t('Snap a clear photo of your hand in good light', {
    'zh': '在光线充足处拍摄清晰的手部照片',
    'hi': 'अच्छी रोशनी में अपने हाथ की स्पष्ट फोटो लें',
    'es': 'Toma una foto clara de tu mano con buena luz',
    'fr': 'Prenez une photo nette de votre main avec une bonne lumière',
    'de': 'Mache ein klares Handfoto bei gutem Licht',
    'ru': 'Сделайте чёткое фото руки при хорошем освещении',
    'pt': 'Tire uma foto nítida da sua mão com boa luz',
    'it': 'Scatta una foto nitida della mano con buona luce',
    'ro': 'Fă o poză clară a mâinii în lumină bună',
    'nl': 'Maak een heldere foto van je hand bij goed licht',
    'ar': 'التقط صورة واضحة ليدك في إضاءة جيدة',
  });

  static String get openCamera => _t('Open Camera', {
    'zh': '打开相机',
    'hi': 'कैमरा खोलें',
    'es': 'Abrir cámara',
    'fr': 'Ouvrir la caméra',
    'de': 'Kamera öffnen',
    'ru': 'Открыть камеру',
    'pt': 'Abrir câmara',
    'it': 'Apri fotocamera',
    'ro': 'Deschide camera',
    'nl': 'Camera openen',
    'ar': 'افتح الكاميرا',
  });

  static String get retakePhoto => _t('Retake', {
    'zh': '重拍',
    'hi': 'फिर से लें',
    'es': 'Repetir',
    'fr': 'Reprendre',
    'de': 'Neu aufnehmen',
    'ru': 'Переснять',
    'pt': 'Repetir',
    'it': 'Scatta di nuovo',
    'ro': 'Refă poza',
    'nl': 'Opnieuw',
    'ar': 'إعادة التقاط',
  });

  static String get selectStyle => _t('Pick a nail style', {
    'zh': '选择美甲风格',
    'hi': 'नेल स्टाइल चुनें',
    'es': 'Elige un estilo de uñas',
    'fr': 'Choisissez un style d’ongles',
    'de': 'Wähle einen Nagelstil',
    'ru': 'Выберите стиль маникюра',
    'pt': 'Escolha um estilo de unhas',
    'it': 'Scegli uno stile unghie',
    'ro': 'Alege un stil de unghii',
    'nl': 'Kies een nagelstijl',
    'ar': 'اختر نمط الأظافر',
  });

  static String get generate => _t('Generate', {
    'zh': '生成',
    'hi': 'जनरेट करें',
    'es': 'Generar',
    'fr': 'Générer',
    'de': 'Generieren',
    'ru': 'Создать',
    'pt': 'Gerar',
    'it': 'Genera',
    'ro': 'Generează',
    'nl': 'Genereren',
    'ar': 'إنشاء',
  });

  static String get generating => _t('Creating your look...', {
    'zh': '正在生成你的造型...',
    'hi': 'आपका लुक बन रहा है...',
    'es': 'Creando tu look...',
    'fr': 'Création de votre look...',
    'de': 'Look wird erstellt...',
    'ru': 'Создаём ваш образ...',
    'pt': 'A criar o seu look...',
    'it': 'Creazione del tuo look...',
    'ro': 'Se creează look-ul...',
    'nl': 'Je look wordt gemaakt...',
    'ar': 'جارٍ إنشاء إطلالتك...',
  });

  static String get getStarted => _t('Get Started', {
    'zh': '开始使用',
    'hi': 'शुरू करें',
    'es': 'Empezar',
    'fr': 'Commencer',
    'de': 'Loslegen',
    'ru': 'Начать',
    'pt': 'Começar',
    'it': 'Inizia',
    'ro': 'Începe',
    'nl': 'Aan de slag',
    'ar': 'ابدأ',
  });

  static String get missingApiKey => _t(
    'Add OPENAI_API_KEY to your .env file to generate nail looks.',
    {
      'zh': '请在 .env 文件中添加 OPENAI_API_KEY 以生成美甲效果。',
      'hi': 'नेल लुक जनरेट करने के लिए .env में OPENAI_API_KEY जोड़ें।',
      'es': 'Añade OPENAI_API_KEY a tu archivo .env para generar looks.',
      'fr': 'Ajoutez OPENAI_API_KEY à votre fichier .env.',
      'de': 'Füge OPENAI_API_KEY zur .env-Datei hinzu.',
      'ru': 'Добавьте OPENAI_API_KEY в файл .env.',
      'pt': 'Adicione OPENAI_API_KEY ao ficheiro .env.',
      'it': 'Aggiungi OPENAI_API_KEY al file .env.',
      'ro': 'Adaugă OPENAI_API_KEY în fișierul .env.',
      'nl': 'Voeg OPENAI_API_KEY toe aan je .env-bestand.',
      'ar': 'أضف OPENAI_API_KEY إلى ملف .env.',
    },
  );

  static String get generationTimedOut => _t(
    'Generation is taking too long. Check your connection and try again.',
    {
      'zh': '生成时间过长，请检查网络后重试。',
      'hi': 'जनरेशन में बहुत समय लग रहा है। कनेक्शन जांचें और फिर कोशिश करें।',
      'es': 'La generación tarda demasiado. Comprueba tu conexión e inténtalo de nuevo.',
      'fr': 'La génération prend trop de temps. Vérifiez votre connexion et réessayez.',
      'de': 'Die Generierung dauert zu lange. Prüfe deine Verbindung und versuche es erneut.',
      'ru': 'Генерация занимает слишком много времени. Проверьте соединение и попробуйте снова.',
      'pt': 'A geração está a demorar demasiado. Verifique a ligação e tente novamente.',
      'it': 'La generazione richiede troppo tempo. Controlla la connessione e riprova.',
      'ro': 'Generarea durează prea mult. Verifică conexiunea și încearcă din nou.',
      'nl': 'Genereren duurt te lang. Controleer je verbinding en probeer opnieuw.',
      'ar': 'يستغرق الإنشاء وقتًا طويلًا. تحقق من الاتصال وحاول مرة أخرى.',
    },
  );

  static String get generationFailed => _t(
    'Could not generate this nail look. Please try again.',
    {
      'zh': '无法生成该美甲效果，请重试。',
      'hi': 'यह नेल लुक नहीं बन सका। फिर से कोशिश करें।',
      'es': 'No se pudo generar este look. Inténtalo de nuevo.',
      'fr': 'Impossible de générer ce look. Réessayez.',
      'de': 'Look konnte nicht erstellt werden. Bitte erneut versuchen.',
      'ru': 'Не удалось создать образ. Попробуйте снова.',
      'pt': 'Não foi possível gerar este look. Tente novamente.',
      'it': 'Impossibile generare questo look. Riprova.',
      'ro': 'Nu s-a putut genera look-ul. Încearcă din nou.',
      'nl': 'Kon deze look niet maken. Probeer opnieuw.',
      'ar': 'تعذر إنشاء هذا المظهر. حاول مرة أخرى.',
    },
  );

  static String get whiteBackgroundHint => _t(
    'Use white background for best results',
    {
      'zh': '使用白色背景效果更佳',
      'hi': 'सर्वोत्तम परिणाम के लिए सफेद पृष्ठभूमि का उपयोग करें',
      'es': 'Usa fondo blanco para mejores resultados',
      'fr': 'Utilisez un fond blanc pour de meilleurs résultats',
      'de': 'Weißer Hintergrund liefert die besten Ergebnisse',
      'ru': 'Для лучшего результата используйте белый фон',
      'pt': 'Use fundo branco para melhores resultados',
      'it': 'Usa uno sfondo bianco per risultati migliori',
      'ro': 'Folosește fundal alb pentru cele mai bune rezultate',
      'nl': 'Gebruik een witte achtergrond voor het beste resultaat',
      'ar': 'استخدم خلفية بيضاء للحصول على أفضل النتائج',
    },
  );

  static String get holdHandHint => _t(
    'Nails painted on your fingers — move your hand',
    {
      'zh': '美甲已涂在您的手指上 — 移动您的手',
      'hi': 'उंगलियों पर नेल लगे हैं — हाथ हिलाएँ',
      'es': 'Uñas pintadas en tus dedos — mueve la mano',
      'fr': 'Ongles peints sur vos doigts — bougez la main',
      'de': 'Nägel auf deinen Fingern — bewege deine Hand',
      'ru': 'Маникюр на пальцах — двигайте рукой',
      'pt': 'Unhas pintadas nos dedos — mova a mão',
      'it': 'Unghie dipinte sulle dita — muovi la mano',
      'ro': 'Unghii pictate pe degete — mișcă mâna',
      'nl': 'Nagels op je vingers — beweeg je hand',
      'ar': 'الأظافر مرسومة على أصابعك — حرّك يدك',
    },
  );

  static String get detectingHandHint => _t(
    'Show your palm to the camera',
    {
      'zh': '将手掌对准相机',
      'hi': 'अपनी हथेली कैमरे की ओर करें',
      'es': 'Muestra la palma a la cámara',
      'fr': 'Montrez votre paume à la caméra',
      'de': 'Zeige deine Handfläche zur Kamera',
      'ru': 'Покажите ладонь камере',
      'pt': 'Mostre a palma da mão à câmara',
      'it': 'Mostra il palmo alla fotocamera',
      'ro': 'Arată palma spre cameră',
      'nl': 'Toon je handpalm aan de camera',
      'ar': 'وجّه راحة يدك نحو الكاميرا',
    },
  );

  static String get tapToPlain => _t('Tap to plain', {
    'zh': '点击切换 plain',
    'hi': 'plain के लिए टैप करें',
    'es': 'Toca para plain',
    'fr': 'Appuyez pour plain',
    'de': 'Tippen für plain',
    'ru': 'Нажмите для plain',
    'pt': 'Toque para plain',
    'it': 'Tocca per plain',
    'ro': 'Atinge pentru plain',
    'nl': 'Tik voor plain',
    'ar': 'اضغط للوضع العادي',
  });

  static String get tapToCamera => _t('Tap to camera', {
    'zh': '点击切换相机',
    'hi': 'कैमरे के लिए टैप करें',
    'es': 'Toca para cámara',
    'fr': 'Appuyez pour la caméra',
    'de': 'Tippen für Kamera',
    'ru': 'Нажмите для камеры',
    'pt': 'Toque para câmara',
    'it': 'Tocca per fotocamera',
    'ro': 'Atinge pentru cameră',
    'nl': 'Tik voor camera',
    'ar': 'اضغط للكاميرا',
  });

  static String get plainPickLookHint => _t('Tap a look to paint the nails', {
    'zh': '点击造型以涂上美甲',
    'hi': 'नेल पेंट करने के लिए लुक टैप करें',
    'es': 'Toca un look para pintar las uñas',
    'fr': 'Appuyez sur un look pour peindre les ongles',
    'de': 'Tippe einen Look an, um Nägel zu lackieren',
    'ru': 'Нажмите стиль, чтобы нанести маникюр',
    'pt': 'Toque num look para pintar as unhas',
    'it': 'Tocca un look per dipingere le unghie',
    'ro': 'Atinge un look pentru a picta unghiile',
    'nl': 'Tik een look om nagels te schilderen',
    'ar': 'اضغط على مظهر لطلاء الأظافر',
  });

  static String get plainLookAppliedHint => _t('Look applied — tap another style', {
    'zh': '已应用造型 — 点击其他风格',
    'hi': 'लुक लगाया गया — दूसरा स्टाइल टैप करें',
    'es': 'Look aplicado — toca otro estilo',
    'fr': 'Look appliqué — choisissez un autre style',
    'de': 'Look angewendet — wähle einen anderen Stil',
    'ru': 'Стиль применён — выберите другой',
    'pt': 'Look aplicado — toque noutro estilo',
    'it': 'Look applicato — tocca un altro stile',
    'ro': 'Look aplicat — atinge alt stil',
    'nl': 'Look toegepast — tik een andere stijl',
    'ar': 'تم تطبيق المظهر — اختر نمطًا آخر',
  });

  static String get lightHand => _t('Light hand', {
    'zh': '浅色手',
    'hi': 'हल्का हाथ',
    'es': 'Mano clara',
    'fr': 'Main claire',
    'de': 'Helle Hand',
    'ru': 'Светлая рука',
    'pt': 'Mão clara',
    'it': 'Mano chiara',
    'ro': 'Mână deschisă',
    'nl': 'Lichte hand',
    'ar': 'يد فاتحة',
  });

  static String get brownHand => _t('Brown hand', {
    'zh': '棕色手',
    'hi': 'भूरा हाथ',
    'es': 'Mano morena',
    'fr': 'Main brune',
    'de': 'Braune Hand',
    'ru': 'Тёмная рука',
    'pt': 'Mão castanha',
    'it': 'Mano scura',
    'ro': 'Mână maro',
    'nl': 'Donkere hand',
    'ar': 'يد داكنة',
  });

  static String get leftHand => _t('Left hand', {
    'zh': '左手',
    'hi': 'बायां हाथ',
    'es': 'Mano izquierda',
    'fr': 'Main gauche',
    'de': 'Linke Hand',
    'ru': 'Левая рука',
    'pt': 'Mão esquerda',
    'it': 'Mano sinistra',
    'ro': 'Mâna stângă',
    'nl': 'Linkerhand',
    'ar': 'اليد اليسرى',
  });

  static String get rightHand => _t('Right hand', {
    'zh': '右手',
    'hi': 'दायां हाथ',
    'es': 'Mano derecha',
    'fr': 'Main droite',
    'de': 'Rechte Hand',
    'ru': 'Правая рука',
    'pt': 'Mão direita',
    'it': 'Mano destra',
    'ro': 'Mâna dreaptă',
    'nl': 'Rechterhand',
    'ar': 'اليد اليمنى',
  });

  static String get guideOn => _t('On', {
    'zh': '开',
    'hi': 'चालू',
    'es': 'Sí',
    'fr': 'Oui',
    'de': 'An',
    'ru': 'Вкл',
    'pt': 'Sim',
    'it': 'Sì',
    'ro': 'Pornit',
    'nl': 'Aan',
    'ar': 'تشغيل',
  });

  static String get guideOff => _t('Off', {
    'zh': '关',
    'hi': 'बंद',
    'es': 'No',
    'fr': 'Non',
    'de': 'Aus',
    'ru': 'Выкл',
    'pt': 'Não',
    'it': 'No',
    'ro': 'Oprit',
    'nl': 'Uit',
    'ar': 'إيقاف',
  });

  static String get timerOff => _t('OFF', {
    'zh': '关',
    'hi': 'बंद',
    'es': 'NO',
    'fr': 'NON',
    'de': 'AUS',
    'ru': 'ВЫКЛ',
    'pt': 'NÃO',
    'it': 'NO',
    'ro': 'OPRIT',
    'nl': 'UIT',
    'ar': 'إيقاف',
  });

  static String get cameraUnavailable => _t(
    'Camera is not available on this device.',
    {
      'zh': '此设备无法使用相机。',
      'hi': 'इस डिवाइस पर कैमरा उपलब्ध नहीं है।',
      'es': 'La cámara no está disponible en este dispositivo.',
      'fr': 'La caméra n’est pas disponible sur cet appareil.',
      'de': 'Kamera auf diesem Gerät nicht verfügbar.',
      'ru': 'Камера недоступна на этом устройстве.',
      'pt': 'A câmara não está disponível neste dispositivo.',
      'it': 'Fotocamera non disponibile su questo dispositivo.',
      'ro': 'Camera nu este disponibilă pe acest dispozitiv.',
      'nl': 'Camera is niet beschikbaar op dit apparaat.',
      'ar': 'الكاميرا غير متوفرة على هذا الجهاز.',
    },
  );

  static String get cameraCaptureFailed => _t(
    'Could not capture photo. Please try again.',
    {
      'zh': '无法拍照，请重试。',
      'hi': 'फोटो नहीं ली जा सकी। फिर से कोशिश करें।',
      'es': 'No se pudo tomar la foto. Inténtalo de nuevo.',
      'fr': 'Impossible de prendre la photo. Réessayez.',
      'de': 'Foto konnte nicht aufgenommen werden. Bitte erneut versuchen.',
      'ru': 'Не удалось сделать фото. Попробуйте снова.',
      'pt': 'Não foi possível tirar a foto. Tente novamente.',
      'it': 'Impossibile scattare la foto. Riprova.',
      'ro': 'Nu s-a putut face fotografia. Încearcă din nou.',
      'nl': 'Kon geen foto maken. Probeer opnieuw.',
      'ar': 'تعذر التقاط الصورة. حاول مرة أخرى.',
    },
  );

  static String get closeCamera => _t('Close', {
    'zh': '关闭',
    'hi': 'बंद करें',
    'es': 'Cerrar',
    'fr': 'Fermer',
    'de': 'Schließen',
    'ru': 'Закрыть',
    'pt': 'Fechar',
    'it': 'Chiudi',
    'ro': 'Închide',
    'nl': 'Sluiten',
    'ar': 'إغلاق',
  });
}
