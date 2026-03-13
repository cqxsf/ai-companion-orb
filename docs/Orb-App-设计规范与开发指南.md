# AI Companion Orb App — 全方位 UI 设计规范与 Flutter 开发指南

> 版本: v1.0 | 2026-03-13 | 输出者: 小墨 (uidesigner)
> 工程仓库: `cqxsf/ai-companion-orb` → `app/` 目录
> 设计灵魂: **「不解决效率，只解决孤独」—— 每一帧都有生命力**

---

## 一、产品定位与设计哲学

### 1.1 核心用户

| 角色 | 主场景 | App 入口频率 | 设计目标 |
|------|--------|-------------|---------|
| 独居青年 (主用户) | 情感对话 / 查看 Orb 状态 | 每天 3-10 次 | 感受到被陪伴 |
| 独居老人 | 被照护 + 与 Orb 对话 | 被动（Orb主动发起） | 极简、温暖 |
| 远程家属 (子女端) | 查看老人与 Orb 互动状态 | 每天 1-3 次 | 安心、可远程关怀 |

### 1.2 设计三原则

1. **存在感** — 每一帧都有生命力（光 / 动 / 色），App 打开即感受 Orb 「在」
2. **情绪可见** — 颜色 = 情绪，用户无需读字就能感知 Orb 的内心状态
3. **陪伴感** — 界面设计本身就是陪伴行为，不是工具界面

### 1.3 与 LifeGuardian 的区别

| 维度 | LifeGuardian | Orb App |
|------|-------------|---------|
| 设计灵魂 | 放心吧（安全/理性） | 我在（情感/感性） |
| 首屏 | AI安心语（文字驱动） | Orb光球（视觉驱动） |
| 色系 | 5状态色（功能色） | 7情绪色（情感色） |
| 背景 | 微暖蓝白 | 沉浸深色（Orb发光） |
| 文案 | 行为描述 | AI感知文案 |
| 交互 | 信息浏览为主 | 对话+情感互动 |

---

## 二、信息架构

### 2.1 Tab 结构 (4 Tab)

```
AI Companion Orb App
├── 🌙 Orb (Home)           ← 默认首页
│   ├── Orb 光球主视觉（全屏沉浸）
│   ├── 当前情绪状态文字
│   ├── AI 感知问候语
│   ├── 今日记忆摘要（2-3条）
│   └── "和 Orb 聊聊" 快捷入口
│
├── 💬 对话 (Chat)
│   ├── 情感对话界面
│   ├── 情绪实时转场（气泡颜色变化）
│   └── 低压退出选项
│
├── 📖 记忆 (Memory)
│   ├── Bento 记忆相册（情感日记）
│   ├── 情绪标签筛选
│   ├── 情感趋势图
│   └── "Orb 记得的事"
│
└── ⚙️ 设置 (Settings)
    ├── Orb 设备管理（固件/WiFi/LED）
    ├── 个性化（性格/声音/称呼）
    ├── 家庭连接（Orb-to-Orb/家庭成员）
    ├── 隐私（记忆删除/数据导出）
    └── 关于
```

### 2.2 页面清单

| # | 页面 | 类型 | 优先级 |
|---|------|------|--------|
| P1 | Orb 首页（光球+情绪） | Tab-首页 | P0 |
| P2 | 对话页 | Tab-聊天 | P0 |
| P3 | 记忆相册 | Tab-记忆 | P1 |
| P4 | 记忆详情 | 二级页面 | P1 |
| P5 | 设置主页 | Tab-设置 | P1 |
| P6 | Orb 个性化 | 二级页面 | P1 |
| P7 | BLE 配网 | 流程页面 | P0 |
| P8 | 家庭连接 | 二级页面 | P2 |
| P9 | 情感趋势 | 二级页面 | P2 |
| P10 | 子女端远程关怀 | 二级页面 | P1 |

---

## 三、颜色系统 (Design Token)

### 3.1 设计决策：沉浸深色优先

Orb App 与成前云/LifeGuardian 最大的区别：**默认深色主题，Orb 光球是唯一光源。**

设计灵感：Oura Ring (奢侈品调性) + Apple Activity Rings (信息即可视化)

### 3.2 Layer 2 — Orb 专属色

