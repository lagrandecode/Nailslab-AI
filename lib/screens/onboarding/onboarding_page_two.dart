import 'package:flutter/material.dart';

import '../../constants/asset_paths.dart';
import '../../core/theme/app_colors.dart';

class OnboardingPageTwo extends StatelessWidget {
  const OnboardingPageTwo({super.key, required this.onContinue});

  final VoidCallback onContinue;

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
        Positioned(
          left: 24,
          right: 24,
          bottom: bottomPadding + 24,
          child: SizedBox(
            width: double.infinity,
            height: 54,
            child: FilledButton(
              onPressed: onContinue,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(27),
                ),
                textStyle: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: const Text('Continue'),
            ),
          ),
        ),
      ],
    );
  }
}
