import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/models/orb_emotion.dart';

class SettingsState {
  final String orbName;
  final double volume;
  final bool notifications;
  final bool emergencyNotifications;
  final String userName;
  final OrbEmotion defaultEmotion;
  final bool soundEnabled;
  final bool hapticEnabled;

  const SettingsState({
    required this.orbName,
    required this.volume,
    required this.notifications,
    required this.emergencyNotifications,
    required this.userName,
    required this.defaultEmotion,
    required this.soundEnabled,
    required this.hapticEnabled,
  });

  SettingsState copyWith({
    String? orbName,
    double? volume,
    bool? notifications,
    bool? emergencyNotifications,
    String? userName,
    OrbEmotion? defaultEmotion,
    bool? soundEnabled,
    bool? hapticEnabled,
  }) {
    return SettingsState(
      orbName: orbName ?? this.orbName,
      volume: volume ?? this.volume,
      notifications: notifications ?? this.notifications,
      emergencyNotifications:
          emergencyNotifications ?? this.emergencyNotifications,
      userName: userName ?? this.userName,
      defaultEmotion: defaultEmotion ?? this.defaultEmotion,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      hapticEnabled: hapticEnabled ?? this.hapticEnabled,
    );
  }

  factory SettingsState.initial() {
    return const SettingsState(
      orbName: '小光',
      volume: 0.6,
      notifications: true,
      emergencyNotifications: true,
      userName: '用户',
      defaultEmotion: OrbEmotion.calm,
      soundEnabled: true,
      hapticEnabled: true,
    );
  }
}

class SettingsController extends StateNotifier<SettingsState> {
  SettingsController() : super(SettingsState.initial());

  void setOrbName(String name) {
    if (name.trim().isNotEmpty) {
      state = state.copyWith(orbName: name.trim());
    }
  }

  void setVolume(double volume) {
    state = state.copyWith(volume: volume.clamp(0, 1));
  }

  void toggleNotifications(bool value) {
    state = state.copyWith(notifications: value);
  }

  void toggleEmergencyNotifications(bool value) {
    state = state.copyWith(emergencyNotifications: value);
  }

  void setUserName(String name) {
    if (name.trim().isNotEmpty) {
      state = state.copyWith(userName: name.trim());
    }
  }

  void setDefaultEmotion(OrbEmotion emotion) {
    state = state.copyWith(defaultEmotion: emotion);
  }

  void toggleSound(bool value) {
    state = state.copyWith(soundEnabled: value);
  }

  void toggleHaptic(bool value) {
    state = state.copyWith(hapticEnabled: value);
  }
}

final settingsProvider = StateNotifierProvider<SettingsController, SettingsState>(
  (ref) => SettingsController(),
);