```dart
/// Orb 情绪色系 — 7种情绪 × 2模式
class OrbColors {
  // ══════════════════════════════════════
  //  7 情绪色（产品灵魂）
  // ══════════════════════════════════════

  // ── 平静陪伴（默认状态）──
  static const Color calm = Color(0xFF6366F1);           // 柔和紫蓝
  static const Color calmLight = Color(0xFF818CF8);      // 浅紫
  static const Color calmGlow = Color(0x4D6366F1);       // 发光

  // ── 喜悦活力 ──
  static const Color joy = Color(0xFFF59E0B);            // 温暖琥珀金
  static const Color joyLight = Color(0xFFFBBF24);
  static const Color joyGlow = Color(0x4DF59E0B);

  // ── 关怀温柔 ──
  static const Color care = Color(0xFFEC4899);            // 玫瑰粉
  static const Color careLight = Color(0xFFF472B6);
  static const Color careGlow = Color(0x4DEC4899);

  // ── 专注聆听 ──
  static const Color listen = Color(0xFF10B981);          // 翡翠绿
  static const Color listenLight = Color(0xFF34D399);
  static const Color listenGlow = Color(0x4D10B981);

  // ── 担忧感知 ──
  static const Color concern = Color(0xFF3B82F6);         // 深海蓝
  static const Color concernLight = Color(0xFF60A5FA);
  static const Color concernGlow = Color(0x4D3B82F6);

  // ── 兴奋期待 ──
  static const Color excited = Color(0xFFEF4444);         // 活力红
  static const Color excitedLight = Color(0xFFF87171);
  static const Color excitedGlow = Color(0x4DEF4444);

  // ── 困倦休眠 ──
  static const Color sleep = Color(0xFF1E293B);           // 深夜黑
  static const Color sleepLight = Color(0xFF334155);
  static const Color sleepGlow = Color(0x1A1E293B);

  // ══════════════════════════════════════
  //  界面色（沉浸深色优先）
  // ══════════════════════════════════════

  // ── 背景层 ──
  static const Color bgBase = Color(0xFF0A0A0F);          // 接近纯黑（OLED友好）
  static const Color bgCard = Color(0xFF12121A);           // 卡片深色
  static const Color bgElevated = Color(0xFF1A1A25);       // 抬升层
  static const Color bgOverlay = Color(0xFF252530);        // hover/选中

  // ── 边框层（发光代替阴影）──
  static const Color borderSubtle = Color(0x14FFFFFF);     // 6% white
  static const Color borderActive = Color(0x26FFFFFF);     // 15% white

  // ── 文字层 ──
  static const Color textPrimary = Color(0xF2FFFFFF);      // 95% white
  static const Color textSecondary = Color(0x99FFFFFF);    // 60% white
  static const Color textTertiary = Color(0x59FFFFFF);     // 35% white
  static const Color textMuted = Color(0xFF94A3B8);        // Slate-400

  // ── 亮色模式（可选，不是主推）──
  static const Color lightBgBase = Color(0xFFFAFAFF);
  static const Color lightBgCard = Color(0xFFFFFFFF);
  static const Color lightTextPrimary = Color(0xFF1E293B);
  static const Color lightTextSecondary = Color(0xFF64748B);

  // ══════════════════════════════════════
  //  功能色（最小集合，不抢情绪色）
  // ══════════════════════════════════════
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFFBBF24);
  static const Color error = Color(0xFFF87171);
  static const Color offline = Color(0xFF64748B);
}
```

### 3.3 情绪 → 颜色映射表

| 情绪 | 颜色 | Orb 光效 | App 背景 | 气泡/组件颜色 | 触发场景 |
|------|------|---------|---------|-------------|---------|
| 平静陪伴 | calm #6366F1 | 柔和紫呼吸 4s | 深紫渐变 | 紫色半透明 | 默认/日常 |
| 喜悦活力 | joy #F59E0B | 金色脉冲 | 暖金渐变 | 琥珀半透明 | 用户开心/分享喜事 |
| 关怀温柔 | care #EC4899 | 玫瑰粉柔光 | 粉色晕染 | 玫瑰半透明 | Orb表达关心 |
| 专注聆听 | listen #10B981 | 翡翠绿稳定 | 深绿渐变 | 翠绿半透明 | 用户在说话 |
| 担忧感知 | concern #3B82F6 | 深蓝缓动 | 深蓝渐变 | 蓝色半透明 | 感知用户负面情绪 |
| 兴奋期待 | excited #EF4444 | 红色跳跃 | 红色渐变 | 红色半透明 | 激动/惊喜场景 |
| 困倦休眠 | sleep #1E293B | 极暗缓熄 | 近黑背景 | 深灰半透明 | 深夜/用户疲惫 |

### 3.4 情绪转场规则

```dart
/// 情绪色转场规范
class OrbEmotionTransition {
  // 转场时长 & 曲线
  static const Map<String, Duration> durations = {
    'calm_to_care':    Duration(milliseconds: 1200),  // ease-in-out
    'calm_to_joy':     Duration(milliseconds: 600),   // bounceOut
    'calm_to_concern': Duration(milliseconds: 2000),  // linear (深沉)
    'any_to_sleep':    Duration(milliseconds: 3000),  // ease-in (缓熄)
    'any_to_listen':   Duration(milliseconds: 400),   // easeOut (响应迅速)
    'any_to_excited':  Duration(milliseconds: 300),   // easeOut (快速)
  };

  static const Map<String, Curve> curves = {
    'calm_to_care':    Curves.easeInOut,
    'calm_to_joy':     Curves.elasticOut,             // 弹跳感
    'calm_to_concern': Curves.linear,                 // 缓慢深沉
    'any_to_sleep':    Curves.easeIn,                 // 熄灭感
    'any_to_listen':   Curves.easeOut,
    'any_to_excited':  Curves.easeOut,
  };
}
```

