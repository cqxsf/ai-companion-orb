import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/models/orb_emotion.dart';
import '../../shared/models/memory.dart';

class OrbHomeState {
  final OrbEmotion currentEmotion;
  final String greeting;
  final List<Memory> recentMemories;
  final bool isListening;

  const OrbHomeState({
    required this.currentEmotion,
    required this.greeting,
    required this.recentMemories,
    this.isListening = false,
  });

  OrbHomeState copyWith({
    OrbEmotion? currentEmotion,
    String? greeting,
    List<Memory>? recentMemories,
    bool? isListening,
  }) {
    return OrbHomeState(
      currentEmotion: currentEmotion ?? this.currentEmotion,
      greeting: greeting ?? this.greeting,
      recentMemories: recentMemories ?? this.recentMemories,
      isListening: isListening ?? this.isListening,
    );
  }

  factory OrbHomeState.initial() {
    return OrbHomeState(
      currentEmotion: OrbEmotion.calm,
      greeting: _greetingForTime(),
      recentMemories: _sampleMemories(),
      isListening: false,
    );
  }
}

String _greetingForTime() {
  final hour = DateTime.now().hour;
  if (hour >= 5 && hour < 12) {
    return '早上好，今天感觉怎么样？';
  } else if (hour >= 12 && hour < 18) {
    return '下午好，休息一下吧';
  } else if (hour >= 18 && hour < 22) {
    return '晚上好，今天过得如何？';
  } else {
    return '夜深了，注意休息哦';
  }
}

List<Memory> _sampleMemories() {
  return [
    Memory(
      id: '1',
      title: '今天天气不错',
      content: '你说今天出门晒了太阳，感觉很舒服，腿也没那么疼了',
      date: DateTime.now().subtract(const Duration(hours: 2)),
      emotion: OrbEmotion.joy,
      tags: ['健康', '户外'],
    ),
    Memory(
      id: '2',
      title: '和王阿姨通了电话',
      content: '和老朋友聊了半小时，聊到了以前的往事，心情很好',
      date: DateTime.now().subtract(const Duration(days: 1)),
      emotion: OrbEmotion.care,
      tags: ['朋友', '社交'],
    ),
    Memory(
      id: '3',
      title: '喝了一杯热茶',
      content: '下午泡了一杯龙井，坐在窗边看书，很安静惬意',
      date: DateTime.now().subtract(const Duration(days: 2)),
      emotion: OrbEmotion.calm,
      tags: ['生活', '放松'],
    ),
  ];
}

class OrbHomeController extends StateNotifier<OrbHomeState> {
  final Ref ref;

  OrbHomeController(this.ref) : super(OrbHomeState.initial());

  void changeEmotion(OrbEmotion emotion) {
    state = state.copyWith(
      currentEmotion: emotion,
      greeting: _greetingForEmotion(emotion),
    );
    ref.read(orbEmotionProvider.notifier).state = emotion;
  }

  void cycleEmotion() {
    changeEmotion(state.currentEmotion.next);
  }

  void startListening() {
    state = state.copyWith(isListening: true, currentEmotion: OrbEmotion.listen);
    ref.read(orbEmotionProvider.notifier).state = OrbEmotion.listen;
  }

  void stopListening() {
    state = state.copyWith(isListening: false, currentEmotion: OrbEmotion.calm);
    ref.read(orbEmotionProvider.notifier).state = OrbEmotion.calm;
  }

  void refreshGreeting() {
    state = state.copyWith(greeting: _greetingForTime());
  }
}

String _greetingForEmotion(OrbEmotion emotion) {
  switch (emotion) {
    case OrbEmotion.calm:
      return '静静陪着你，有什么想说的吗？';
    case OrbEmotion.joy:
      return '你看起来心情不错呢，发生什么好事了？';
    case OrbEmotion.care:
      return '我在这里，随时都可以聊聊';
    case OrbEmotion.listen:
      return '我在认真听，请说吧…';
    case OrbEmotion.concern:
      return '感觉你有点不开心，没事的，我陪着你';
    case OrbEmotion.excited:
      return '哇，好开心！快告诉我发生了什么！';
    case OrbEmotion.sleep:
      return '好好休息吧，我会守护你的梦';
  }
}

final orbEmotionProvider = StateProvider<OrbEmotion>((ref) => OrbEmotion.calm);

final orbHomeProvider = StateNotifierProvider<OrbHomeController, OrbHomeState>(
  (ref) => OrbHomeController(ref),
);
