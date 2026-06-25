import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../constants/try_on_strings.dart';
import '../../core/config/openai_config.dart';
import '../../core/theme/app_colors.dart';
import '../../models/nail_style.dart';
import '../../screens/upload/hand_upload_try_on_screen.dart';
import '../../services/language_service.dart';
import '../../services/nail_generation_service.dart';
import '../../widgets/animated_onboarding_headline.dart';
import '../../widgets/nail_style_picker.dart';

class OnboardingTryScreen extends StatefulWidget {
  const OnboardingTryScreen({super.key, required this.onFinished});

  final VoidCallback onFinished;

  @override
  State<OnboardingTryScreen> createState() => _OnboardingTryScreenState();
}

class _OnboardingTryScreenState extends State<OnboardingTryScreen> {
  final NailGenerationService _generationService = const NailGenerationService();

  bool _showHeadline = false;
  Uint8List? _handBytes;
  Uint8List? _resultBytes;
  NailStyle? _selectedStyle;
  bool _isGenerating = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _showHeadline = true);
    });
  }

  Future<void> _openHandTryOn() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => const HandUploadTryOnScreen()),
    );
  }

  Future<void> _generate() async {
    final hand = _handBytes;
    final style = _selectedStyle;
    if (hand == null || style == null || _isGenerating) return;

    if (!OpenAiConfig.isConfigured) {
      setState(() => _errorMessage = TryOnStrings.missingApiKey);
      return;
    }

    setState(() {
      _isGenerating = true;
      _errorMessage = null;
    });

    try {
      final result = await _generationService.generate(
        handImageBytes: hand,
        style: style,
      );
      if (!mounted) return;
      setState(() {
        _resultBytes = result;
        _isGenerating = false;
      });
    } on NailGenerationException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
        _isGenerating = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e is TimeoutException
            ? TryOnStrings.generationTimedOut
            : TryOnStrings.generationFailed;
        _isGenerating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    final topPadding = MediaQuery.paddingOf(context).top;
    final displayBytes = _resultBytes ?? _handBytes;

    return ColoredBox(
      color: Colors.white,
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.only(top: topPadding > 0 ? 8 : 56, left: 24, right: 24),
              child: ListenableBuilder(
                listenable: LanguageService.instance,
                builder: (context, _) {
                  return AnimatedOnboardingHeadline(
                    text: TryOnStrings.tryItHeadline,
                    play: _showHeadline,
                    lightBackground: true,
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ListenableBuilder(
                listenable: LanguageService.instance,
                builder: (context, _) => Text(
                  TryOnStrings.snapHandHint,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.title.withValues(alpha: 0.65),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _PhotoPreview(
                  bytes: displayBytes,
                  isGenerating: _isGenerating,
                  onTapCamera: _openHandTryOn,
                ),
              ),
            ),
            if (_handBytes != null) ...[
              const SizedBox(height: 16),
              NailStylePicker(
                selected: _selectedStyle,
                onSelected: (style) {
                  setState(() {
                    _selectedStyle = style;
                    _errorMessage = null;
                  });
                },
              ),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                  child: Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Color(0xFFFF8A80), fontSize: 13),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                child: SizedBox(
                  height: 48,
                  child: FilledButton(
                    onPressed: _selectedStyle == null || _isGenerating ? null : _generate,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: _isGenerating
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : ListenableBuilder(
                            listenable: LanguageService.instance,
                            builder: (context, _) => Text(TryOnStrings.generate),
                          ),
                  ),
                ),
              ),
            ],
            Padding(
              padding: EdgeInsets.fromLTRB(24, 16, 24, bottomPadding + 24),
              child: SizedBox(
                height: 54,
                child: FilledButton(
                  onPressed: _handBytes == null ? _openHandTryOn : widget.onFinished,
                  style: FilledButton.styleFrom(
                    backgroundColor: _handBytes != null
                        ? Colors.white
                        : AppColors.primary,
                    foregroundColor: _handBytes != null
                        ? AppColors.primary
                        : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(27),
                      side: _handBytes != null
                          ? const BorderSide(color: AppColors.primary)
                          : BorderSide.none,
                    ),
                  ),
                  child: ListenableBuilder(
                    listenable: LanguageService.instance,
                    builder: (context, _) => Text(
                      _handBytes != null
                          ? TryOnStrings.getStarted
                          : TryOnStrings.openCamera,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhotoPreview extends StatelessWidget {
  const _PhotoPreview({
    required this.bytes,
    required this.isGenerating,
    required this.onTapCamera,
  });

  final Uint8List? bytes;
  final bool isGenerating;
  final VoidCallback onTapCamera;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: bytes == null ? onTapCamera : null,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE8E8E8)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(19),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (bytes != null)
                Image.memory(bytes!, fit: BoxFit.cover)
              else
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.photo_camera_outlined,
                        size: 56,
                        color: AppColors.title.withValues(alpha: 0.35),
                      ),
                      const SizedBox(height: 12),
                      ListenableBuilder(
                        listenable: LanguageService.instance,
                        builder: (context, _) => Text(
                          TryOnStrings.openCamera,
                          style: TextStyle(
                            color: AppColors.title.withValues(alpha: 0.5),
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              if (isGenerating)
                Container(
                  color: Colors.black.withValues(alpha: 0.55),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(color: AppColors.primary),
                        const SizedBox(height: 16),
                        ListenableBuilder(
                          listenable: LanguageService.instance,
                          builder: (context, _) => Text(
                            TryOnStrings.generating,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (bytes != null && !isGenerating)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Material(
                    color: Colors.black.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(20),
                    child: InkWell(
                      onTap: onTapCamera,
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.refresh, color: Colors.white, size: 18),
                            const SizedBox(width: 6),
                            ListenableBuilder(
                              listenable: LanguageService.instance,
                              builder: (context, _) => Text(
                                TryOnStrings.retakePhoto,
                                style: const TextStyle(color: Colors.white, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
