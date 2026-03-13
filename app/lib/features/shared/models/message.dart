import 'orb_emotion.dart';

class Message {
  final String id;
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final OrbEmotion? emotion;

  const Message({
    required this.id,
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.emotion,
  });

  Message copyWith({
    String? id,
    String? content,
    bool? isUser,
    DateTime? timestamp,
    OrbEmotion? emotion,
  }) {
    return Message(
      id: id ?? this.id,
      content: content ?? this.content,
      isUser: isUser ?? this.isUser,
      timestamp: timestamp ?? this.timestamp,
      emotion: emotion ?? this.emotion,
    );
  }
}
