import 'package:flutter/material.dart';

import '../core/haptics/app_haptics.dart';
import '../models/nail_beauty_shape.dart';

class NailShapePicker extends StatelessWidget {
  const NailShapePicker({
    super.key,
    required this.selectedShape,
    required this.onShapeSelected,
  });

  final NailBeautyShape selectedShape;
  final ValueChanged<NailBeautyShape> onShapeSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
        itemCount: NailBeautyShape.pickerOrder.length,
        separatorBuilder: (context, index) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final shape = NailBeautyShape.pickerOrder[index];
          final selected = shape == selectedShape;
          return GestureDetector(
            onTap: () {
              AppHaptics.heavy();
              onShapeSelected(shape);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: selected ? 0.18 : 0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selected ? Colors.white : Colors.white24,
                  width: selected ? 2 : 1,
                ),
              ),
              child: Text(
                shape.label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: selected ? 0.95 : 0.7),
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
