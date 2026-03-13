import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/orb_colors.dart';
import '../../../core/theme/orb_typography.dart';
import '../../../core/theme/orb_spacing.dart';
import '../../shared/models/memory.dart';

class MemoryCard extends StatelessWidget {
  final Memory memory;
  final bool isLarge;

  const MemoryCard({
    super.key,
    required this.memory,
    this.isLarge = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/memory/${memory.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: OrbColors.bgCard,
          borderRadius: BorderRadius.circular(OrbSpacing.radiusLg),
          border: Border.all(color: OrbColors.borderSubtle),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Color accent top bar
            Container(
              height: 4,
              decoration: BoxDecoration(
                color: memory.emotion.color,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(OrbSpacing.radiusLg),
                  topRight: Radius.circular(OrbSpacing.radiusLg),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(OrbSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        memory.emotion.emoji,
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(width: OrbSpacing.xs),
                      Text(
                        memory.emotion.label,
                        style: OrbTypography.labelSmall.copyWith(
                          color: memory.emotion.lightColor,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _formatDate(memory.date),
                        style: OrbTypography.caption,
                      ),
                    ],
                  ),
                  const SizedBox(height: OrbSpacing.sm),
                  Text(
                    memory.title,
                    style: OrbTypography.titleMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: OrbSpacing.xs),
                  Text(
                    memory.excerpt,
                    style: OrbTypography.bodySmall,
                    maxLines: isLarge ? 4 : 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (memory.tags.isNotEmpty) ...[
                    const SizedBox(height: OrbSpacing.sm),
                    Wrap(
                      spacing: OrbSpacing.xs,
                      runSpacing: OrbSpacing.xs,
                      children: memory.tags.take(3).map((tag) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: OrbSpacing.sm,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: memory.emotion.glowColor,
                            borderRadius: BorderRadius.circular(OrbSpacing.radiusFull),
                          ),
                          child: Text(
                            tag,
                            style: OrbTypography.labelSmall.copyWith(
                              color: memory.emotion.lightColor,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) return '今天';
    if (diff.inDays == 1) return '昨天';
    if (diff.inDays < 7) return '${diff.inDays}天前';
    return '${date.month}月${date.day}日';
  }
}
