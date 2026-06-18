import 'package:flutter/material.dart';

import '../../constants/app_strings.dart';
import '../../constants/asset_paths.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/animated_onboarding_headline.dart';

class OnboardingPageTwo extends StatefulWidget {
  const OnboardingPageTwo({super.key, required this.onContinue});

  final VoidCallback onContinue;

  @override
  State<OnboardingPageTwo> createState() => _OnboardingPageTwoState();
}

class _OnboardingPageTwoState extends State<OnboardingPageTwo> {
  bool _showHeadline = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      setState(() => _showHeadline = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          AssetPaths.onboardingImage2,
          fit: BoxFit.cover,
          alignment: Alignment.center,
        ),
        OnboardingHeadlineOverlay(
          headline: () => AppStrings.onboardingTwoHeadline,
          play: _showHeadline,
        ),
        Positioned(
          left: 24,
          right: 24,
          bottom: bottomPadding + 24,
          child: SizedBox(
            width: double.infinity,
            height: 54,
            child: FilledButton(
              onPressed: widget.onContinue,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(27),
                ),
              ),
              child: Text(AppStrings.continueLabel),
            ),
          ),
        ),
      ],
    );
  }
}