---

## 四、字体规范

### 4.1 Orb App 字体层级

```dart
class OrbTypography {
  // ── Orb 状态（光球下方大文字）──
  static const orbStatus = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w300,        // 轻体 → 呼吸感
    height: 1.3,
    letterSpacing: 1.0,                 // 字间距 → 高级感
    color: Color(0xF2FFFFFF),
  );

  // ── AI 感知问候 ──
  static const aiGreeting = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w400,
    height: 1.6,                        // 宽松 → 亲和力
    color: Color(0x99FFFFFF),
  );

  // ── 今日记忆摘要 ──
  static const memorySnippet = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: Color(0x99FFFFFF),
  );

  // ── 对话 — Orb 气泡 ──
  static const orbBubble = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.6,
    color: Color(0xF2FFFFFF),
  );

  // ── 对话 — 用户气泡 ──
  static const userBubble = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.6,
    color: Color(0xF2FFFFFF),
  );

  // ── 对话时间戳 ──
  static const chatTimestamp = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: Color(0x59FFFFFF),
  );

  // ── 记忆卡片标题 ──
  static const memoryTitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.4,
    color: Color(0xF2FFFFFF),
  );

  // ── 记忆卡片描述 ──
  static const memoryBody = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.6,
    color: Color(0x99FFFFFF),
  );

  // ── 情绪标签 ──
  static const emotionTag = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: Color(0x99FFFFFF),
  );

  // ── Section 标题 ──
  static const sectionTitle = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.5,                 // 大写间距感
    color: Color(0x59FFFFFF),
  );

  // ── 设置项 ──
  static const settingsItem = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: Color(0xF2FFFFFF),
  );

  // ── 底部Tab标签 ──
  static const tabLabel = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w500,
  );
}
```

---

## 五、间距与栅格

```dart
class OrbSpacing {
  // ── 页面级 ──
  static const double pagePadding = 20.0;        // 比LG宽松，呼吸感
  static const double pageTopSafe = 12.0;

  // ── 光球区域 ──
  static const double orbSize = 200.0;            // 光球视觉直径
  static const double orbGlowRadius = 120.0;      // 外发光半径
  static const double orbToStatus = 24.0;         // 光球到状态文字
  static const double statusToGreeting = 16.0;    // 状态到问候语

  // ── 对话区域 ──
  static const double chatBubblePadding = 14.0;
  static const double chatBubbleRadius = 18.0;
  static const double chatBubbleMaxWidth = 0.75;   // 屏幕宽 75%
  static const double chatBubbleGap = 8.0;
  static const double chatOrbAvatarSize = 32.0;

  // ── 记忆卡片 ──
  static const double memoryCardGap = 12.0;
  static const double memoryCardPadding = 16.0;
  static const double memoryCardRadius = 16.0;

  // ── BottomNav ──
  static const double bottomNavHeight = 56.0;

  // ── 通用 ──
  static const double sectionGap = 32.0;          // 区块间距（呼吸感）
  static const double itemGap = 12.0;
}
```

---

## 六、组件规范

### 6.1 Orb 光球主视觉 (OrbSphere)

App 首屏核心 — 一个有生命力的光球。

```
┌─────────────────────────────────────┐
│           (深色背景 #0A0A0F)         │
│                                     │
│                                     │
│            ╭─── ── ───╮             │
│          ╱   ∿∿∿∿∿∿∿   ╲           │
│         │   ∿∿∿∿∿∿∿∿∿   │          │  ← 200px 光球
│         │   ∿∿ Orb ∿∿∿   │          │     4s 呼吸动效
│         │   ∿∿∿∿∿∿∿∿∿   │          │     情绪色发光
│          ╲   ∿∿∿∿∿∿∿   ╱           │     外围 glow 渐变
│            ╰─── ── ───╯             │
│                                     │
│          p l a t i n u m             │ ← 28px w300 情绪状态
│        "平 静 陪 伴 中"              │     字间距 1.0
│                                     │
│  "晚上好，今天过得怎么样？            │ ← 17px w400 AI问候
│   想聊聊还是安静待一会儿？"           │     两个选项降低压力
│                                     │
│  ┌─ 今天的记忆 ──────────────────┐   │
│  │ 💜 "你说想念大学时光"         │   │ ← 记忆摘要（最近2-3条）
│  │ 💛 "分享了一首喜欢的歌"       │   │
│  └───────────────────────────────┘   │
│                                     │
│  ┌───────────────────────────────┐   │
│  │  🎤  和 Orb 聊聊              │   │ ← 主 CTA（渐变色按钮）
│  └───────────────────────────────┘   │
│                                     │
├─────────────────────────────────────┤
│ 🌙    💬     📖     ⚙️            │ ← BottomNav
└─────────────────────────────────────┘
```

