import 'package:flutter/material.dart';

import '../core/haptics/app_haptics.dart';
import '../core/theme/app_colors.dart';
import '../models/nail_look.dart';

enum CameraPanelTab { looks, color, aiGenerate }

/// Preset nail polish colors for plain-mode finger painting.
const plainNailColors = <Color>[
  Color(0xFFC41230),
  Color(0xFFE91E8C),
  Color(0xFFFF6B35),
  Color(0xFFD4AF37),
  Color(0xFFB76E79),
  Color(0xFF9B59B6),
  Color(0xFF1A1A1A),
  Color(0xFFF5F5F5),
];

class CameraBottomPanel extends StatelessWidget {
  const CameraBottomPanel({
    super.key,
    required this.activeTab,
    required this.looks,
    required this.selectedLookId,
    required this.onTabChanged,
    required this.onLookSelected,
    this.plainMode = false,
    this.selectedFingerLabel,
    this.onColorSelected,
    this.onClearColor,
    this.selectedColor,
  });

  final CameraPanelTab activeTab;
  final List<NailLook> looks;
  final String? selectedLookId;
  final ValueChanged<CameraPanelTab> onTabChanged;
  final ValueChanged<NailLook> onLookSelected;
  final bool plainMode;
  final String? selectedFingerLabel;
  final ValueChanged<Color>? onColorSelected;
  final VoidCallback? onClearColor;
  final Color? selectedColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (activeTab == CameraPanelTab.looks)
            SizedBox(
              height: 112,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                itemCount: looks.length,
                separatorBuilder: (context, index) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final look = looks[index];
                  final selected = look.id == selectedLookId;
                  return _LookThumbnail(
                    look: look,
                    selected: selected,
                    onTap: () {
                      AppHaptics.heavy();
                      onLookSelected(look);
                    },
                  );
                },
              ),
            )
          else if (activeTab == CameraPanelTab.color)
            SizedBox(
              height: 88,
              child: Column(
                children: [
                  if (plainMode && selectedFingerLabel != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: Text(
                        selectedFingerLabel!,
                        style: TextStyle(
                          color: AppColors.title.withValues(alpha: 0.55),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  Expanded(
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                      itemCount: plainNailColors.length + 1,
                      separatorBuilder: (context, index) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return _ColorSwatch(
                            color: Colors.transparent,
                            isClear: true,
                            onTap: onClearColor,
                          );
                        }
                        final color = plainNailColors[index - 1];
                        return _ColorSwatch(
                          color: color,
                          selected: !plainMode && color == selectedColor,
                          onTap: () {
                            AppHaptics.heavy();
                            onColorSelected?.call(color);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            )
          else
            SizedBox(
              height: 56,
              child: Center(
                child: Text(
                  activeTab == CameraPanelTab.color
                      ? 'Switch to plain mode to paint nail colors'
                      : 'Capture a photo to use AI Generate',
                  style: TextStyle(
                    color: AppColors.title.withValues(alpha: 0.55),
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                _TabButton(
                  label: 'Looks',
                  icon: Icons.auto_awesome_outlined,
                  selected: activeTab == CameraPanelTab.looks,
                  onTap: () => onTabChanged(CameraPanelTab.looks),
                ),
                _TabButton(
                  label: 'Color',
                  icon: Icons.palette_outlined,
                  selected: activeTab == CameraPanelTab.color,
                  onTap: () => onTabChanged(CameraPanelTab.color),
                ),
                _TabButton(
                  label: 'AI Generate',
                  icon: Icons.bolt_outlined,
                  selected: activeTab == CameraPanelTab.aiGenerate,
                  onTap: () => onTabChanged(CameraPanelTab.aiGenerate),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ColorSwatch extends StatelessWidget {
  const _ColorSwatch({
    required this.color,
    this.isClear = false,
    this.onTap,
    this.selected = false,
  });

  final Color color;
  final bool isClear;
  final VoidCallback? onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isClear ? Colors.white : color,
          border: Border.all(
            color: selected
                ? AppColors.primary
                : AppColors.title.withValues(alpha: isClear ? 0.25 : 0.12),
            width: selected ? 2.5 : (isClear ? 1.5 : 1),
          ),
        ),
        child: isClear
            ? Icon(
                Icons.close,
                size: 18,
                color: AppColors.title.withValues(alpha: 0.45),
              )
            : null,
      ),
    );
  }
}

class _LookThumbnail extends StatelessWidget {
  const _LookThumbnail({
    required this.look,
    required this.selected,
    required this.onTap,
  });

  final NailLook look;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 72,
        child: Column(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: selected ? AppColors.primary : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.asset(
                    look.thumbnailAsset,
                    fit: BoxFit.cover,
                    width: double.infinity,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              look.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                color: selected
                    ? AppColors.primary
                    : AppColors.title.withValues(alpha: 0.7),
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 22,
              color: selected
                  ? AppColors.primary
                  : AppColors.title.withValues(alpha: 0.45),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: selected
                    ? AppColors.primary
                    : AppColors.title.withValues(alpha: 0.45),
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
