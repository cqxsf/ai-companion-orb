import 'orb_emotion.dart';

class Memory {
  final String id;
  final String title;
  final String content;
  final DateTime date;
  final OrbEmotion emotion;
  final List<String> tags;

  const Memory({
    required this.id,
    required this.title,
    required this.content,
    required this.date,
    required this.emotion,
    this.tags = const [],
  });

  Memory copyWith({
    String? id,
    String? title,
    String? content,
    DateTime? date,
    OrbEmotion? emotion,
    List<String>? tags,
  }) {
    return Memory(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      date: date ?? this.date,
      emotion: emotion ?? this.emotion,
      tags: tags ?? this.tags,
    );
  }

  String get excerpt {
    if (content.length <= 80) return content;
    return '${content.substring(0, 80)}…';
  }
}
