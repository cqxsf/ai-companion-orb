import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/orb_colors.dart';
import '../../../core/theme/orb_spacing.dart';
import '../../../core/theme/orb_typography.dart';
import '../controllers/orb_home_controller.dart';
import '../widgets/orb_sphere.dart';
import '../widgets/ai_greeting.dart';
import '../widgets/memory_snippet.dart';
import '../../shared/models/orb_emotion.dart';

class OrbHomePage extends ConsumerWidget {
  const OrbHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeState = ref.watch(orbHomeProvider);
    final controller = ref.read(orbHomeProvider.notifier);
    final emotion = homeState.currentEmotion;

    return Scaffold(
      backgroundColor: OrbColors.bgBase,
      body: Stack(
        children: [
          // Background gradient
          _buildBackground(emotion),
          // Main content
          SafeArea(
            child: Column(
              children: [
                _buildTopBar(context, emotion, controller),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      children: [
                        const SizedBox(height: OrbSpacing.xxl),
                        // Orb sphere centered
                        Center(
                          child: OrbSphere(
                            emotion: emotion,
                            size: 200,
                            isListening: homeState.isListening,
                            onTap: controller.cycleEmotion,
                          ),
                        ),
                        const SizedBox(height: OrbSpacing.lg),
                        // Emotion label
                        _buildEmotionLabel(emotion),
                        const SizedBox(height: OrbSpacing.xl),
                        // AI Greeting
                        AiGreeting(
                          greeting: homeState.greeting,
                          emotion: emotion,
                        ),
                        const SizedBox(height: OrbSpacing.lg),
                        // Recent memory
                        if (homeState.recentMemories.isNotEmpty)
                          MemorySnippet(
                            memory: homeState.recentMemories.first,
                            emotion: emotion,
                          ),
                        // Emotion selector
                        const SizedBox(height: OrbSpacing.xl),
                        _buildEmotionSelector(emotion, controller),
                        const SizedBox(height: OrbSpacing.xxl),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Floating mic button
          Positioned(
            right: OrbSpacing.lg,
            bottom: OrbSpacing.lg,
            child: _buildMicButton(homeState, controller),
          ),
        ],
      ),
    );
  }

  Widget _buildBackground(OrbEmotion emotion) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(0, -0.3),
          radius: 0.8,
          colors: [
            emotion.glowColor,
            OrbColors.bgBase,
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(
    BuildContext context,
    OrbEmotion emotion,
    OrbHomeController controller,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: OrbSpacing.lg,
        vertical: OrbSpacing.sm,
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '小光',
                style: OrbTypography.headlineMedium,
              ),
              Text(
                '你的 AI 陪伴',
                style: OrbTypography.caption,
              ),
            ],
          ),
          const Spacer(),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: OrbColors.bgCard,
              shape: BoxShape.circle,
              border: Border.all(color: OrbColors.borderSubtle),
            ),
            child: const Icon(
              Icons.notifications_rounded,
              size: 20,
              color: OrbColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmotionLabel(OrbEmotion emotion) {
    return Column(
      children: [
        Text(
          emotion.emoji,
          style: const TextStyle(fontSize: 28),
        ),
        const SizedBox(height: OrbSpacing.xs),
        Text(
          emotion.label,
          style: OrbTypography.headlineSmall.copyWith(
            color: emotion.lightColor,
          ),
        ),
        const SizedBox(height: OrbSpacing.xs),
        Text(
          emotion.description,
          style: OrbTypography.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildEmotionSelector(
    OrbEmotion current,
    OrbHomeController controller,
  ) {
    return SizedBox(
      height: 56,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: OrbSpacing.lg),
        children: OrbEmotion.values.map((emotion) {
          final isSelected = emotion == current;
          return GestureDetector(
            onTap: () => controller.changeEmotion(emotion),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.only(right: OrbSpacing.sm),
              padding: const EdgeInsets.symmetric(
                horizontal: OrbSpacing.md,
                vertical: OrbSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: isSelected ? emotion.glowColor : OrbColors.bgCard,
                borderRadius: BorderRadius.circular(OrbSpacing.radiusFull),
                border: Border.all(
                  color: isSelected ? emotion.color : OrbColors.borderSubtle,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    emotion.emoji,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(width: OrbSpacing.xs),
                  Text(
                    emotion.label,
                    style: OrbTypography.labelMedium.copyWith(
                      color: isSelected ? emotion.lightColor : OrbColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMicButton(OrbHomeState state, OrbHomeController controller) {
    return GestureDetector(
      onTap: state.isListening ? controller.stopListening : controller.startListening,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: state.isListening
              ? OrbColors.listen
              : state.currentEmotion.color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: state.currentEmotion.glowColor,
              blurRadius: state.isListening ? 20 : 12,
              spreadRadius: state.isListening ? 4 : 0,
            ),
          ],
        ),
        child: Icon(
          state.isListening ? Icons.stop_rounded : Icons.mic_rounded,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }
}
