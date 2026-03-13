import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/models/memory.dart';
import '../../shared/models/orb_emotion.dart';

class MemoryState {
  final List<Memory> memories;
  final OrbEmotion? filterEmotion;
  final Memory? selectedMemory;

  const MemoryState({
    required this.memories,
    this.filterEmotion,
    this.selectedMemory,
  });

  MemoryState copyWith({
    List<Memory>? memories,
    OrbEmotion? filterEmotion,
    Memory? selectedMemory,
    bool clearFilter = false,
    bool clearSelected = false,
  }) {
    return MemoryState(
      memories: memories ?? this.memories,
      filterEmotion: clearFilter ? null : (filterEmotion ?? this.filterEmotion),
      selectedMemory: clearSelected ? null : (selectedMemory ?? this.selectedMemory),
    );
  }

  List<Memory> get filteredMemories {
    if (filterEmotion == null) return memories;
    return memories.where((m) => m.emotion == filterEmotion).toList();
  }

  factory MemoryState.initial() {
    return MemoryState(memories: _sampleMemories());
  }
}

List<Memory> _sampleMemories() {
  return [
    Memory(
      id: '1',
      title: '今天天气不错',
      content: '你说今天出门晒了太阳，感觉很舒服，腿也没那么疼了。走了大概半小时，在公园里遇见了邻居李阿姨，聊了很久。',
      date: DateTime.now().subtract(const Duration(hours: 2)),
      emotion: OrbEmotion.joy,
      tags: ['健康', '户外', '朋友'],
    ),
    Memory(
      id: '2',
      title: '和王阿姨通了电话',
      content: '和老朋友聊了半小时，聊到了以前的往事，聊起了年轻时候一起跳广场舞的日子，心情很好，笑了好几次。',
      date: DateTime.now().subtract(const Duration(days: 1)),
      emotion: OrbEmotion.care,
      tags: ['朋友', '社交', '回忆'],
    ),
    Memory(
      id: '3',
      title: '安静的下午茶时光',
      content: '下午泡了一杯龙井，坐在窗边看了一会儿书，很安静惬意。阳光刚好照在书页上，感觉特别平静。',
      date: DateTime.now().subtract(const Duration(days: 2)),
      emotion: OrbEmotion.calm,
      tags: ['生活', '放松', '阅读'],
    ),
    Memory(
      id: '4',
      title: '孙子来视频了',
      content: '小宝今天来视频，说在学校得了小红花，还唱了一首歌给我听。真的太可爱了，心里暖暖的。',
      date: DateTime.now().subtract(const Duration(days: 3)),
      emotion: OrbEmotion.joy,
      tags: ['家人', '孙子', '视频'],
    ),
    Memory(
      id: '5',
      title: '有点担心身体',
      content: '今天膝盖有点酸，有点担心是不是天气变化的缘故。小光建议我明天如果还疼的话，要告诉子女去看看医生。',
      date: DateTime.now().subtract(const Duration(days: 4)),
      emotion: OrbEmotion.concern,
      tags: ['健康', '提醒'],
    ),
    Memory(
      id: '6',
      title: '社区书法课',
      content: '参加了社区的书法班，写了一幅"福"字，老师说写得不错。认识了几个新朋友，大家都很友好。',
      date: DateTime.now().subtract(const Duration(days: 5)),
      emotion: OrbEmotion.excited,
      tags: ['社区', '书法', '新朋友'],
    ),
  ];
}

class MemoryController extends StateNotifier<MemoryState> {
  MemoryController() : super(MemoryState.initial());

  void setFilter(OrbEmotion? emotion) {
    if (state.filterEmotion == emotion) {
      state = state.copyWith(clearFilter: true);
    } else {
      state = state.copyWith(filterEmotion: emotion);
    }
  }

  void selectMemory(Memory memory) {
    state = state.copyWith(selectedMemory: memory);
  }

  void clearSelection() {
    state = state.copyWith(clearSelected: true);
  }

  Memory? getMemoryById(String id) {
    try {
      return state.memories.firstWhere((m) => m.id == id);
    } catch (_) {
      return null;
    }
  }
}

final memoryProvider = StateNotifierProvider<MemoryController, MemoryState>(
  (ref) => MemoryController(),
);
