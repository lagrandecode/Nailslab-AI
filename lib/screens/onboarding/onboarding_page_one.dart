import 'dart:async';
import 'dart:math';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../constants/asset_paths.dart';
import '../../constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/animated_onboarding_headline.dart';

class OnboardingPageOne extends StatefulWidget {
  const OnboardingPageOne({super.key, required this.onContinue});

  final VoidCallback onContinue;

  @override
  State<OnboardingPageOne> createState() => _OnboardingPageOneState();
}

class _OnboardingPageOneState extends State<OnboardingPageOne>
    with TickerProviderStateMixin {
  static const Duration _videoStartOffset = Duration(seconds: 1);
  static const Duration _headlineDelay = Duration(seconds: 2);
  static const Duration _confettiDelay = Duration(seconds: 2);
  static const Duration _buttonDelay = Duration(seconds: 3);

  late final ConfettiController _confettiController;
  late final AnimationController _buttonController;
  late final Animation<Offset> _buttonSlide;
  late final Animation<double> _buttonFade;

  VideoPlayerController? _videoController;
  bool _videoReady = false;
  bool _showHeadline = false;
  bool _showConfetti = false;
  bool _showButton = false;
  Timer? _headlineTimer;
  Timer? _confettiTimer;
  Timer? _buttonTimer;
  bool _isLooping = false;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );
    _buttonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _buttonSlide = Tween<Offset>(
      begin: const Offset(0, 1.4),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _buttonController,
      curve: Curves.easeOutBack,
    ));
    _buttonFade = CurvedAnimation(
      parent: _buttonController,
      curve: Curves.easeOut,
    );
    _initVideo();
  }

  Future<void> _initVideo() async {
    const videoPath = AssetPaths.onboardingVideo1;
    final controller = VideoPlayerController.asset(
      videoPath,
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
    );
    _videoController = controller;

    try {
      await controller.initialize().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Video failed to load');
        },
      );
      await controller.setVolume(0);
      await controller.setLooping(false);
      await controller.seekTo(_videoStartOffset);
      controller.addListener(_onVideoTick);
      if (mounted) {
        setState(() => _videoReady = true);
      }
      await controller.play();
      _scheduleOverlays();
    } catch (_) {
      if (mounted) {
        _scheduleOverlays();
      }
    }
  }

  void _onVideoTick() {
    final controller = _videoController;
    if (controller == null || !controller.value.isInitialized || _isLooping) {
      return;
    }

    final position = controller.value.position;
    final duration = controller.value.duration;

    // If the player snaps back to the start, skip the first second again.
    if (position < _videoStartOffset - const Duration(milliseconds: 100)) {
      _loopFromTrimPoint();
      return;
    }

    if (duration > Duration.zero &&
        position >= duration - const Duration(milliseconds: 150)) {
      _loopFromTrimPoint();
    }
  }

  Future<void> _loopFromTrimPoint() async {
    final controller = _videoController;
    if (controller == null || _isLooping) {
      return;
    }

    _isLooping = true;
    try {
      await controller.seekTo(_videoStartOffset);
      await controller.play();
    } finally {
      _isLooping = false;
    }
  }

  void _scheduleOverlays() {
    _headlineTimer?.cancel();
    _confettiTimer?.cancel();
    _buttonTimer?.cancel();

    _headlineTimer = Timer(_headlineDelay, () {
      if (!mounted) {
        return;
      }
      setState(() => _showHeadline = true);
    });

    _confettiTimer = Timer(_confettiDelay, () {
      if (!mounted) {
        return;
      }
      setState(() => _showConfetti = true);
      _confettiController.play();
    });

    _buttonTimer = Timer(_buttonDelay, () {
      if (!mounted) {
        return;
      }
      setState(() => _showButton = true);
      _buttonController.forward();
    });
  }

  @override
  void dispose() {
    _headlineTimer?.cancel();
    _confettiTimer?.cancel();
    _buttonTimer?.cancel();
    _videoController?.removeListener(_onVideoTick);
    _videoController?.dispose();
    _confettiController.dispose();
    _buttonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (_videoReady && _videoController != null)
          _FullscreenVideo(controller: _videoController!)
        else
          const ColoredBox(color: Colors.black),
        OnboardingHeadlineOverlay(
          headline: () => AppStrings.onboardingOneHeadline,
          play: _showHeadline,
        ),
        if (_showConfetti)
          Positioned.fill(
            child: IgnorePointer(
              child: Align(
                alignment: Alignment.topCenter,
                child: ConfettiWidget(
                  confettiController: _confettiController,
                  blastDirection: pi / 2,
                  blastDirectionality: BlastDirectionality.directional,
                  emissionFrequency: 0.08,
                  numberOfParticles: 28,
                  maxBlastForce: 28,
                  minBlastForce: 14,
                  gravity: 0.35,
                  particleDrag: 0.04,
                  colors: const [
                    AppColors.primary,
                    AppColors.primaryLight,
                    Color(0xFFFFB6D9),
                    Color(0xFFFFFFFF),
                    Color(0xFFFFC1E3),
                  ],
                ),
              ),
            ),
          ),
        if (_showButton)
          Positioned(
            left: 24,
            right: 24,
            bottom: MediaQuery.paddingOf(context).bottom + 32,
            child: FadeTransition(
              opacity: _buttonFade,
              child: SlideTransition(
                position: _buttonSlide,
                child: _ContinueButton(onPressed: widget.onContinue),
              ),
            ),
          ),
      ],
    );
  }
}

class _FullscreenVideo extends StatelessWidget {
  const _FullscreenVideo({required this.controller});

  final VideoPlayerController controller;

  @override
  Widget build(BuildContext context) {
    final size = controller.value.size;

    return ColoredBox(
      color: Colors.black,
      child: SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.cover,
          alignment: Alignment.center,
          child: SizedBox(
            width: size.width,
            height: size.height,
            child: VideoPlayer(controller),
          ),
        ),
      ),
    );
  }
}

class _ContinueButton extends StatelessWidget {
  const _ContinueButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(27),
          ),
        ),
        child: Text(AppStrings.continueLabel),
      ),
    );
  }
}
