import 'package:flutter/material.dart';
import '../../../core/theme/orb_colors.dart';
import '../../../core/theme/orb_typography.dart';
import '../models/orb_emotion.dart';

class OrbBottomNav extends StatelessWidget {
  final int currentIndex;
  final OrbEmotion currentEmotion;
  final ValueChanged<int> onTap;

  const OrbBottomNav({
    super.key,
    required this.currentIndex,
    required this.currentEmotion,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final selectedColor = currentEmotion.color;

    return Container(
      decoration: const BoxDecoration(
        color: OrbColors.bgCard,
        border: Border(
          top: BorderSide(color: OrbColors.borderSubtle, width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              _NavItem(
                icon: Icons.home_rounded,
                label: '小光',
                isSelected: currentIndex == 0,
                selectedColor: selectedColor,
                onTap: () => onTap(0),
              ),
              _NavItem(
                icon: Icons.chat_bubble_rounded,
                label: '对话',
                isSelected: currentIndex == 1,
                selectedColor: selectedColor,
                onTap: () => onTap(1),
              ),
              _NavItem(
                icon: Icons.auto_stories_rounded,
                label: '记忆',
                isSelected: currentIndex == 2,
                selectedColor: selectedColor,
                onTap: () => onTap(2),
              ),
              _NavItem(
                icon: Icons.settings_rounded,
                label: '设置',
                isSelected: currentIndex == 3,
                selectedColor: selectedColor,
                onTap: () => onTap(3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final Color selectedColor;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.selectedColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected ? selectedColor.withAlpha(26) : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  icon,
                  size: 22,
                  color: isSelected ? selectedColor : OrbColors.textTertiary,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                label,
                style: OrbTypography.labelSmall.copyWith(
                  color: isSelected ? selectedColor : OrbColors.textTertiary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
