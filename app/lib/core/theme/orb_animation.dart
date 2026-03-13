import 'package:flutter/animation.dart';

class OrbAnimation {
  OrbAnimation._();

  // Durations
  static const Duration breathe = Duration(seconds: 4);
  static const Duration joyBounce = Duration(milliseconds: 600);
  static const Duration sleepFade = Duration(seconds: 3);
  static const Duration listenPulse = Duration(milliseconds: 800);
  static const Duration colorTransition = Duration(milliseconds: 500);
  static const Duration pageTransition = Duration(milliseconds: 300);
  static const Duration microInteraction = Duration(milliseconds: 150);
  static const Duration emotionChange = Duration(milliseconds: 400);

  // Curves
  static const Curve breatheCurve = Curves.easeInOut;
  static const Curve bounceCurve = Curves.elasticOut;
  static const Curve fadeCurve = Curves.easeIn;
  static const Curve pulseCurve = Curves.easeInOut;
  static const Curve standard = Curves.easeInOut;

  // Scale values
  static const double breatheMin = 0.95;
  static const double breatheMax = 1.05;
  static const double joyScale = 1.15;
  static const double listenScale = 1.08;
  static const double sleepOpacity = 0.15;

  // Glow radii
  static const double glowMin = 100.0;
  static const double glowMax = 140.0;

  // Opacity values
  static const double breatheOpacityMin = 0.7;
  static const double breatheOpacityMax = 1.0;
}
