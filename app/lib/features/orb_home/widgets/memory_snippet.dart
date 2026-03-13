import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/orb_colors.dart';
import '../../../core/theme/orb_typography.dart';
import '../../../core/theme/orb_spacing.dart';
import '../../shared/models/memory.dart';
import '../../shared/models/orb_emotion.dart';

class MemorySnippet extends StatelessWidget {
  final Memory? memory;
  final OrbEmotion emotion;

  const MemorySnippet({
    super.key,
    this.memory,
    required this.emotion,
  });

  @override
  Widget build(BuildContext context) {
    if (memory == null) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () => context.push('/memory/${memory!.id}'),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: OrbSpacing.lg),
        padding: const EdgeInsets.all(OrbSpacing.md),
        decoration: BoxDecoration(
          color: OrbColors.bgCard,
          borderRadius: BorderRadius.circular(OrbSpacing.radiusLg),
          border: Border(
            left: BorderSide(
              color: emotion.color,
              width: 3,
            ),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        memory!.emotion.emoji,
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(width: OrbSpacing.xs),
                      Text(
                        '最近的记忆',
                        style: OrbTypography.labelSmall.copyWith(
                          color: emotion.lightColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: OrbSpacing.xs),
                  Text(
                    memory!.title,
                    style: OrbTypography.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    memory!.excerpt,
                    style: OrbTypography.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: OrbSpacing.sm),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: OrbColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}
