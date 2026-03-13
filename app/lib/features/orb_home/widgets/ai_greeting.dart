import 'package:flutter/material.dart';
import '../../../core/theme/orb_colors.dart';
import '../../../core/theme/orb_typography.dart';
import '../../shared/models/orb_emotion.dart';

class AiGreeting extends StatefulWidget {
  final String greeting;
  final OrbEmotion emotion;

  const AiGreeting({
    super.key,
    required this.greeting,
    required this.emotion,
  });

  @override
  State<AiGreeting> createState() => _AiGreetingState();
}

class _AiGreetingState extends State<AiGreeting>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  String _displayedGreeting = '';

  @override
  void initState() {
    super.initState();
    _displayedGreeting = widget.greeting;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
  }

  @override
  void didUpdateWidget(AiGreeting oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.greeting != widget.greeting) {
      _controller.reverse().then((_) {
        setState(() {
          _displayedGreeting = widget.greeting;
        });
        _controller.forward();
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
    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          margin: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            color: OrbColors.bgCard,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: OrbColors.borderSubtle),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: widget.emotion.glowColor,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    widget.emotion.emoji,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '小光',
                      style: OrbTypography.labelMedium.copyWith(
                        color: widget.emotion.lightColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _displayedGreeting,
                      style: OrbTypography.bodyLarge.copyWith(
                        color: OrbColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
