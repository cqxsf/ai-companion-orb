import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/orb_colors.dart';
import '../../../core/theme/orb_spacing.dart';
import '../../../core/theme/orb_typography.dart';
import '../controllers/chat_controller.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/chat_input_bar.dart';
import '../widgets/emotion_transition.dart';
import '../../shared/models/orb_emotion.dart';

class ChatPage extends ConsumerStatefulWidget {
  const ChatPage({super.key});

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  final _scrollController = ScrollController();
  OrbEmotion _lastEmotion = OrbEmotion.calm;
  bool _showEmotionTransition = false;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);
    final controller = ref.read(chatProvider.notifier);
    final emotion = chatState.currentEmotion;

    ref.listen(chatProvider, (previous, next) {
      if (previous?.messages.length != next.messages.length) {
        _scrollToBottom();
      }
      if (previous?.currentEmotion != next.currentEmotion) {
        setState(() {
          _lastEmotion = next.currentEmotion;
          _showEmotionTransition = true;
        });
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() => _showEmotionTransition = false);
          }
        });
      }
    });

    return Scaffold(
      backgroundColor: OrbColors.bgBase,
      body: Stack(
        children: [
          Column(
            children: [
              _buildHeader(emotion),
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(vertical: OrbSpacing.md),
                  itemCount: chatState.messages.length +
                      (chatState.isTyping ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (chatState.isTyping && index == chatState.messages.length) {
                      return _buildTypingIndicator(emotion);
                    }
                    return ChatBubble(message: chatState.messages[index]);
                  },
                ),
              ),
              ChatInputBar(
                initialText: chatState.inputText,
                currentEmotion: emotion,
                onChanged: controller.updateInputText,
                onSend: controller.sendMessage,
              ),
            ],
          ),
          // Emotion transition overlay
          if (_showEmotionTransition)
            Positioned(
              top: 100,
              left: 0,
              right: 0,
              child: Center(
                child: EmotionTransition(emotion: _lastEmotion),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader(OrbEmotion emotion) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + OrbSpacing.sm,
        left: OrbSpacing.lg,
        right: OrbSpacing.lg,
        bottom: OrbSpacing.sm,
      ),
      decoration: const BoxDecoration(
        color: OrbColors.bgCard,
        border: Border(bottom: BorderSide(color: OrbColors.borderSubtle)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: emotion.glowColor,
              shape: BoxShape.circle,
              border: Border.all(color: emotion.color),
            ),
            child: Center(
              child: Text(
                emotion.emoji,
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ),
          const SizedBox(width: OrbSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('小光', style: OrbTypography.titleMedium),
              Text(
                emotion.label,
                style: OrbTypography.caption.copyWith(
                  color: emotion.lightColor,
                ),
              ),
            ],
          ),
          const Spacer(),
          IconButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: OrbColors.bgCard,
                  title: Text('清空对话', style: OrbTypography.titleMedium),
                  content: Text(
                    '确定要清空所有对话记录吗？',
                    style: OrbTypography.bodyMedium,
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text('取消',
                          style: const TextStyle(color: OrbColors.textSecondary)),
                    ),
                    TextButton(
                      onPressed: () {
                        ref.read(chatProvider.notifier).clearChat();
                        Navigator.pop(ctx);
                      },
                      child: Text('清空',
                          style: const TextStyle(color: OrbColors.excited)),
                    ),
                  ],
                ),
              );
            },
            icon: const Icon(Icons.more_horiz_rounded, color: OrbColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator(OrbEmotion emotion) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: OrbSpacing.md,
        vertical: OrbSpacing.xs,
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: emotion.glowColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(emotion.emoji, style: const TextStyle(fontSize: 14)),
            ),
          ),
          const SizedBox(width: OrbSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: OrbSpacing.md,
              vertical: OrbSpacing.sm + 2,
            ),
            decoration: BoxDecoration(
              color: emotion.glowColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
                bottomRight: Radius.circular(20),
                bottomLeft: Radius.circular(4),
              ),
            ),
            child: _TypingDots(color: emotion.lightColor),
          ),
        ],
      ),
    );
  }
}

class _TypingDots extends StatefulWidget {
  final Color color;

  const _TypingDots({required this.color});

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
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
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final offset = ((_controller.value - i * 0.15) % 1.0);
            final opacity = offset < 0.5
                ? offset * 2
                : (1.0 - offset) * 2;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: widget.color.withAlpha((opacity * 255).round()),
                shape: BoxShape.circle,
              ),
            );
          }),
        );
      },
    );
  }
}