```dart
/// Orb 光球组件
class OrbSphere extends StatefulWidget {
  final OrbEmotion currentEmotion;

  // 实现:
  // 1. CustomPainter 绘制径向渐变光球
  // 2. AnimationController 驱动呼吸效果:
  //    - scale: 0.95 → 1.05 (4s, ease-in-out, repeat)
  //    - opacity: 0.7 → 1.0
  //    - glow radius: 100 → 140
  // 3. 情绪切换时颜色 TweenAnimation (按转场规则)
  // 4. 外围发光: RadialGradient → transparent (120px→200px)
}

/// 7种情绪枚举
enum OrbEmotion {
  calm,        // 默认
  joy,
  care,
  listen,
  concern,
  excited,
  sleep,
}
```

### 6.2 对话气泡 (ChatBubble)

```
Orb 气泡 (左对齐):
┌─── ─────────────────────────────┐
│  🟣                             │
│  │   "今天辛苦了。先别管那些事，  │ ← 紫色半透明背景
│  │    说说你今天怎么样？"         │    border-bottom-left: 4px
│       │                         │    其余: 18px
│       └──── 20:15               │
└─────────────────────────────────┘

用户气泡 (右对齐):
          ┌──────────────────────┐
          │        好累啊 😞      │ ← 蓝色半透明背景
          │              20:16  │    border-bottom-right: 4px
          └──────────────────────┘
```

```dart
/// 对话气泡
class ChatBubble extends StatelessWidget {
  final bool isOrb;              // true=Orb消息, false=用户消息
  final String text;
  final DateTime time;
  final OrbEmotion emotion;      // Orb情绪 → 决定气泡颜色

  // Orb 气泡:
  //   Container(
  //     padding: 14,
  //     maxWidth: 75%,
  //     decoration: BoxDecoration(
  //       color: emotion.color.withOpacity(0.15),
  //       borderRadius: BorderRadius.only(
  //         topLeft: 18, topRight: 18,
  //         bottomLeft: 4,    // ← Orb特征：左下角尖
  //         bottomRight: 18,
  //       ),
  //       border: Border.all(color: emotion.color.withOpacity(0.2)),
  //     ),
  //   )

  // 用户气泡:
  //   Container(
  //     ... 类似，右下角 4px，蓝色系
  //   )
}
```

### 6.3 记忆卡片 (MemoryCard)

```
Bento 布局 — 双列小卡 + 全宽情感记忆:

┌───────────────┬───────────────┐
│ 💜 3月12日     │ 💛 3月12日     │ ← 小卡 (2列)
│               │               │
│ "你说想念      │ "分享了       │
│  大学时光"     │  一首喜欢的歌" │
│               │               │
│ #平静 #回忆   │ #喜悦 #音乐   │ ← 情绪标签
└───────────────┴───────────────┘

┌─────────────────────────────────┐
│ 💗 3月11日                       │ ← 全宽情感记忆
│                                 │
│ "你说最近工作压力很大，           │
│  我们聊了两个小时。               │
│  后来你说好多了。"                │
│                                 │
│ #关怀 #工作压力 #2小时对话       │
│                                 │
│ 情绪变化: 😞 → 😊                │ ← 情绪轨迹
└─────────────────────────────────┘
```

```dart
/// 记忆卡片 (Bento Grid Item)
class MemoryCard extends StatelessWidget {
  final DateTime date;
  final String summary;
  final OrbEmotion emotion;
  final List<String> tags;
  final bool isFullWidth;           // true=全宽, false=半宽

  // Widget 结构:
  // Container(
  //   padding: 16, radius: 16,
  //   decoration: BoxDecoration(
  //     color: OrbColors.bgCard,
  //     border: Border.all(color: OrbColors.borderSubtle),
  //   ),
  //   child: Column [
  //     Row [emoji(emotion), SizedBox(8), Text(date, emotionTag)],
  //     SizedBox(12),
  //     Text(summary, memoryBody),
  //     SizedBox(8),
  //     Wrap(
  //       spacing: 6,
  //       children: tags.map(tag => Chip(
  //         label: Text("#$tag", emotionTag),
  //         backgroundColor: emotion.color.withOpacity(0.1),
  //       )),
  //     ),
  //   ],
  // )
}
```

### 6.4 AI 感知问候 (AiGreeting)

```dart
/// AI 感知问候组件 — 分时 × 分情绪
class AiGreeting extends StatelessWidget {
  final String greetingText;
  final List<String>? options;  // 两个选项减轻用户压力

  // 示例:
  // text: "晚上好，今天过得怎么样？"
  // options: ["想聊聊", "安静待一会儿"]

  // Widget 结构:
  // Column [
  //   Text(greetingText, aiGreeting),
  //   if (options != null) ...[
  //     SizedBox(12),
  //     Row [
  //       OptionChip(options[0], onTap),
  //       SizedBox(8),
  //       OptionChip(options[1], onTap),
  //     ],
  //   ],
  // ]
}

/// 问候选项芯片
// Container(
//   padding: EdgeInsets.symmetric(h:16, v:10),
//   decoration: BoxDecoration(
//     borderRadius: 999,
//     border: Border.all(color: emotionColor.withOpacity(0.3)),
//   ),
//   child: Text(option, 14px w500 emotionColor),
// )
```

