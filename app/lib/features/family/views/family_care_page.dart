import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/orb_colors.dart';
import '../../../core/theme/orb_spacing.dart';
import '../../../core/theme/orb_typography.dart';
import '../../shared/models/orb_emotion.dart';
import '../controllers/family_controller.dart';

class FamilyCarePage extends ConsumerWidget {
  const FamilyCarePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final familyState = ref.watch(familyProvider);

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
                    Text('家人关怀', style: OrbTypography.displayMedium),
                    const SizedBox(height: OrbSpacing.xs),
                    Text('来自家人的爱与关心', style: OrbTypography.bodyMedium),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: OrbSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '家庭成员',
                    style: OrbTypography.titleMedium.copyWith(
                      color: OrbColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: OrbSpacing.md),
                  SizedBox(
                    height: 90,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: familyState.members.length,
                      itemBuilder: (context, index) {
                        final member = familyState.members[index];
                        return Container(
                          margin: const EdgeInsets.only(right: OrbSpacing.md),
                          child: Column(
                            children: [
                              Stack(
                                children: [
                                  Container(
                                    width: 56,
                                    height: 56,
                                    decoration: BoxDecoration(
                                      color: OrbColors.bgCard,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: member.isOnline
                                            ? OrbColors.listen
                                            : OrbColors.borderSubtle,
                                        width: 2,
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        member.avatar,
                                        style: const TextStyle(fontSize: 24),
                                      ),
                                    ),
                                  ),
                                  if (member.isOnline)
                                    Positioned(
                                      bottom: 2,
                                      right: 2,
                                      child: Container(
                                        width: 12,
                                        height: 12,
                                        decoration: BoxDecoration(
                                          color: OrbColors.listen,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: OrbColors.bgBase,
                                            width: 2,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: OrbSpacing.xs),
                              Text(
                                member.name,
                                style: OrbTypography.labelSmall,
                              ),
                              Text(
                                member.relation,
                                style: OrbTypography.caption,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: OrbSpacing.lg),
                  Text(
                    '关怀消息',
                    style: OrbTypography.titleMedium.copyWith(
                      color: OrbColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: OrbSpacing.md),
                  ...familyState.careMessages.map((msg) {
                    return Container(
                      margin:
                          const EdgeInsets.only(bottom: OrbSpacing.md),
                      padding: const EdgeInsets.all(OrbSpacing.md),
                      decoration: BoxDecoration(
                        color: OrbColors.bgCard,
                        borderRadius:
                            BorderRadius.circular(OrbSpacing.radiusLg),
                        border: Border.all(color: OrbColors.borderSubtle),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: msg.emotion.glowColor,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                msg.emotion.emoji,
                                style: const TextStyle(fontSize: 20),
                              ),
                            ),
                          ),
                          const SizedBox(width: OrbSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      msg.fromName,
                                      style: OrbTypography.titleMedium,
                                    ),
                                    const Spacer(),
                                    Text(
                                      _formatTime(msg.timestamp),
                                      style: OrbTypography.caption,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: OrbSpacing.xs),
                                Text(
                                  msg.content,
                                  style: OrbTypography.bodyMedium.copyWith(
                                    color: OrbColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: OrbSpacing.xxl),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inMinutes < 1) return '刚刚';
    if (diff.inHours < 1) return '${diff.inMinutes}分钟前';
    if (diff.inDays < 1) return '${diff.inHours}小时前';
    return '${time.month}月${time.day}日';
  }
}
