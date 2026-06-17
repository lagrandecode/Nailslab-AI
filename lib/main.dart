import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'constants/app_strings.dart';
import 'core/theme/app_theme.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'services/language_service.dart';
import 'widgets/haptic_scope.dart';
import 'widgets/logo_placeholder.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
    return const Scaffold(
      backgroundColor: Colors.white,
      body: LogoPlaceholder(height: 160),
    );
  }
}
