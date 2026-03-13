import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/orb_colors.dart';
import '../../../core/theme/orb_spacing.dart';
import '../../../core/theme/orb_typography.dart';
import '../controllers/memory_controller.dart';
import '../widgets/memory_card.dart';
import '../widgets/emotion_filter.dart';

class MemoryPage extends ConsumerWidget {
  const MemoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memoryState = ref.watch(memoryProvider);
    final controller = ref.read(memoryProvider.notifier);
    final memories = memoryState.filteredMemories;

    return Scaffold(
      backgroundColor: OrbColors.bgBase,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.all(OrbSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('记忆', style: OrbTypography.displayMedium),
                    const SizedBox(height: OrbSpacing.xs),
                    Text(
                      '与小光共同珍藏的每一刻',
                      style: OrbTypography.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: EmotionFilter(
              selectedEmotion: memoryState.filterEmotion,
              onFilterChanged: controller.setFilter,
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: OrbSpacing.lg)),
          if (memories.isEmpty)
            SliverFillRemaining(
              child: _buildEmptyState(),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: OrbSpacing.lg),
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final memory = memories[index];
                    return MemoryCard(
                      memory: memory,
                      isLarge: index == 0 && memories.length > 2,
                    );
                  },
                  childCount: memories.length,
                ),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: memories.length == 1 ? 1 : 2,
                  crossAxisSpacing: OrbSpacing.sm,
                  mainAxisSpacing: OrbSpacing.sm,
                  childAspectRatio: memories.length == 1 ? 1.6 : 0.9,
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: OrbSpacing.xxl)),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🔍', style: TextStyle(fontSize: 48)),
          const SizedBox(height: OrbSpacing.md),
          Text(
            '没有找到相关记忆',
            style: OrbTypography.headlineSmall,
          ),
          const SizedBox(height: OrbSpacing.sm),
          Text(
            '换个情感标签试试？',
            style: OrbTypography.bodyMedium,
          ),
        ],
      ),
    );
  }
}
