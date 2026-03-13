import 'package:flutter/material.dart';
import '../../../core/theme/orb_colors.dart';
import '../../../core/theme/orb_typography.dart';
import '../../../core/theme/orb_spacing.dart';
import '../../shared/models/message.dart';

class ChatBubble extends StatelessWidget {
  final Message message;

  const ChatBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: OrbSpacing.md,
        vertical: OrbSpacing.xs,
      ),
      child: Row(
        mainAxisAlignment:
            message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!message.isUser) ...[
            _buildAiAvatar(),
            const SizedBox(width: OrbSpacing.sm),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: message.isUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.72,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: OrbSpacing.md,
                    vertical: OrbSpacing.sm + 2,
                  ),
                  decoration: BoxDecoration(
                    color: message.isUser
                        ? OrbColors.bgElevated
                        : (message.emotion?.glowColor ?? OrbColors.calmGlow),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(20),
                      topRight: const Radius.circular(20),
                      bottomLeft: Radius.circular(message.isUser ? 20 : 4),
                      bottomRight: Radius.circular(message.isUser ? 4 : 20),
                    ),
                    border: Border.all(
                      color: message.isUser
                          ? OrbColors.borderSubtle
                          : (message.emotion?.color.withAlpha(77) ??
                              OrbColors.borderSubtle),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!message.isUser && message.emotion != null) ...[
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              message.emotion!.emoji,
                              style: const TextStyle(fontSize: 12),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              message.emotion!.label,
                              style: OrbTypography.labelSmall.copyWith(
                                color: message.emotion!.lightColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: OrbSpacing.xs),
                      ],
                      Text(
                        message.content,
                        style: OrbTypography.bodyMedium.copyWith(
                          color: OrbColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatTime(message.timestamp),
                  style: OrbTypography.caption,
                ),
              ],
            ),
          ),
          if (message.isUser) ...[
            const SizedBox(width: OrbSpacing.sm),
            _buildUserAvatar(),
          ],
        ],
      ),
    );
  }

  Widget _buildAiAvatar() {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: message.emotion?.glowColor ?? OrbColors.calmGlow,
        shape: BoxShape.circle,
        border: Border.all(
          color: message.emotion?.color ?? OrbColors.calm,
          width: 1.5,
        ),
      ),
      child: Center(
        child: Text(
          message.emotion?.emoji ?? '✨',
          style: const TextStyle(fontSize: 14),
        ),
      ),
    );
  }

  Widget _buildUserAvatar() {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: OrbColors.bgOverlay,
        shape: BoxShape.circle,
        border: Border.all(color: OrbColors.borderSubtle),
      ),
      child: const Icon(
        Icons.person_rounded,
        size: 18,
        color: OrbColors.textSecondary,
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inMinutes < 1) return '刚刚';
    if (diff.inHours < 1) return '${diff.inMinutes}分钟前';
    if (diff.inDays < 1) return '${diff.inHours}小时前';
    return '${time.month}月${time.day}日';
  }
}
