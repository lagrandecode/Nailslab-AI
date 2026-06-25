import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'constants/app_strings.dart';
import 'core/config/nail_detect_config.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/upload/hand_upload_try_on_screen.dart';
import 'services/language_service.dart';
import 'widgets/haptic_scope.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: '.env');
    assert(() {
      if (!NailDetectConfig.isConfigured) {
        debugPrint(
          'NAIL_DETECT_URL missing in bundled .env — stop app and run flutter run again after editing .env',
        );
      }
      return true;
    }());
  } catch (e) {
    assert(() {
      debugPrint('Could not load .env asset: $e');
      return true;
    }());
  }
  await LanguageService.instance.ensureLoaded();
  runApp(const NailLabApp());
}

class NailLabApp extends StatefulWidget {
  const NailLabApp({super.key});

  @override
  State<NailLabApp> createState() => _NailLabAppState();
}

class _NailLabAppState extends State<NailLabApp> {
  @override
  void initState() {
    super.initState();
    LanguageService.instance.addListener(_rebuild);
  }

  @override
  void dispose() {
    LanguageService.instance.removeListener(_rebuild);
    super.dispose();
  }

  void _rebuild() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appTitle,
      debugShowCheckedModeBanner: false,
      locale: LanguageService.instance.locale,
      supportedLocales: [
        for (final language in LanguageService.supported) language.locale,
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: AppTheme.light(),
      builder: (context, child) => HapticScope(child: child ?? const SizedBox.shrink()),
      home: const _AppRoot(),
    );
  }
}

class _AppRoot extends StatefulWidget {
  const _AppRoot();

  @override
  State<_AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<_AppRoot> {
  bool _onboardingComplete = false;

  @override
  Widget build(BuildContext context) {
    if (_onboardingComplete) {
      return const HomeScreen();
    }

    return OnboardingScreen(
      onFinished: () => setState(() => _onboardingComplete = true),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.back_hand_outlined, size: 64, color: AppColors.primary),
                const SizedBox(height: 16),
                const Text(
                  'NailLab AI',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(
                  'Upload a hand photo, detect nails, try any color.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.title.withValues(alpha: 0.65)),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const HandUploadTryOnScreen(),
                        ),
                      );
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                    ),
                    child: const Text('Try nail colors'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