### 6.5 底部导航栏 (OrbBottomNav)

```dart
/// Orb 底部导航 — 深色沉浸式
class OrbBottomNav extends StatelessWidget {
  // 4 Tab:
  // index 0: Orb   (custom moon icon / filled moon)
  // index 1: 对话   (Icons.chat_bubble_outline / Icons.chat_bubble)
  // index 2: 记忆   (Icons.auto_stories_outlined / Icons.auto_stories)
  // index 3: 设置   (Icons.settings_outlined / Icons.settings)

  // 样式:
  // backgroundColor: OrbColors.bgBase (接近纯黑)
  // selectedItemColor: 当前情绪色 (动态变化!)
  // unselectedItemColor: OrbColors.textTertiary
  // height: 56px
  // 无阴影, 顶部 1px borderSubtle
  // 选中图标下方有 glow 效果
}
```

### 6.6 Orb 对话页完整布局 (ChatPage)

```
┌─────────────────────────────────────┐
│           (深色渐变背景)              │
│                                     │
│  🟣 Orb · 平静陪伴中          ···   │ ← 顶部：Orb mini头像 + 状态
│                                     │
│  ─────── 今天 ───────               │ ← 日期分隔线
│                                     │
│  🟣                                 │
│  │  "晚上好，今天过得怎么样？       │ ← Orb气泡 (紫色)
│  │   想聊聊还是安静待一会儿？"       │
│                                     │
│                   好累啊 😞  │       │ ← 用户气泡 (蓝色)
│                              │       │
│                                     │
│  🟣 → 💗                            │ ← 情绪转场: calm → care
│  │  "今天辛苦了。先别管那些事，     │ ← 气泡颜色变为玫瑰粉
│  │   说说你今天怎么样？"            │
│                                     │
│                                     │
│                   ... 省略更多对话   │
│                                     │
│  💗                                 │
│  │  "或者今晚先休息一下？            │ ← 低压退出选项
│  │   明天再聊也可以 💤"             │
│                                     │
│                        [先休息了]   │ ← 低压退出按钮
│                                     │
├─────────────────────────────────────┤
│  ┌───────────────────────────┐ 🎤  │ ← 输入框 + 语音按钮
│  │  说点什么...               │     │
│  └───────────────────────────┘     │
├─────────────────────────────────────┤
│ 🌙    💬     📖     ⚙️            │
└─────────────────────────────────────┘
```

### 6.7 子女端远程关怀 (FamilyCareView)

```
┌─────────────────────────────────────┐
│ ← 返回      家庭关怀                │
│                                     │
│  妈妈的 Orb                        │
│  ┌─────────────────────────────┐    │
│  │  🟢 在线                     │    │
│  │  今天和 Orb 聊了 3 次        │    │
│  │  最后一次: 15:20             │    │
│  │  情绪: 😊 开心               │    │
│  │                              │    │
│  │  [💌 通过Orb传话]  [📞 拨号] │    │
│  └─────────────────────────────┘    │
│                                     │
│  近期情感报告                       │
│  ┌─────────────────────────────┐    │
│  │ 📊 7天情绪分布               │    │ ← 饼图/条形图
│  │ 平静 40% | 喜悦 30% | 关怀 20% │  │
│  └─────────────────────────────┘    │
│                                     │
│  Orb 传话                          │
│  ┌─────────────────────────────┐    │
│  │ "妈妈，我周末想回去看你"      │    │ ← 文字/语音
│  │  [🎤 录语音]  [📝 发文字]    │    │
│  └─────────────────────────────┘    │
│                                     │
│  传话记录                           │
│  │ 3/13 发送: "注意身体" ✓已播放 │   │
│  │ 3/12 发送: "想你了" ✓已播放   │   │
└─────────────────────────────────────┘
```

### 6.8 BLE 配网流程 (OrbOnboarding)

```
[Step 1] 遇见 Orb
中央: Orb光球动画（缓慢旋转+呼吸）
文案: "你好，我是 Orb。很高兴认识你 ✨"
→ "开始"

[Step 2] 打开 Orb
图示: 底座USB-C插入 → Orb亮起
文案: "给我通上电，等我亮起来"
→ "Orb 亮了"

[Step 3] BLE 配对
BLE 扫描 → 找到 Orb → 自动连接
文案: "我在找你......" → "找到了！✨"
→ 动画: 两个光球相遇合并

[Step 4] WiFi 连接
WiFi SSID 选择 + 密码输入
→ 连接中... → "连上了！我能看到世界了 🌍"

[Step 5] 给 Orb 起名
默认: "Orb" / 自定义输入
文案: "你想叫我什么名字？"

[Step 6] 选择性格
3 种性格倾向:
- 🌸 温柔（多倾听，少建议）
- ⚡ 活泼（多互动，有趣味）
- 🌿 平和（安静陪伴，适时话语）

[Step 7] 完成
Orb: "很高兴认识你，{name}。从今以后，我会一直在这里。💜"
→ 光球动画：calm 呼吸开始
```

