import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'constants/app_strings.dart';
import 'constants/try_on_strings.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'screens/camera/hand_camera_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'services/language_service.dart';
import 'widgets/haptic_scope.dart';
import 'widgets/logo_placeholder.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const NailLabApp());

  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    // Optional in dev; use --dart-define=OPENAI_API_KEY when .env is absent.
  }
  await LanguageService.instance.ensureLoaded();
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

  Future<void> _openCamera(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const HandCameraScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(flex: 2),
              const LogoPlaceholder(height: 160),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton(
                  onPressed: () => _openCamera(context),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(27),
                    ),
                  ),
                  child: Text(TryOnStrings.openCamera),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
