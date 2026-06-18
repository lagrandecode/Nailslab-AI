import 'package:flutter/material.dart';

import '../core/haptics/app_haptics.dart';
import '../core/theme/app_colors.dart';
import '../models/nail_look.dart';

enum CameraPanelTab { looks, color, aiGenerate }

class CameraBottomPanel extends StatelessWidget {
  const CameraBottomPanel({
    super.key,
    required this.activeTab,
    required this.looks,
    required this.selectedLookId,
    required this.onTabChanged,
    required this.onLookSelected,
  });

  final CameraPanelTab activeTab;
  final List<NailLook> looks;
  final String? selectedLookId;
  final ValueChanged<CameraPanelTab> onTabChanged;
  final ValueChanged<NailLook> onLookSelected;

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
          else
            SizedBox(
              height: 56,
              child: Center(
                child: Text(
                  activeTab == CameraPanelTab.color
                      ? 'Color presets coming soon'
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
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: selected ? AppColors.primary : const Color(0xFFE0E0E0),
                    width: selected ? 2 : 1,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(9),
                  child: Image.asset(
                    look.thumbnailAsset,
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              look.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: selected ? AppColors.primary : AppColors.title,
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
              color: selected ? AppColors.primary : AppColors.title.withValues(alpha: 0.45),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: selected ? AppColors.primary : AppColors.title.withValues(alpha: 0.45),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