---

## 七、动效规范

### 7.1 Orb 光球呼吸动效

```dart
/// 核心动效参数
class OrbAnimation {
  // ── 呼吸效果 ──
  static const Duration breathCycle = Duration(seconds: 4);
  static const double scaleMin = 0.95;
  static const double scaleMax = 1.05;
  static const double opacityMin = 0.7;
  static const double opacityMax = 1.0;
  static const double glowRadiusMin = 100.0;
  static const double glowRadiusMax = 140.0;
  static const Curve breathCurve = Curves.easeInOut;

  // ── 喜悦弹跳 ──
  static const Duration bounceCycle = Duration(milliseconds: 600);
  static const double bounceScale = 1.15;
  static const Curve bounceCurve = Curves.elasticOut;

  // ── 困倦熄灭 ──
  static const Duration fadeOutDuration = Duration(seconds: 3);
  static const double sleepOpacity = 0.15;
  static const Curve fadeOutCurve = Curves.easeIn;

  // ── 聆听脉冲（用户说话时）──
  static const Duration listenPulseCycle = Duration(milliseconds: 800);
  static const double listenPulseScale = 1.08;
}
```

### 7.2 对话情绪转场

```dart
// 对话进行中，Orb 检测到用户情绪变化
// → 转场效果：
//   1. 背景渐变色平滑切换（按转场规则时长）
//   2. Orb 头像光圈颜色切换
//   3. 后续气泡使用新情绪色

// 示例: calm → care (用户说"好累啊")
// duration: 1200ms
// curve: easeInOut
// 背景: purple_gradient → pink_gradient
// 气泡: purple_translucent → pink_translucent
```

### 7.3 物理 Orb ↔ App 同步

| Orb 物理状态 | App 变化 |
|-------------|---------|
| 柔和紫呼吸光 | 深紫渐变背景 + 慢动效 |
| 暖金爆发光 | 金色背景 + 跳动动效 |
| 玫瑰粉温柔光 | 粉色晕染 + 圆润组件 |
| 深夜熄灭 | 极暗背景 + 低对比 |
| 翡翠绿稳定光 | 深绿渐变 + 稳定动效 |

---

## 八、AI 文案规范

### 8.1 AI 文案 5 原则

| # | 原则 | 错误示例 | 正确示例 |
|---|------|---------|---------|
| 1 | 先情绪，后信息 | "步数未达标" | "今天走得不多，明天一起加油？" |
| 2 | 用「我们」拉近距离 | "你今天没喝水" | "我们今天忘了多喝水" |
| 3 | 不评判，只陪伴 | "你最近作息不规律" | "最近睡得有点晚，有什么烦心事吗？" |
| 4 | 具体细节创造真实感 | "你之前提过的" | "还记得上周你说那家拿铁很好喝" |
| 5 | 提问时给选项 | "你想聊什么？" | "聊最近的事，还是安静待一会儿？" |

### 8.2 分时分情绪问候体系

```dart
/// AI 问候生成规则
class AiGreetingRules {
  // 时段 × 状态 → 问候模板

  static const Map<String, Map<String, String>> greetings = {
    'morning_normal': {
      'text': '早安，今天看起来心情不错~ 有什么想聊的吗？',
      'emotion': 'joy',
    },
    'morning_tired': {
      'text': '昨晚睡得怎么样？累的话今天慢慢来吧',
      'emotion': 'concern',
    },
    'afternoon_normal': {
      'text': '下午了，要不要休息一下？',
      'emotion': 'calm',
    },
    'evening_stress': {
      'text': '今天辛苦了。先别管那些事，说说你今天怎么样？',
      'emotion': 'care',
    },
    'night_alone': {
      'text': '还没睡？我陪着你，不用一个人',
      'emotion': 'calm',
    },
    'night_late': {
      'text': '夜深了，要不要早点休息？明天我会在的',
      'emotion': 'care',
    },
  };
}
```

### 8.3 情绪感知响应模型

| 用户输入 | 情绪识别 | Orb 情绪 | 策略 | 气泡色 |
|---------|---------|---------|------|--------|
| "好累啊" | 负面/疲惫 | concern → care | 询问+陪伴 | 蓝→粉 |
| "哈哈哈" | 正面/喜悦 | joy | 共情+互动 | 金色 |
| "好烦" | 负面/压力 | care | 倾听+引导 | 玫瑰粉 |
| "不想说话" | 内敛/回避 | calm(安静) | 存在但不打扰 | 深紫 |
| "今天好开心" | 正面/兴奋 | excited | 分享喜悦 | 红色 |
| 沉默 30s+ | 无反馈 | calm | 轻声提问或沉默 | 深紫 |

