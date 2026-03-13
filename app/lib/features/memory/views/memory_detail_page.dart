import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/orb_colors.dart';
import '../../../core/theme/orb_spacing.dart';
import '../../../core/theme/orb_typography.dart';
import '../controllers/memory_controller.dart';

class MemoryDetailPage extends ConsumerWidget {
  final String memoryId;

  const MemoryDetailPage({super.key, required this.memoryId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memory = ref.read(memoryProvider.notifier).getMemoryById(memoryId);

    if (memory == null) {
      return Scaffold(
        backgroundColor: OrbColors.bgBase,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('😕', style: TextStyle(fontSize: 48)),
              const SizedBox(height: OrbSpacing.md),
              Text('记忆不见了', style: OrbTypography.headlineSmall),
              const SizedBox(height: OrbSpacing.md),
              TextButton(
                onPressed: () => context.pop(),
                child: const Text('返回'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: OrbColors.bgBase,
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  memory.emotion.glowColor,
                  OrbColors.bgBase,
                ],
                stops: const [0, 0.4],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: OrbSpacing.lg,
                    vertical: OrbSpacing.sm,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => context.pop(),
                        icon: const Icon(Icons.arrow_back_ios_rounded),
                        color: OrbColors.textPrimary,
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: OrbSpacing.md,
                          vertical: OrbSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: memory.emotion.glowColor,
                          borderRadius:
                              BorderRadius.circular(OrbSpacing.radiusFull),
                          border: Border.all(color: memory.emotion.color),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              memory.emotion.emoji,
                              style: const TextStyle(fontSize: 14),
                            ),
                            const SizedBox(width: OrbSpacing.xs),
                            Text(
                              memory.emotion.label,
                              style: OrbTypography.labelMedium.copyWith(
                                color: memory.emotion.lightColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.all(OrbSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Date
                        Text(
                          _formatFullDate(memory.date),
                          style: OrbTypography.caption.copyWith(
                            color: memory.emotion.lightColor,
                          ),
                        ),
                        const SizedBox(height: OrbSpacing.sm),
                        // Title
                        Text(
                          memory.title,
                          style: OrbTypography.displayMedium,
                        ),
                        const SizedBox(height: OrbSpacing.lg),
                        // Content
                        Container(
                          padding: const EdgeInsets.all(OrbSpacing.lg),
                          decoration: BoxDecoration(
                            color: OrbColors.bgCard,
                            borderRadius:
                                BorderRadius.circular(OrbSpacing.radiusLg),
                            border: Border.all(color: OrbColors.borderSubtle),
                          ),
                          child: Text(
                            memory.content,
                            style: OrbTypography.bodyLarge,
                          ),
                        ),
                        const SizedBox(height: OrbSpacing.lg),
                        // Tags
                        if (memory.tags.isNotEmpty) ...[
                          Text('标签', style: OrbTypography.titleMedium),
                          const SizedBox(height: OrbSpacing.sm),
                          Wrap(
                            spacing: OrbSpacing.sm,
                            runSpacing: OrbSpacing.sm,
                            children: memory.tags.map((tag) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: OrbSpacing.md,
                                  vertical: OrbSpacing.xs + 2,
                                ),
                                decoration: BoxDecoration(
                                  color: memory.emotion.glowColor,
                                  borderRadius: BorderRadius.circular(
                                      OrbSpacing.radiusFull),
                                  border:
                                      Border.all(color: memory.emotion.color),
                                ),
                                child: Text(
                                  '# $tag',
                                  style: OrbTypography.labelMedium.copyWith(
                                    color: memory.emotion.lightColor,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                        const SizedBox(height: OrbSpacing.xxl),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatFullDate(DateTime date) {
    const weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    final weekday = weekdays[date.weekday - 1];
    return '${date.year}年${date.month}月${date.day}日 $weekday';
  }
}
