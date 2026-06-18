import 'package:flutter/material.dart';

import '../constants/app_strings.dart';
import '../core/theme/app_colors.dart';
import '../services/language_service.dart';

class LanguageSelectorButton extends StatelessWidget {
  const LanguageSelectorButton({super.key, this.compact = true});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LanguageService.instance,
      builder: (context, _) {
        final current = LanguageService.instance.current;

        return PopupMenuButton<String>(
          tooltip: AppStrings.settingsLanguageLabel,
          onSelected: LanguageService.instance.setLanguageCode,
          offset: const Offset(0, 40),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          itemBuilder: (context) {
            return LanguageService.supported
                .map(
                  (language) => CheckedPopupMenuItem<String>(
                    value: language.code,
                    checked: language.code == current.code,
                    child: Row(
                      children: [
                        Text(language.flag, style: const TextStyle(fontSize: 18)),
                        const SizedBox(width: 10),
                        Expanded(child: Text(language.name)),
                      ],
                    ),
                  ),
                )
                .toList();
          },
          child: compact ? _CompactChip(current: current) : _FullChip(current: current),
        );
      },
    );
  }
}

class _CompactChip extends StatelessWidget {
  const _CompactChip({required this.current});

  final AppLanguage current;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(current.flag, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Text(
              current.code.toUpperCase(),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.title,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FullChip extends StatelessWidget {
  const _FullChip({required this.current});

  final AppLanguage current;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      leading: const Icon(Icons.language_rounded),
      title: Text(AppStrings.settingsLanguageLabel),
      subtitle: Text('${current.flag} ${current.name}'),
      trailing: const Icon(Icons.expand_more_rounded),
    );
  }
}
