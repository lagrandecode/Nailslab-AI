import 'package:flutter/material.dart';

import '../constants/try_on_strings.dart';
import '../core/theme/app_colors.dart';
import '../models/nail_style.dart';
import '../services/language_service.dart';
import '../services/nail_style_repository.dart';

class NailStylePicker extends StatefulWidget {
  const NailStylePicker({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final NailStyle? selected;
  final ValueChanged<NailStyle> onSelected;

  @override
  State<NailStylePicker> createState() => _NailStylePickerState();
}

class _NailStylePickerState extends State<NailStylePicker> {
  final _repository = NailStyleRepository.instance;
  String? _activeCategoryId;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await _repository.ensureLoaded();
    if (!mounted) return;
    setState(() {
      _loading = false;
      _activeCategoryId ??= _repository.categories.firstOrNull?.id;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SizedBox(
        height: 150,
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.primary),
          ),
        ),
      );
    }

    final categories = _repository.categories;
    final activeCategoryId = _activeCategoryId ?? categories.first.id;
    final styles = _repository.stylesForCategory(activeCategoryId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: ListenableBuilder(
            listenable: LanguageService.instance,
            builder: (context, _) => Text(
              TryOnStrings.selectStyle,
              style: TextStyle(
                color: AppColors.title.withValues(alpha: 0.85),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: categories.length,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final category = categories[index];
              final isActive = category.id == activeCategoryId;

              return FilterChip(
                label: Text(category.name),
                selected: isActive,
                showCheckmark: false,
                labelStyle: TextStyle(
                  fontSize: 12,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                  color: isActive ? Colors.white : AppColors.title,
                ),
                selectedColor: AppColors.primary,
                backgroundColor: const Color(0xFFF5F5F5),
                side: BorderSide(
                  color: isActive ? AppColors.primary : const Color(0xFFE0E0E0),
                ),
                onSelected: (_) => setState(() => _activeCategoryId = category.id),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 108,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: styles.length,
            separatorBuilder: (context, index) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final style = styles[index];
              final isSelected = widget.selected?.id == style.id;

              return _StyleCard(
                style: style,
                selected: isSelected,
                onTap: () => widget.onSelected(style),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _StyleCard extends StatelessWidget {
  const _StyleCard({
    required this.style,
    required this.selected,
    required this.onTap,
  });

  final NailStyle style;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 88,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Column(
            children: [
              Expanded(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: selected ? AppColors.primary : const Color(0xFFE0E0E0),
                      width: selected ? 2 : 1,
                    ),
                    color: const Color(0xFFF8F8F8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(13),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (style.hasThumbnail)
                          Image.network(
                            style.thumbnailUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                _PlaceholderThumb(shape: style.shape),
                          )
                        else
                          _PlaceholderThumb(shape: style.shape),
                        if (style.isPremium)
                          Positioned(
                            top: 6,
                            right: 6,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.55),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(Icons.star, size: 10, color: Colors.amber),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                style.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  height: 1.15,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: selected ? AppColors.primary : AppColors.title,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlaceholderThumb extends StatelessWidget {
  const _PlaceholderThumb({required this.shape});

  final String shape;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFE4F0), Color(0xFFFCE4EC)],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.back_hand_outlined,
          size: 28,
          color: AppColors.primary.withValues(alpha: 0.45),
        ),
      ),
    );
  }
}
