import 'package:flutter/material.dart';
import '../../../core/theme/orb_colors.dart';
import '../../../core/theme/orb_typography.dart';
import '../../../core/theme/orb_spacing.dart';
import '../../shared/models/orb_emotion.dart';

class ChatInputBar extends StatefulWidget {
  final String initialText;
  final OrbEmotion currentEmotion;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSend;

  const ChatInputBar({
    super.key,
    required this.initialText,
    required this.currentEmotion,
    required this.onChanged,
    required this.onSend,
  });

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> {
  late TextEditingController _textController;
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.initialText);
  }

  @override
  void didUpdateWidget(ChatInputBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialText != oldWidget.initialText && widget.initialText.isEmpty) {
      _textController.clear();
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleSend() {
    final text = _textController.text.trim();
    if (text.isNotEmpty) {
      widget.onSend(text);
      _textController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasText = _textController.text.isNotEmpty;

    return Container(
      padding: EdgeInsets.only(
        left: OrbSpacing.md,
        right: OrbSpacing.md,
        top: OrbSpacing.sm,
        bottom: MediaQuery.of(context).viewInsets.bottom > 0
            ? OrbSpacing.sm
            : OrbSpacing.md,
      ),
      decoration: const BoxDecoration(
        color: OrbColors.bgCard,
        border: Border(
          top: BorderSide(color: OrbColors.borderSubtle),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              focusNode: _focusNode,
              style: OrbTypography.bodyMedium.copyWith(
                color: OrbColors.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: '说点什么吧…',
                hintStyle: OrbTypography.bodyMedium,
                filled: true,
                fillColor: OrbColors.bgElevated,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(OrbSpacing.radiusFull),
                  borderSide: const BorderSide(color: OrbColors.borderSubtle),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(OrbSpacing.radiusFull),
                  borderSide: const BorderSide(color: OrbColors.borderSubtle),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(OrbSpacing.radiusFull),
                  borderSide: BorderSide(color: widget.currentEmotion.color),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: OrbSpacing.md,
                  vertical: OrbSpacing.sm + 2,
                ),
              ),
              textInputAction: TextInputAction.send,
              onChanged: (text) {
                widget.onChanged(text);
                setState(() {});
              },
              onSubmitted: (_) => _handleSend(),
              maxLines: 4,
              minLines: 1,
            ),
          ),
          const SizedBox(width: OrbSpacing.sm),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: hasText
                  ? widget.currentEmotion.color
                  : OrbColors.bgElevated,
              shape: BoxShape.circle,
              border: Border.all(
                color: hasText
                    ? widget.currentEmotion.color
                    : OrbColors.borderSubtle,
              ),
            ),
            child: IconButton(
              onPressed: hasText ? _handleSend : null,
              icon: Icon(
                hasText ? Icons.send_rounded : Icons.mic_rounded,
                color: hasText ? Colors.white : OrbColors.textTertiary,
                size: 20,
              ),
              padding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }
}
