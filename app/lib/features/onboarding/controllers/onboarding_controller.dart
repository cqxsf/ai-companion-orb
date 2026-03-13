import 'package:flutter_riverpod/flutter_riverpod.dart';

enum OnboardingStep { welcome, setName, connectOrb, done }

class OnboardingState {
  final OnboardingStep step;
  final String userName;
  final String orbName;
  final bool isConnecting;
  final bool isConnected;

  const OnboardingState({
    this.step = OnboardingStep.welcome,
    this.userName = '',
    this.orbName = '小光',
    this.isConnecting = false,
    this.isConnected = false,
  });

  OnboardingState copyWith({
    OnboardingStep? step,
    String? userName,
    String? orbName,
    bool? isConnecting,
    bool? isConnected,
  }) {
    return OnboardingState(
      step: step ?? this.step,
      userName: userName ?? this.userName,
      orbName: orbName ?? this.orbName,
      isConnecting: isConnecting ?? this.isConnecting,
      isConnected: isConnected ?? this.isConnected,
    );
  }
}

class OnboardingController extends StateNotifier<OnboardingState> {
  OnboardingController() : super(const OnboardingState());

  void goToNext() {
    final steps = OnboardingStep.values;
    final currentIndex = steps.indexOf(state.step);
    if (currentIndex < steps.length - 1) {
      state = state.copyWith(step: steps[currentIndex + 1]);
    }
  }

  void setUserName(String name) {
    state = state.copyWith(userName: name);
  }

  void setOrbName(String name) {
    state = state.copyWith(orbName: name);
  }

  Future<void> simulateConnect() async {
    state = state.copyWith(isConnecting: true);
    await Future.delayed(const Duration(seconds: 2));
    state = state.copyWith(
      isConnecting: false,
      isConnected: true,
      step: OnboardingStep.done,
    );
  }

  void reset() {
    state = const OnboardingState();
  }
}

final onboardingProvider =
    StateNotifierProvider<OnboardingController, OnboardingState>(
  (ref) => OnboardingController(),
);
