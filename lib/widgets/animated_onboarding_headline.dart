import 'package:flutter/material.dart';

import '../core/haptics/app_haptics.dart';
import '../services/language_service.dart';

class AnimatedOnboardingHeadline extends StatefulWidget {
  const AnimatedOnboardingHeadline({
    super.key,
    required this.text,
    required this.play,
    this.alignment = TextAlign.center,
    this.lightBackground = false,
  });

  final String text;
  final bool play;
  final TextAlign alignment;
  final bool lightBackground;

  @override
  State<AnimatedOnboardingHeadline> createState() =>
      _AnimatedOnboardingHeadlineState();
}

class _AnimatedOnboardingHeadlineState extends State<AnimatedOnboardingHeadline>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;
  bool _played = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.35),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
  }

  @override
  void didUpdateWidget(AnimatedOnboardingHeadline oldWidget) {
    super.didUpdateWidget(oldWidget);
    _maybePlay();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _maybePlay() {
    if (!widget.play || _played) {
      return;
    }
    _played = true;
    AppHaptics.heavy();
    _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    _maybePlay();

    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: Text(
          widget.text,
          textAlign: widget.alignment,
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w700,
            height: 1.15,
            color: widget.lightBackground ? const Color(0xFF2D2D2D) : Colors.white,
            shadows: widget.lightBackground
                ? null
                : const [
                    Shadow(
                      color: Color(0x99000000),
                      blurRadius: 16,
                      offset: Offset(0, 2),
                    ),
                  ],
          ),
        ),
      ),
    );
  }
}

class OnboardingHeadlineOverlay extends StatelessWidget {
  const OnboardingHeadlineOverlay({
    super.key,
    required this.headline,
    required this.play,
  });

  final String Function() headline;
  final bool play;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top + 64;

    return Positioned(
      top: top,
      left: 24,
      right: 24,
      child: IgnorePointer(
        child: ListenableBuilder(
          listenable: LanguageService.instance,
          builder: (context, _) {
            return AnimatedOnboardingHeadline(
              text: headline(),
              play: play,
            );
          },
        ),
      ),
    );
  }
}