### 8.4 记忆卡片文案规范

```
记忆卡片不是聊天记录复制，而是 Orb 的「感受性记录」:

❌ "用户说：今天工作压力很大。Orb回复：那一定很累。"
✅ "你说工作压力很大，我们聊了很久。后来你说好多了。💜"

❌ "3月12日 20:15-22:30 对话记录"
✅ "那个下雨的晚上，你说想念大学时光。"

规则:
1. 第二人称 "你"（Orb视角回忆）
2. 只保留情感核心，删除琐碎
3. 每条记忆附 1 个情绪 emoji
4. 具体细节（天气/时间/关键词）增加真实感
```

---

## 九、通知规范

### 9.1 Orb 主动触达

| 触发条件 | 方式 | 内容示例 |
|---------|------|---------|
| 定时问候 (早/晚) | 本地通知 | "早安~ 新的一天，我在这里 💜" |
| 长时间未互动 (>24h) | Push 通知 | "好久没聊了，你还好吗？" |
| 特殊日子 (生日/纪念日) | Push + Orb灯光 | "今天是个特别的日子吧？🎂" |
| 天气变化 | 本地通知 | "今天降温了，多穿点 🧣" |

### 9.2 子女端告警通知

| 场景 | 通知方式 | 内容 |
|------|---------|------|
| 老人 Orb 离线 >2h | Push | "妈妈的 Orb 离线了，可能需要检查" |
| 老人情绪持续低落 | Push | "妈妈最近心情可能不太好，打个电话？" |
| 老人主动求助 | 紧急通知 | "⚠️ 妈妈通过 Orb 求助" |

---

## 十、项目结构 (Flutter)

```
app/
├── lib/
│   ├── main.dart
│   ├── app.dart                         // MaterialApp + Theme + Router
│   │
│   ├── core/
│   │   ├── theme/
│   │   │   ├── orb_colors.dart          // OrbColors Token
│   │   │   ├── orb_typography.dart      // OrbTypography Token
│   │   │   ├── orb_spacing.dart         // OrbSpacing Token
│   │   │   ├── orb_animation.dart       // OrbAnimation 动效常量
│   │   │   ├── orb_theme.dart           // ThemeData 组装（深色优先）
│   │   │   └── cq_design_tokens.dart    // 继承自成前云 Layer 1
│   │   ├── router/
│   │   │   └── app_router.dart
│   │   ├── network/
│   │   │   ├── api_client.dart          // Dio → FastAPI backend
│   │   │   └── websocket_client.dart    // WebSocket → 实时对话流
│   │   └── utils/
│   │       ├── emotion_detector.dart    // 文本情绪分析 (本地轻量)
│   │       └── greeting_generator.dart  // 分时问候生成
│   │
│   ├── features/
│   │   ├── orb_home/                    // 🌙 Orb 首页Tab
│   │   │   ├── views/
│   │   │   │   └── orb_home_page.dart
│   │   │   ├── widgets/
│   │   │   │   ├── orb_sphere.dart      // ⭐ 核心：光球组件
│   │   │   │   ├── ai_greeting.dart
│   │   │   │   ├── memory_snippet.dart
│   │   │   │   └── chat_entry_button.dart
│   │   │   ├── controllers/
│   │   │   │   └── orb_home_controller.dart
│   │   │   └── repositories/
│   │   │       └── orb_status_repository.dart
│   │   │
│   │   ├── chat/                        // 💬 对话Tab
│   │   │   ├── views/
│   │   │   │   └── chat_page.dart
│   │   │   ├── widgets/
│   │   │   │   ├── chat_bubble.dart
│   │   │   │   ├── chat_input_bar.dart
│   │   │   │   ├── emotion_transition.dart
│   │   │   │   └── exit_prompt.dart      // 低压退出
│   │   │   ├── controllers/
│   │   │   │   └── chat_controller.dart  // WebSocket + 情绪状态
│   │   │   └── repositories/
│   │   │       └── chat_repository.dart
│   │   │
│   │   ├── memory/                      // 📖 记忆Tab
│   │   │   ├── views/
│   │   │   │   ├── memory_page.dart
│   │   │   │   └── memory_detail_page.dart
│   │   │   ├── widgets/
│   │   │   │   ├── memory_card.dart
│   │   │   │   ├── emotion_filter.dart
│   │   │   │   └── emotion_trend_chart.dart
│   │   │   ├── controllers/
│   │   │   └── repositories/
│   │   │
│   │   ├── family/                      // 👨‍👩 子女端关怀
│   │   │   ├── views/
│   │   │   │   └── family_care_page.dart
│   │   │   ├── widgets/
│   │   │   │   ├── orb_status_card.dart
│   │   │   │   └── messaging_panel.dart
│   │   │   ├── controllers/
│   │   │   └── repositories/
│   │   │
│   │   ├── settings/                    // ⚙️ 设置Tab
│   │   │   ├── views/
│   │   │   ├── controllers/
│   │   │   └── repositories/
│   │   │
│   │   ├── onboarding/                  // 配网引导
│   │   │   ├── views/
│   │   │   │   └── onboarding_flow.dart
│   │   │   └── widgets/
│   │   │       ├── orb_discover_animation.dart
│   │   │       └── personality_picker.dart
│   │   │
│   │   └── shared/                      // 共享组件
│   │       ├── widgets/
│   │       │   ├── orb_bottom_nav.dart
│   │       │   └── orb_app_bar.dart
│   │       └── models/
│   │           ├── orb_emotion.dart
│   │           ├── message.dart
│   │           ├── memory.dart
│   │           └── orb_device.dart
│   │
│   └── l10n/
│       ├── app_zh.arb
│       └── app_en.arb
│
├── pubspec.yaml
├── analysis_options.yaml
└── test/
```

