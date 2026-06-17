import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'widgets/haptic_scope.dart';
import 'widgets/logo_placeholder.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const NailLabApp());
}

class NailLabApp extends StatelessWidget {
  const NailLabApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NailLab AI',
      debugShowCheckedModeBanner: false,
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
