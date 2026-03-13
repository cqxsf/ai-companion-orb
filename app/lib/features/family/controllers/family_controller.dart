import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/models/orb_emotion.dart';

class FamilyMember {
  final String id;
  final String name;
  final String relation;
  final String avatar;
  final bool isOnline;

  const FamilyMember({
    required this.id,
    required this.name,
    required this.relation,
    required this.avatar,
    this.isOnline = false,
  });
}

class CareMessage {
  final String id;
  final String fromName;
  final String content;
  final DateTime timestamp;
  final OrbEmotion emotion;

  const CareMessage({
    required this.id,
    required this.fromName,
    required this.content,
    required this.timestamp,
    required this.emotion,
  });
}

class FamilyState {
  final List<FamilyMember> members;
  final List<CareMessage> careMessages;
  final bool isSending;

  const FamilyState({
    required this.members,
    required this.careMessages,
    this.isSending = false,
  });

  FamilyState copyWith({
    List<FamilyMember>? members,
    List<CareMessage>? careMessages,
    bool? isSending,
  }) {
    return FamilyState(
      members: members ?? this.members,
      careMessages: careMessages ?? this.careMessages,
      isSending: isSending ?? this.isSending,
    );
  }

  factory FamilyState.initial() {
    return FamilyState(
      members: [
        const FamilyMember(
          id: '1',
          name: '小明',
          relation: '儿子',
          avatar: '👨',
          isOnline: true,
        ),
        const FamilyMember(
          id: '2',
          name: '小红',
          relation: '女儿',
          avatar: '👩',
          isOnline: false,
        ),
        const FamilyMember(
          id: '3',
          name: '小宝',
          relation: '孙子',
          avatar: '👦',
          isOnline: true,
        ),
      ],
      careMessages: [
        CareMessage(
          id: '1',
          fromName: '小明',
          content: '妈，今天天气不错，出去走走吧！',
          timestamp: DateTime.now().subtract(const Duration(hours: 1)),
          emotion: OrbEmotion.care,
        ),
        CareMessage(
          id: '2',
          fromName: '小宝',
          content: '奶奶，我今天学了一首新歌，下次视频唱给你听！',
          timestamp: DateTime.now().subtract(const Duration(hours: 3)),
          emotion: OrbEmotion.joy,
        ),
        CareMessage(
          id: '3',
          fromName: '小红',
          content: '妈，记得按时吃药，爱你',
          timestamp: DateTime.now().subtract(const Duration(days: 1)),
          emotion: OrbEmotion.care,
        ),
      ],
    );
  }
}

class FamilyController extends StateNotifier<FamilyState> {
  FamilyController() : super(FamilyState.initial());

  void sendCareMessage(String memberId, String content) {
    final member = state.members.firstWhere((m) => m.id == memberId);
    final message = CareMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      fromName: member.name,
      content: content,
      timestamp: DateTime.now(),
      emotion: OrbEmotion.care,
    );
    state = state.copyWith(
      careMessages: [message, ...state.careMessages],
    );
  }
}

final familyProvider = StateNotifierProvider<FamilyController, FamilyState>(
  (ref) => FamilyController(),
);