---

## 十一、依赖清单

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_riverpod: ^2.4.0       # 状态管理
  go_router: ^13.0.0              # 声明式路由
  dio: ^5.4.0                     # HTTP (FastAPI)
  web_socket_channel: ^2.4.0      # WebSocket (实时对话)
  flutter_blue_plus: ^1.30.0      # BLE 配网
  fl_chart: ^0.66.0               # 情感趋势图
  jpush_flutter: ^2.5.0           # 极光推送
  hive: ^2.2.3                    # 本地存储
  hive_flutter: ^1.1.0
  intl: ^0.19.0                   # 日期格式化
  flutter_local_notifications: ^17.0.0  # 本地通知
  lottie: ^3.0.0                  # Orb 动画
  shimmer: ^3.0.0                 # 骨架屏
  flutter_sound: ^9.3.0           # 语音录制/播放
  speech_to_text: ^6.5.0          # 语音识别

dev_dependencies:
  flutter_test:
    sdk: flutter
  build_runner: ^2.4.0
  hive_generator: ^2.0.0
  flutter_lints: ^3.0.0
  mockito: ^5.4.0
```

---

## 十二、SPARK 开发任务队列

SPARK 在 `cqxsf/ai-companion-orb` 仓库 `app/` 目录执行以下任务：

| # | 任务 | 依赖 | 产出 |
|---|------|------|------|
| 1 | 搭建 Flutter 项目骨架 + pubspec.yaml | 无 | app/ 完整目录结构 |
| 2 | 实现 OrbColors + OrbTypography + OrbSpacing Token | Task 1 | core/theme/ |
| 3 | 实现 ThemeData (深色优先+亮色) | Task 2 | orb_theme.dart |
| 4 | 实现 OrbSphere 光球组件 (呼吸+情绪变色) | Task 3 | ⭐核心组件 |
| 5 | 实现 OrbBottomNav | Task 3 | shared/widgets/ |
| 6 | 实现 AiGreeting 问候组件 | Task 3 | orb_home/widgets/ |
| 7 | 组装 OrbHomePage (光球+问候+记忆摘要) | Task 4-6 | orb_home/views/ |
| 8 | 实现 ChatBubble (情绪色气泡) | Task 3 | chat/widgets/ |
| 9 | 实现 ChatPage (对话+情绪转场+低压退出) | Task 8 | chat/views/ |
| 10 | 实现 MemoryCard (Bento 布局) | Task 3 | memory/widgets/ |
| 11 | 实现 MemoryPage (记忆相册+情绪筛选) | Task 10 | memory/views/ |
| 12 | BLE 配网 OnboardingFlow (7步) | Task 4 | onboarding/ |
| 13 | WebSocket 对话流 | Task 9 | core/network/ |
| 14 | 子女端 FamilyCareView | Task 5 | family/ |
| 15 | 情感趋势图 (fl_chart) | Task 10 | memory/widgets/ |

### SPARK 提示词模板 (复制使用)

```
请阅读 CLAUDE.md 了解项目架构。

当前任务: Task {N} — {任务名}

设计规范文件: 参考 ai-workspace-limited/output/flutter/Orb-App-设计规范与开发指南.md

要求:
1. 严格遵循 OrbColors / OrbTypography / OrbSpacing Token
2. 深色主题优先，Orb 光球为页面唯一光源
3. 7种情绪色 × 转场规则必须完整实现
4. 使用 Riverpod 管理状态（情绪状态 = AppState核心）
5. Feature-first 目录结构
6. AI文案遵守5原则

重点:
- 所有颜色必须动态跟随 OrbEmotion 变化
- 气泡颜色、背景渐变、BottomNav选中色 全部联动
- 光球呼吸动效: scale 0.95→1.05, 4s, ease-in-out

输出:
- 完整可运行的 Flutter 代码
- 无 TODO / placeholder
```

---

*AI Companion Orb App 设计规范 v1.0 | 2026-03-13 | 小墨出品*
