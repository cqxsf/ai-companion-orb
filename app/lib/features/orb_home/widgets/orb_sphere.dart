import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/theme/orb_animation.dart';
import '../../../core/theme/orb_colors.dart';
import '../../shared/models/orb_emotion.dart';

class OrbSphere extends StatefulWidget {
  final OrbEmotion emotion;
  final double size;
  final VoidCallback? onTap;
  final bool isListening;

  const OrbSphere({
    super.key,
    required this.emotion,
    this.size = 200,
    this.onTap,
    this.isListening = false,
  });

  @override
  State<OrbSphere> createState() => _OrbSphereState();
}

class _OrbSphereState extends State<OrbSphere>
    with TickerProviderStateMixin {
  late AnimationController _breathController;
  late AnimationController _colorController;
  late Animation<double> _scaleAnim;
  late Animation<double> _opacityAnim;
  late Animation<double> _glowAnim;
  late Animation<Color?> _colorAnim;
  late Animation<Color?> _glowColorAnim;

  Color _fromColor = OrbColors.calm;
  Color _toColor = OrbColors.calm;
  Color _fromGlow = OrbColors.calmGlow;
  Color _toGlow = OrbColors.calmGlow;

  @override
  void initState() {
    super.initState();
    _fromColor = widget.emotion.color;
    _toColor = widget.emotion.color;
    _fromGlow = widget.emotion.glowColor;
    _toGlow = widget.emotion.glowColor;

    _breathController = AnimationController(
      vsync: this,
      duration: OrbAnimation.breathe,
    )..repeat(reverse: true);

    _colorController = AnimationController(
      vsync: this,
      duration: OrbAnimation.colorTransition,
    );

    _scaleAnim = Tween<double>(
      begin: OrbAnimation.breatheMin,
      end: OrbAnimation.breatheMax,
    ).animate(CurvedAnimation(parent: _breathController, curve: OrbAnimation.breatheCurve));

    _opacityAnim = Tween<double>(
      begin: OrbAnimation.breatheOpacityMin,
      end: OrbAnimation.breatheOpacityMax,
    ).animate(CurvedAnimation(parent: _breathController, curve: OrbAnimation.breatheCurve));

    _glowAnim = Tween<double>(
      begin: OrbAnimation.glowMin,
      end: OrbAnimation.glowMax,
    ).animate(CurvedAnimation(parent: _breathController, curve: OrbAnimation.breatheCurve));

    _rebuildColorAnim();
  }

  void _rebuildColorAnim() {
    _colorAnim = ColorTween(begin: _fromColor, end: _toColor).animate(
      CurvedAnimation(parent: _colorController, curve: OrbAnimation.standard),
    );
    _glowColorAnim = ColorTween(begin: _fromGlow, end: _toGlow).animate(
      CurvedAnimation(parent: _colorController, curve: OrbAnimation.standard),
    );
  }

  @override
  void didUpdateWidget(OrbSphere oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.emotion != widget.emotion) {
      _fromColor = _colorAnim.value ?? _toColor;
      _fromGlow = _glowColorAnim.value ?? _toGlow;
      _toColor = widget.emotion.color;
      _toGlow = widget.emotion.glowColor;
      _rebuildColorAnim();
      _colorController.forward(from: 0);

      if (widget.emotion == OrbEmotion.joy) {
        _triggerJoyBounce();
      } else if (widget.emotion == OrbEmotion.sleep) {
        _breathController.duration = OrbAnimation.sleepFade;
      } else if (widget.emotion == OrbEmotion.listen) {
        _breathController.duration = OrbAnimation.listenPulse;
      } else {
        _breathController.duration = OrbAnimation.breathe;
      }
    }

    if (oldWidget.isListening != widget.isListening) {
      if (widget.isListening) {
        _breathController.duration = OrbAnimation.listenPulse;
      } else {
        _breathController.duration = OrbAnimation.breathe;
      }
    }
  }

  void _triggerJoyBounce() {
    _breathController.stop();
    _breathController.duration = OrbAnimation.joyBounce;
    _breathController.forward(from: 0).then((_) {
      if (mounted) {
        _breathController.duration = OrbAnimation.breathe;
        _breathController.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _breathController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: Listenable.merge([_breathController, _colorController]),
        builder: (context, child) {
          final currentColor = _colorAnim.value ?? _toColor;
          final currentGlow = _glowColorAnim.value ?? _toGlow;

          return Opacity(
            opacity: widget.emotion == OrbEmotion.sleep
                ? OrbAnimation.sleepOpacity
                : _opacityAnim.value,
            child: Transform.scale(
              scale: _scaleAnim.value,
              child: SizedBox(
                width: widget.size + _glowAnim.value,
                height: widget.size + _glowAnim.value,
                child: CustomPaint(
                  painter: _OrbPainter(
                    primaryColor: currentColor,
                    glowColor: currentGlow,
                    sphereSize: widget.size,
                    glowRadius: _glowAnim.value,
                    isListening: widget.isListening,
                    animValue: _breathController.value,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _OrbPainter extends CustomPainter {
  final Color primaryColor;
  final Color glowColor;
  final double sphereSize;
  final double glowRadius;
  final bool isListening;
  final double animValue;

  _OrbPainter({
    required this.primaryColor,
    required this.glowColor,
    required this.sphereSize,
    required this.glowRadius,
    required this.isListening,
    required this.animValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = sphereSize / 2;

    // Draw outer glow
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          glowColor,
          glowColor.withAlpha(77),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius + glowRadius / 2));

    canvas.drawCircle(center, radius + glowRadius / 2, glowPaint);

    // Draw inner sphere
    final spherePaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.3, -0.4),
        colors: [
          Colors.white.withAlpha(230),
          primaryColor.withAlpha(230),
          primaryColor.withAlpha(200),
          Color.lerp(primaryColor, Colors.black, 0.5)!.withAlpha(255),
        ],
        stops: const [0.0, 0.3, 0.7, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawCircle(center, radius, spherePaint);

    // Listening ring
    if (isListening) {
      final ringPaint = Paint()
        ..color = primaryColor.withAlpha(128)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      final ringRadius = radius + 16 + 8 * math.sin(animValue * 2 * math.pi);
      canvas.drawCircle(center, ringRadius, ringPaint);

      final ringPaint2 = Paint()
        ..color = primaryColor.withAlpha(64)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;

      final ringRadius2 = radius + 28 + 6 * math.sin(animValue * 2 * math.pi + 1);
      canvas.drawCircle(center, ringRadius2, ringPaint2);
    }

    // Specular highlight
    final highlightPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.4, -0.5),
        colors: [
          Colors.white.withAlpha(100),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius * 0.5));

    canvas.drawCircle(
      Offset(center.dx - radius * 0.2, center.dy - radius * 0.25),
      radius * 0.35,
      highlightPaint,
    );
  }

  @override
  bool shouldRepaint(_OrbPainter oldDelegate) {
    return oldDelegate.primaryColor != primaryColor ||
        oldDelegate.glowColor != glowColor ||
        oldDelegate.glowRadius != glowRadius ||
        oldDelegate.isListening != isListening ||
        oldDelegate.animValue != animValue;
  }
}
