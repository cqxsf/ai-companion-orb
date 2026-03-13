import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/orb_colors.dart';
import '../../../core/theme/orb_spacing.dart';
import '../../../core/theme/orb_typography.dart';
import '../controllers/onboarding_controller.dart';

class OnboardingFlow extends ConsumerStatefulWidget {
  const OnboardingFlow({super.key});

  @override
  ConsumerState<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends ConsumerState<OnboardingFlow> {
  final _nameController = TextEditingController();
  final _orbNameController = TextEditingController(text: '小光');

  @override
  void dispose() {
    _nameController.dispose();
    _orbNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingProvider);
    final controller = ref.read(onboardingProvider.notifier);

    return Scaffold(
      backgroundColor: OrbColors.bgBase,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        child: _buildStep(state, controller),
      ),
    );
  }

  Widget _buildStep(OnboardingState state, OnboardingController controller) {
    switch (state.step) {
      case OnboardingStep.welcome:
        return _buildWelcomePage(controller);
      case OnboardingStep.setName:
        return _buildSetNamePage(controller);
      case OnboardingStep.connectOrb:
        return _buildConnectPage(state, controller);
      case OnboardingStep.done:
        return _buildDonePage();
    }
  }

  Widget _buildWelcomePage(OnboardingController controller) {
    return SafeArea(
      key: const ValueKey('welcome'),
      child: Padding(
        padding: const EdgeInsets.all(OrbSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            // Orb sphere placeholder
            Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    OrbColors.calmLight.withAlpha(200),
                    OrbColors.calm.withAlpha(180),
                    OrbColors.calm.withAlpha(100),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: OrbColors.calmGlow,
                    blurRadius: 60,
                    spreadRadius: 20,
                  ),
                ],
              ),
              child: const Center(
                child: Text('✨', style: TextStyle(fontSize: 48)),
              ),
            ),
            const SizedBox(height: OrbSpacing.xxl),
            Text(
              '你好，我是小光',
              style: OrbTypography.displayLarge.copyWith(
                color: OrbColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: OrbSpacing.md),
            Text(
              '我会陪伴在你身边\n倾听你的故事，分享你的喜怒哀乐',
              style: OrbTypography.bodyLarge.copyWith(
                color: OrbColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: controller.goToNext,
                child: const Text('开始认识'),
              ),
            ),
            const SizedBox(height: OrbSpacing.md),
            TextButton(
              onPressed: () => context.go('/'),
              child: Text(
                '跳过',
                style: OrbTypography.bodyMedium.copyWith(
                  color: OrbColors.textTertiary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSetNamePage(OnboardingController controller) {
    return SafeArea(
      key: const ValueKey('setName'),
      child: Padding(
        padding: const EdgeInsets.all(OrbSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: OrbSpacing.xxl),
            Text(
              '你叫什么名字？',
              style: OrbTypography.displayMedium,
            ),
            const SizedBox(height: OrbSpacing.sm),
            Text(
              '我想记住你的名字，这样更亲切',
              style: OrbTypography.bodyMedium,
            ),
            const SizedBox(height: OrbSpacing.xxl),
            TextField(
              controller: _nameController,
              style: OrbTypography.bodyLarge,
              decoration: const InputDecoration(
                hintText: '请输入你的名字',
                prefixIcon: Icon(Icons.person_rounded, color: OrbColors.textSecondary),
              ),
              textInputAction: TextInputAction.next,
              onChanged: controller.setUserName,
            ),
            const SizedBox(height: OrbSpacing.lg),
            TextField(
              controller: _orbNameController,
              style: OrbTypography.bodyLarge,
              decoration: const InputDecoration(
                hintText: '小光的名字（默认：小光）',
                prefixIcon: Icon(Icons.auto_awesome_rounded, color: OrbColors.textSecondary),
              ),
              onChanged: controller.setOrbName,
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _nameController.text.isNotEmpty
                    ? controller.goToNext
                    : null,
                child: const Text('继续'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectPage(
    OnboardingState state,
    OnboardingController controller,
  ) {
    return SafeArea(
      key: const ValueKey('connect'),
      child: Padding(
        padding: const EdgeInsets.all(OrbSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            // Bluetooth indicator
            AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: state.isConnecting
                    ? OrbColors.listenGlow
                    : OrbColors.bgCard,
                border: Border.all(
                  color: state.isConnecting
                      ? OrbColors.listen
                      : OrbColors.borderSubtle,
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.bluetooth_rounded,
                size: 48,
                color: state.isConnecting ? OrbColors.listen : OrbColors.textTertiary,
              ),
            ),
            const SizedBox(height: OrbSpacing.xxl),
            Text(
              '连接你的小光',
              style: OrbTypography.displayMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: OrbSpacing.md),
            Text(
              state.isConnecting
                  ? '正在搜索附近的小光…'
                  : '请将手机靠近小光设备\n确保设备已通电（蓝灯闪烁）',
              style: OrbTypography.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const Spacer(),
            if (!state.isConnecting)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: controller.simulateConnect,
                  child: const Text('开始搜索'),
                ),
              ),
            if (state.isConnecting)
              const CircularProgressIndicator(color: OrbColors.listen),
            const SizedBox(height: OrbSpacing.md),
            TextButton(
              onPressed: () => context.go('/'),
              child: Text(
                '稍后再连接',
                style: OrbTypography.bodyMedium.copyWith(
                  color: OrbColors.textTertiary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDonePage() {
    return SafeArea(
      key: const ValueKey('done'),
      child: Padding(
        padding: const EdgeInsets.all(OrbSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🎉', style: TextStyle(fontSize: 64)),
            const SizedBox(height: OrbSpacing.xxl),
            Text(
              '你好！',
              style: OrbTypography.displayLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: OrbSpacing.md),
            Text(
              '小光已经准备好了\n我们开始吧',
              style: OrbTypography.bodyLarge.copyWith(
                color: OrbColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: OrbSpacing.xxl),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => context.go('/'),
                child: const Text('开始使用'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
