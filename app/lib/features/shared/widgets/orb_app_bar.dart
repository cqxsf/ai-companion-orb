import 'package:flutter/material.dart';
import '../../../core/theme/orb_colors.dart';
import '../../../core/theme/orb_typography.dart';
import '../models/orb_emotion.dart';

class OrbAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final OrbEmotion? emotion;
  final List<Widget>? actions;
  final Widget? leading;
  final bool showEmotionDot;

  const OrbAppBar({
    super.key,
    required this.title,
    this.emotion,
    this.actions,
    this.leading,
    this.showEmotionDot = false,
  });

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: preferredSize.height + MediaQuery.of(context).padding.top,
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
      decoration: const BoxDecoration(
        color: Colors.transparent,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            if (leading != null)
              leading!
            else
              const SizedBox(width: 8),
            if (showEmotionDot && emotion != null) ...[
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: emotion!.color,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: emotion!.glowColor,
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
            ],
            Text(title, style: OrbTypography.titleLarge),
            const Spacer(),
            if (actions != null) ...actions!,
          ],
        ),
      ),
    );
  }
}

class OrbSliverAppBar extends StatelessWidget {
  final String title;
  final OrbEmotion? emotion;
  final List<Widget>? actions;

  const OrbSliverAppBar({
    super.key,
    required this.title,
    this.emotion,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      backgroundColor: Colors.transparent,
      expandedHeight: 80,
      floating: true,
      snap: true,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
        title: Row(
          children: [
            if (emotion != null) ...[
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: emotion!.color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
            ],
            Text(
              title,
              style: OrbTypography.headlineMedium.copyWith(
                color: OrbColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
      actions: actions,
    );
  }
}
