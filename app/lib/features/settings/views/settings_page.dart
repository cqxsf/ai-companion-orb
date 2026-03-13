import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/orb_colors.dart';
import '../../../core/theme/orb_spacing.dart';
import '../../../core/theme/orb_typography.dart';
import '../controllers/settings_controller.dart';
import '../../shared/models/orb_emotion.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final controller = ref.read(settingsProvider.notifier);

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
                    Text('设置', style: OrbTypography.displayMedium),
                    const SizedBox(height: OrbSpacing.xs),
                    Text('个性化你的小光', style: OrbTypography.bodyMedium),
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
                  _buildSection(
                    '个人信息',
                    [
                      _buildEditTile(
                        context: context,
                        icon: Icons.person_rounded,
                        label: '你的名字',
                        value: settings.userName,
                        onSave: controller.setUserName,
                      ),
                    ],
                  ),
                  const SizedBox(height: OrbSpacing.lg),
                  _buildSection(
                    '小光设备',
                    [
                      _buildEditTile(
                        context: context,
                        icon: Icons.auto_awesome_rounded,
                        label: '小光的名字',
                        value: settings.orbName,
                        onSave: controller.setOrbName,
                      ),
                      const Divider(height: 1, color: OrbColors.borderSubtle),
                      _buildEmotionTile(
                        context: context,
                        label: '默认情绪',
                        value: settings.defaultEmotion,
                        onChanged: controller.setDefaultEmotion,
                      ),
                      const Divider(height: 1, color: OrbColors.borderSubtle),
                      _buildSliderTile(
                        icon: Icons.volume_up_rounded,
                        label: '音量',
                        value: settings.volume,
                        onChanged: controller.setVolume,
                      ),
                    ],
                  ),
                  const SizedBox(height: OrbSpacing.lg),
                  _buildSection(
                    '通知',
                    [
                      _buildSwitchTile(
                        icon: Icons.notifications_rounded,
                        label: '推送通知',
                        subtitle: '接收日常关怀提醒',
                        value: settings.notifications,
                        onChanged: controller.toggleNotifications,
                      ),
                      const Divider(height: 1, color: OrbColors.borderSubtle),
                      _buildSwitchTile(
                        icon: Icons.emergency_rounded,
                        label: '紧急通知',
                        subtitle: '检测到异常时立即通知家人',
                        value: settings.emergencyNotifications,
                        onChanged: controller.toggleEmergencyNotifications,
                        activeColor: OrbColors.excited,
                      ),
                    ],
                  ),
                  const SizedBox(height: OrbSpacing.lg),
                  _buildSection(
                    '交互',
                    [
                      _buildSwitchTile(
                        icon: Icons.music_note_rounded,
                        label: '声音效果',
                        subtitle: '互动时播放提示音',
                        value: settings.soundEnabled,
                        onChanged: controller.toggleSound,
                      ),
                      const Divider(height: 1, color: OrbColors.borderSubtle),
                      _buildSwitchTile(
                        icon: Icons.vibration_rounded,
                        label: '触感反馈',
                        subtitle: '操作时振动反馈',
                        value: settings.hapticEnabled,
                        onChanged: controller.toggleHaptic,
                      ),
                    ],
                  ),
                  const SizedBox(height: OrbSpacing.lg),
                  _buildSection(
                    '关于',
                    [
                      _buildInfoTile(
                        icon: Icons.info_rounded,
                        label: '版本',
                        value: '1.0.0',
                      ),
                      const Divider(height: 1, color: OrbColors.borderSubtle),
                      _buildInfoTile(
                        icon: Icons.favorite_rounded,
                        label: '制作团队',
                        value: '成前科技',
                      ),
                      const Divider(height: 1, color: OrbColors.borderSubtle),
                      _buildActionTile(
                        context: context,
                        icon: Icons.privacy_tip_rounded,
                        label: '隐私政策',
                        onTap: () {},
                      ),
                    ],
                  ),
                  const SizedBox(height: OrbSpacing.xxl),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: OrbSpacing.sm,
            bottom: OrbSpacing.sm,
          ),
          child: Text(
            title,
            style: OrbTypography.labelMedium.copyWith(
              color: OrbColors.textTertiary,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: OrbColors.bgCard,
            borderRadius: BorderRadius.circular(OrbSpacing.radiusLg),
            border: Border.all(color: OrbColors.borderSubtle),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String label,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    Color? activeColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: OrbSpacing.md,
        vertical: OrbSpacing.sm,
      ),
      child: Row(
        children: [
          Icon(icon, size: 22, color: OrbColors.textSecondary),
          const SizedBox(width: OrbSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: OrbTypography.titleMedium),
                Text(subtitle, style: OrbTypography.caption),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: activeColor ?? OrbColors.calm,
          ),
        ],
      ),
    );
  }

  Widget _buildSliderTile({
    required IconData icon,
    required String label,
    required double value,
    required ValueChanged<double> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: OrbSpacing.md,
        vertical: OrbSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 22, color: OrbColors.textSecondary),
              const SizedBox(width: OrbSpacing.md),
              Text(label, style: OrbTypography.titleMedium),
              const Spacer(),
              Text(
                '${(value * 100).round()}%',
                style: OrbTypography.labelMedium.copyWith(
                  color: OrbColors.textSecondary,
                ),
              ),
            ],
          ),
          Slider(
            value: value,
            onChanged: onChanged,
            min: 0,
            max: 1,
            divisions: 10,
          ),
        ],
      ),
    );
  }

  Widget _buildEditTile({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value,
    required ValueChanged<String> onSave,
  }) {
    return InkWell(
      onTap: () => _showEditDialog(context, label, value, onSave),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: OrbSpacing.md,
          vertical: OrbSpacing.md,
        ),
        child: Row(
          children: [
            Icon(icon, size: 22, color: OrbColors.textSecondary),
            const SizedBox(width: OrbSpacing.md),
            Text(label, style: OrbTypography.titleMedium),
            const Spacer(),
            Text(
              value,
              style: OrbTypography.bodyMedium.copyWith(
                color: OrbColors.textSecondary,
              ),
            ),
            const SizedBox(width: OrbSpacing.sm),
            const Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: OrbColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmotionTile({
    required BuildContext context,
    required String label,
    required OrbEmotion value,
    required ValueChanged<OrbEmotion> onChanged,
  }) {
    return InkWell(
      onTap: () => _showEmotionPicker(context, value, onChanged),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: OrbSpacing.md,
          vertical: OrbSpacing.md,
        ),
        child: Row(
          children: [
            const Icon(
              Icons.palette_rounded,
              size: 22,
              color: OrbColors.textSecondary,
            ),
            const SizedBox(width: OrbSpacing.md),
            Text(label, style: OrbTypography.titleMedium),
            const Spacer(),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(value.emoji, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: OrbSpacing.xs),
                Text(
                  value.label,
                  style: OrbTypography.bodyMedium.copyWith(
                    color: value.lightColor,
                  ),
                ),
              ],
            ),
            const SizedBox(width: OrbSpacing.sm),
            const Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: OrbColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: OrbSpacing.md,
        vertical: OrbSpacing.md,
      ),
      child: Row(
        children: [
          Icon(icon, size: 22, color: OrbColors.textSecondary),
          const SizedBox(width: OrbSpacing.md),
          Text(label, style: OrbTypography.titleMedium),
          const Spacer(),
          Text(
            value,
            style: OrbTypography.bodyMedium.copyWith(
              color: OrbColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: OrbSpacing.md,
          vertical: OrbSpacing.md,
        ),
        child: Row(
          children: [
            Icon(icon, size: 22, color: OrbColors.textSecondary),
            const SizedBox(width: OrbSpacing.md),
            Text(label, style: OrbTypography.titleMedium),
            const Spacer(),
            const Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: OrbColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showEditDialog(
    BuildContext context,
    String title,
    String currentValue,
    ValueChanged<String> onSave,
  ) async {
    final controller = TextEditingController(text: currentValue);
    return showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: OrbColors.bgCard,
        title: Text(title, style: OrbTypography.titleMedium),
        content: TextField(
          controller: controller,
          style: OrbTypography.bodyLarge,
          decoration: InputDecoration(
            hintText: '请输入$title',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              '取消',
              style: OrbTypography.labelMedium.copyWith(
                color: OrbColors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              onSave(controller.text);
              Navigator.pop(ctx);
            },
            child: Text(
              '保存',
              style: OrbTypography.labelMedium.copyWith(
                color: OrbColors.calm,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showEmotionPicker(
    BuildContext context,
    OrbEmotion current,
    ValueChanged<OrbEmotion> onChanged,
  ) async {
    return showModalBottomSheet(
      context: context,
      backgroundColor: OrbColors.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(OrbSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('选择默认情绪', style: OrbTypography.headlineSmall),
            const SizedBox(height: OrbSpacing.lg),
            Wrap(
              spacing: OrbSpacing.sm,
              runSpacing: OrbSpacing.sm,
              children: OrbEmotion.values.map((emotion) {
                final isSelected = emotion == current;
                return GestureDetector(
                  onTap: () {
                    onChanged(emotion);
                    Navigator.pop(ctx);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: OrbSpacing.md,
                      vertical: OrbSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? emotion.glowColor
                          : OrbColors.bgElevated,
                      borderRadius:
                          BorderRadius.circular(OrbSpacing.radiusFull),
                      border: Border.all(
                        color:
                            isSelected ? emotion.color : OrbColors.borderSubtle,
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
                            color: isSelected
                                ? emotion.lightColor
                                : OrbColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: OrbSpacing.lg),
          ],
        ),
      ),
    );
  }
}
