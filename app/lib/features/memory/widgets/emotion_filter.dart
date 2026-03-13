import 'package:flutter/material.dart';
import '../../../core/theme/orb_colors.dart';
import '../../../core/theme/orb_typography.dart';
import '../../../core/theme/orb_spacing.dart';
import '../../shared/models/orb_emotion.dart';

class EmotionFilter extends StatelessWidget {
  final OrbEmotion? selectedEmotion;
  final ValueChanged<OrbEmotion?> onFilterChanged;

  const EmotionFilter({
    super.key,
    this.selectedEmotion,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: OrbSpacing.lg),
        children: [
          _FilterChip(
            label: '全部',
            emoji: '✨',
            isSelected: selectedEmotion == null,
            selectedColor: OrbColors.calm,
            onTap: () => onFilterChanged(null),
          ),
          const SizedBox(width: OrbSpacing.sm),
          ...OrbEmotion.values.map((emotion) {
            return Padding(
              padding: const EdgeInsets.only(right: OrbSpacing.sm),
              child: _FilterChip(
                label: emotion.label,
                emoji: emotion.emoji,
                isSelected: selectedEmotion == emotion,
                selectedColor: emotion.color,
                glowColor: emotion.glowColor,
                onTap: () => onFilterChanged(emotion),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final String emoji;
  final bool isSelected;
  final Color selectedColor;
  final Color? glowColor;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.emoji,
    required this.isSelected,
    required this.selectedColor,
    this.glowColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: OrbSpacing.md,
          vertical: OrbSpacing.xs + 2,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? (glowColor ?? OrbColors.calmGlow)
              : OrbColors.bgCard,
          borderRadius: BorderRadius.circular(OrbSpacing.radiusFull),
          border: Border.all(
            color: isSelected ? selectedColor : OrbColors.borderSubtle,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: OrbSpacing.xs),
            Text(
              label,
              style: OrbTypography.labelMedium.copyWith(
                color: isSelected ? selectedColor : OrbColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
