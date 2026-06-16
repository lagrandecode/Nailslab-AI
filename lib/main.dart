import 'package:flutter/material.dart';

import 'widgets/logo_placeholder.dart';

void main() {
  runApp(const NailLabApp());
}

class NailLabApp extends StatelessWidget {
  const NailLabApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NailLab AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFE91E8C)),
        scaffoldBackgroundColor: Colors.white,
        useMaterial3: true,
      ),
      home: const _PlaceholderHome(),
    );
  }
}

class _PlaceholderHome extends StatelessWidget {
  const _PlaceholderHome();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: LogoPlaceholder(height: 160),
    );
  }
}
