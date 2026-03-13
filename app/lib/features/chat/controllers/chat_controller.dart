import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/models/message.dart';
import '../../shared/models/orb_emotion.dart';
import '../../orb_home/controllers/orb_home_controller.dart';

class ChatState {
  final List<Message> messages;
  final bool isTyping;
  final String inputText;
  final OrbEmotion currentEmotion;

  const ChatState({
    required this.messages,
    this.isTyping = false,
    this.inputText = '',
    this.currentEmotion = OrbEmotion.calm,
  });

  ChatState copyWith({
    List<Message>? messages,
    bool? isTyping,
    String? inputText,
    OrbEmotion? currentEmotion,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isTyping: isTyping ?? this.isTyping,
      inputText: inputText ?? this.inputText,
      currentEmotion: currentEmotion ?? this.currentEmotion,
    );
  }

  factory ChatState.initial() {
    return ChatState(
      messages: [
        Message(
          id: 'welcome',
          content: '你好！我是小光，很高兴陪伴你 😊\n今天想聊点什么呢？',
          isUser: false,
          timestamp: DateTime.now().subtract(const Duration(minutes: 1)),
          emotion: OrbEmotion.joy,
        ),
      ],
      currentEmotion: OrbEmotion.calm,
    );
  }
}

const _aiResponses = [
  ('好的，我明白了。你说得很有道理呢！', OrbEmotion.calm),
  ('哇，听起来今天发生了不少事情呀 😊', OrbEmotion.joy),
  ('我听到了，你说的让我很感动 💗', OrbEmotion.care),
  ('嗯嗯，我在认真听，请继续说吧…', OrbEmotion.listen),
  ('听到这些，我有点担心你，还好吗？', OrbEmotion.concern),
  ('太棒了！真为你高兴！🎉', OrbEmotion.excited),
  ('是呀，这样想很平静，保持这种感觉挺好的', OrbEmotion.calm),
  ('我记住了，以后也会放在心上的', OrbEmotion.care),
];

class ChatController extends StateNotifier<ChatState> {
  final Ref ref;

  ChatController(this.ref) : super(ChatState.initial());

  void updateInputText(String text) {
    state = state.copyWith(inputText: text);
  }

  void sendMessage(String text) {
    if (text.trim().isEmpty) return;

    final userMessage = Message(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      content: text.trim(),
      isUser: true,
      timestamp: DateTime.now(),
    );

    state = state.copyWith(
      messages: [...state.messages, userMessage],
      isTyping: true,
      inputText: '',
      currentEmotion: OrbEmotion.listen,
    );

    Timer(const Duration(milliseconds: 1500), () {
      _sendAiReply();
    });
  }

  void _sendAiReply() {
    final responseIndex =
        DateTime.now().millisecondsSinceEpoch % _aiResponses.length;
    final (content, emotion) = _aiResponses[responseIndex];

    final aiMessage = Message(
      id: 'ai_${DateTime.now().millisecondsSinceEpoch}',
      content: content,
      isUser: false,
      timestamp: DateTime.now(),
      emotion: emotion,
    );

    state = state.copyWith(
      messages: [...state.messages, aiMessage],
      isTyping: false,
      currentEmotion: emotion,
    );

    ref.read(chatEmotionProvider.notifier).state = emotion;
    ref.read(orbEmotionProvider.notifier).state = emotion;
  }

  void clearChat() {
    state = ChatState.initial();
  }
}

final chatEmotionProvider = StateProvider<OrbEmotion>((ref) => OrbEmotion.calm);

final chatProvider = StateNotifierProvider<ChatController, ChatState>(
  (ref) => ChatController(ref),
);
