import 'package:flutter/material.dart';
import '../../../core/theme/orb_colors.dart';
import '../../../core/theme/orb_typography.dart';
import '../../../core/theme/orb_spacing.dart';
import '../../shared/models/orb_emotion.dart';

class EmotionTransition extends StatefulWidget {
  final OrbEmotion emotion;

  const EmotionTransition({super.key, required this.emotion});

  @override
  State<EmotionTransition> createState() => _EmotionTransitionState();
}

class _EmotionTransitionState extends State<EmotionTransition>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0, 0.5)),
    );
    _scaleAnim = Tween<double>(begin: 0.5, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _controller.forward();

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) _controller.reverse();
    });
  }

  @override
  void didUpdateWidget(EmotionTransition oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.emotion != widget.emotion) {
      _controller.forward(from: 0);
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) _controller.reverse();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        if (_fadeAnim.value == 0) return const SizedBox.shrink();
        return FadeTransition(
          opacity: _fadeAnim,
          child: Transform.scale(
            scale: _scaleAnim.value,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: OrbSpacing.md,
                vertical: OrbSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: widget.emotion.glowColor,
                borderRadius: BorderRadius.circular(OrbSpacing.radiusFull),
                border: Border.all(color: widget.emotion.color.withAlpha(100)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.emotion.emoji,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(width: OrbSpacing.xs),
                  Text(
                    '小光感到${widget.emotion.label}',
                    style: OrbTypography.labelMedium.copyWith(
                      color: widget.emotion.lightColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
