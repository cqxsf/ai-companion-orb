import 'package:flutter/material.dart';
import '../../../core/theme/orb_colors.dart';

enum OrbEmotion { calm, joy, care, listen, concern, excited, sleep }

extension OrbEmotionExt on OrbEmotion {
  Color get color {
    switch (this) {
      case OrbEmotion.calm:
        return OrbColors.calm;
      case OrbEmotion.joy:
        return OrbColors.joy;
      case OrbEmotion.care:
        return OrbColors.care;
      case OrbEmotion.listen:
        return OrbColors.listen;
      case OrbEmotion.concern:
        return OrbColors.concern;
      case OrbEmotion.excited:
        return OrbColors.excited;
      case OrbEmotion.sleep:
        return OrbColors.sleep;
    }
  }

  Color get lightColor {
    switch (this) {
      case OrbEmotion.calm:
        return OrbColors.calmLight;
      case OrbEmotion.joy:
        return OrbColors.joyLight;
      case OrbEmotion.care:
        return OrbColors.careLight;
      case OrbEmotion.listen:
        return OrbColors.listenLight;
      case OrbEmotion.concern:
        return OrbColors.concernLight;
      case OrbEmotion.excited:
        return OrbColors.excitedLight;
      case OrbEmotion.sleep:
        return OrbColors.sleepLight;
    }
  }

  Color get glowColor {
    switch (this) {
      case OrbEmotion.calm:
        return OrbColors.calmGlow;
      case OrbEmotion.joy:
        return OrbColors.joyGlow;
      case OrbEmotion.care:
        return OrbColors.careGlow;
      case OrbEmotion.listen:
        return OrbColors.listenGlow;
      case OrbEmotion.concern:
        return OrbColors.concernGlow;
      case OrbEmotion.excited:
        return OrbColors.excitedGlow;
      case OrbEmotion.sleep:
        return OrbColors.sleepGlow;
    }
  }

  String get label {
    switch (this) {
      case OrbEmotion.calm:
        return '平静';
      case OrbEmotion.joy:
        return '愉悦';
      case OrbEmotion.care:
        return '关怀';
      case OrbEmotion.listen:
        return '倾听';
      case OrbEmotion.concern:
        return '担心';
      case OrbEmotion.excited:
        return '兴奋';
      case OrbEmotion.sleep:
        return '休眠';
    }
  }

  String get emoji {
    switch (this) {
      case OrbEmotion.calm:
        return '🌙';
      case OrbEmotion.joy:
        return '✨';
      case OrbEmotion.care:
        return '💗';
      case OrbEmotion.listen:
        return '👂';
      case OrbEmotion.concern:
        return '💙';
      case OrbEmotion.excited:
        return '🎉';
      case OrbEmotion.sleep:
        return '😴';
    }
  }

  String get description {
    switch (this) {
      case OrbEmotion.calm:
        return '宁静而温和，陪伴你慢慢休息';
      case OrbEmotion.joy:
        return '充满活力，感受到你的快乐';
      case OrbEmotion.care:
        return '温柔地关心着你的一切';
      case OrbEmotion.listen:
        return '专注地倾听你想说的话';
      case OrbEmotion.concern:
        return '有点担心你，希望你一切都好';
      case OrbEmotion.excited:
        return '和你一起分享这份喜悦';
      case OrbEmotion.sleep:
        return '安静地守护你的睡眠';
    }
  }

  OrbEmotion get next {
    final values = OrbEmotion.values;
    final nextIndex = (values.indexOf(this) + 1) % values.length;
    return values[nextIndex];
  }
}
