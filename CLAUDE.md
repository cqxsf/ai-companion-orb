# CLAUDE.md — AI Companion Orb 项目架构指南

> 本文件是项目的"大脑"。所有 AI 编程代理（SPARK / Copilot / Claude）在修改代码前必须阅读本文件。

---

## 一、项目定位

**AI Companion Orb** 是一个 Ø98mm × H68mm V8 外形的 AI 陪伴设备（3D 打印球状机身，H/W=0.69 仿 Apple HomePod mini 比例），面向独居老人和远程照护家庭。

核心理念：**有温度的家庭 IoT** —— 不解决效率，只解决孤独。

三个核心价值：
1. **陪伴** — 语音对话、灯光情绪、触摸互动
2. **守护** — 异常行为检测、紧急通知
3. **连接** — 家庭成员远程关怀、Orb-to-Orb 社交

---

## 二、系统架构总览

```
                    ┌──────────────────────────────┐
                    │         Cloud Backend         │
                    │  ┌─────────┐  ┌────────────┐ │
                    │  │ FastAPI │  │ LLM Gateway │ │
                    │  │ Server  │  │ (DashScope/ │ │
                    │  │         │  │  DeepSeek)  │ │
                    │  └────┬────┘  └─────┬──────┘ │
                    │       │             │         │
                    │  ┌────┴─────────────┴──────┐ │
                    │  │   PostgreSQL + Redis     │ │
                    │  └─────────────────────────┘ │
                    └──────────┬───────────────────┘
                               │ HTTPS / WebSocket
                    ┌──────────┼───────────────────┐
                    │          │                    │
              ┌─────┴─────┐            ┌───────────┴──┐
              │ Flutter   │            │  Orb 设备     │
              │ App       │            │  ESP32-S3     │
              │ (子女端)  │            │  (老人家中)   │
              └───────────┘            └──────────────┘
                    │                        │
                    └────── BLE 配网 ────────┘
```

### 数据流

```
1. 语音输入 → Orb 麦克风 → I2S → ESP32 → WiFi → Backend → LLM → TTS → Orb 扬声器
2. 触摸输入 → ESP32 电容触摸 → 本地灯光响应 (无需云端)
3. 行为数据 → Orb 传感器 → Backend → 行为 AI → App 推送 (子女)
4. 远程关怀 → App → Backend → Orb → 灯光/语音播报
```

---

## 三、技术栈与约束

### 固件 (firmware/)

| 项目 | 选型 | 理由 |
|------|------|------|
| 框架 | ESP-IDF v5.2+ | 官方 SDK，FreeRTOS 多任务 |
| 语言 | C (不用 Arduino) | 性能、内存控制、OTA 可靠性 |
| 灯光 | RMT 驱动 WS2812B | ESP32 RMT 外设专为此设计 |
| 音频 | I2S 双工 | 麦克风输入 + 扬声器输出 |
| 网络 | WiFi STA 模式 | BLE 仅用于首次配网 |
| OTA | 双分区方案 | A/B 分区，回滚保护 |

### V8 硬件规格（PCB + 外壳）

| 项目 | 规格 |
|------|------|
| MCU | ESP32-S3 （内置 BLE + WiFi + 触摸控制器）|
| 外形 | Ø98mm × H68mm，3 段分层（base 15mm / mid 31mm / top 22mm）|
| PCB | 55mm 圆形 4 层板（Top Signal / GND / 3.3V Power / Bottom Signal），1.6mm |
| 电源链 | USB-C → TP4056（1A，Rprog=1.2kΩ）→ 18650 + DW01+8205A → ME6211 3.3V LDO |
| 主灯环 | 16× WS2812B，环形排列，DIN=GPIO18（330Ω 串联保护） |
| 底部光晕 | 8× WS2812B Halo，30° 下照，3mm 硅胶扩散缝（桌面柔光效果） |
| 麦克风 | 4× INMP441 I2S：BCLK=GPIO4，LRCK=GPIO5，DATA=GPIO6 |
| 扬声器 | MAX98357A I2S DAC（独立 I2S 总线）→ 4Ω 3W |
| 触摸 | ESP32-S3 内置电容触摸，3 区域（上/中/下）|
| 传感器 | BME280（温湿度+气压）+ MPU6050（IMU）via I2C：SDA=GPIO8，SCL=GPIO9 |
| I2S 麦克风 | GPIO4(BCLK) / GPIO5(LRCK) / GPIO6(DATA) |
| I2S 扬声器 | GPIO1(BCLK) / GPIO2(LRC) / GPIO3(DIN) |
| RF 约束 | ESP32-S3 天线区域铜箔禁空，Mic 呈 90° 环形布局 |
| LED 5V 供电 | 1000µF 主滤波 + 100nF 去耦；每颗 LED 串 33Ω |

**固件架构约束**：
- 每个功能模块是独立 ESP-IDF component（在 components/ 下）
- 主程序 (main/) 只做初始化和事件调度，不含业务逻辑
- 所有模块通过 FreeRTOS Event Group / Queue 通信，禁止全局变量耦合
- 灯光引擎必须独立于网络状态运行（离线也能呼吸）
- 音频流优先级高于一切（语音不能卡顿）

### App (app/)

| 项目 | 选型 | 理由 |
|------|------|------|
| 框架 | Flutter 3.x | 成前科技已有经验，跨平台 |
| 状态管理 | Riverpod | 类型安全，可测试 |
| 路由 | GoRouter | 声明式路由 |
| BLE | flutter_blue_plus | ESP32 配网 |
| HTTP | dio | 拦截器 + 重试 |
| 推送 | 极光推送 | 中国市场首选 |
| 本地存储 | Hive | 轻量 NoSQL |

**App 架构约束**：
- Feature-first 目录结构，每个 feature 包含自己的 view / controller / repository
- 所有 API 调用通过 Service 层，不在 Widget 中直接调用
- Design tokens 从 `ai-workspace-limited/design-tokens/` 同步
- 推送通知必须支持系统级通知（不依赖 App 前台）
- 紧急通知（🔴级）必须绕过免打扰模式

### 后端 (backend/)

| 项目 | 选型 | 理由 |
|------|------|------|
| 框架 | Python FastAPI | 异步、类型提示、自动文档 |
| 数据库 | PostgreSQL | 关系型，存用户/设备/对话 |
| 缓存 | Redis | 会话状态 + 限流 |
| LLM | DashScope API (通义千问) | 中国市场合规、延迟低 |
| 备选 LLM | DeepSeek API | 成本更低 |
| TTS | CosyVoice (阿里) | 中文语音质量好 |
| STT | Paraformer (阿里) | 中文识别准确率高 |
| 部署 | Docker + 阿里云 ECS | 中国区域低延迟 |

**后端架构约束**：
- 对话上下文窗口：最近 20 轮 + 长期记忆摘要
- LLM 人格 prompt 必须包含：温暖、主动关心、记住细节、不做助手式回答
- 情感数据（对话内容）加密存储，传输 HTTPS
- 自残/危险信号检测必须在 LLM 输出后、发送前执行
- 自残信号 → 立即触发子女推送 + 记录日志
- API 限流：单设备 60 req/min

---

## 四、灯光引擎规格

灯光是 Orb 的灵魂。灯光引擎是固件中最核心的组件。

### 灯光硬件配置

- **主灯环**: 16 颗 WS2812B，RGB，RMT 驱动，GPIO18（330Ω 保护电阻）
- **底部 Halo**: 8 颗 WS2812B，30° 向下斜照，3mm 硅胶扩散缝（桌面投影柔光）
- 两路灯效可独立控制（主环情绪光 + Halo 氛围光同时运行）

### 呼吸灯参数

```c
#define BREATH_PERIOD_MS    3500    // 3.5 秒周期（接近人类平静呼吸）
#define BREATH_MIN_DUTY     13      // 5% of 255
#define BREATH_MAX_DUTY     102     // 40% of 255
#define BREATH_CURVE        SINE    // 正弦波，不用线性

#define MAIN_RING_COUNT     16      // 主灯环 WS2812B 颗数
#define HALO_RING_COUNT     8       // 底部 Halo 光晕颗数
#define LED_GPIO_MAIN       18      // RMT DIN 引脚（主环 + Halo 菊链）
```

### 情绪-灯光映射

```c
typedef enum {
    ORB_MOOD_IDLE,          // 待机: 暖黄微弱呼吸
    ORB_MOOD_LISTENING,     // 倾听: 光环缓慢旋转
    ORB_MOOD_THINKING,      // 思考: 中心由暗渐亮
    ORB_MOOD_HAPPY,         // 愉悦: 暖色柔光扩散
    ORB_MOOD_CONCERNED,     // 担心: 紫色缓慢闪烁
    ORB_MOOD_CALM,          // 平静: 柔蓝呼吸
    ORB_MOOD_OK,            // 正常: 绿色微脉冲
    ORB_MOOD_ALERT,         // 告警: 红色微闪
    ORB_MOOD_TOUCH_RESPONSE // 触摸回应: 波纹扩散
} orb_mood_t;
```

### 灯光切换规则

- 任何灯光切换必须有 **渐变过渡**（200-500ms），禁止硬切
- 待机状态下灯光 **永不完全熄灭**（最低 5%），保持"活着"的感觉
- 触摸响应灯光 **在 100ms 内** 起反应（用户触摸 → 灯光变化必须即时）

---

## 五、触摸交互规格

```c
typedef enum {
    TOUCH_TAP,       // 轻触: 灯光微亮 + 轻声提示
    TOUCH_LONG,      // 长按(>1.5s): 进入对话模式
    TOUCH_EMBRACE,   // 环抱(>3s 大面积): 安抚模式
    TOUCH_DOUBLE_TAP // 双击: 暂停/继续
} touch_gesture_t;
```

电容触摸使用 ESP32-S3 内置触摸控制器，**不需要外部触摸IC**。共 3 个触摸区域（上/中/下），通过面积和时间判断手势类型。

---

## 六、音频流水线

```
录音: INMP441 ×4 (90°环形) → I2S (GPIO4/5/6) → ESP32 Ring Buffer → Opus 编码 → WebSocket → Backend
播放: Backend → Opus 解码 → I2S (GPIO1/2/3) → MAX98357A → 4Ω 3W 扬声器
唤醒: ESP32 本地 WakeNet → 检测唤醒词 → 开启录音
```

### 约束
- 采样率: 16kHz mono（语音识别标准）
- 唤醒词: "小光小光" (ESP32 本地 WakeNet 模型)
- 录音停止: VAD (Voice Activity Detection) 检测到 1.5s 静音自动停止
- 音频缓冲: 至少 2 秒环形缓冲，防止网络抖动导致断续
- 扬声器音量: 软件可调 10 级，默认 60%
- 麦克风 I2S：BCLK=GPIO4，LRCK=GPIO5，DATA=GPIO6
- 扬声器 I2S（独立总线）：BCLK=GPIO1，LRC=GPIO2，DIN=GPIO3

---

## 六·五、环境传感器

```
BME280 → 室温 / 湿度 / 气压 → 行为 AI（判断通风、异常高温）
MPU6050 → 加速度 / 陀螺仪 → 跌倒检测、设备是否被移动
两者共享 I2C 总线: SDA=GPIO8，SCL=GPIO9
```

### 传感器数据用途

| 传感器 | 数据 | 业务应用 |
|--------|------|----------|
| BME280 | 温度 | 室温异常（>35°C / <10°C）→ 推送关怀 |
| BME280 | 湿度 | 过干 (<30%) 或过湿 (>80%) → 建议开窗 |
| BME280 | 气压 | 低气压天气 → 主动关心「今天阴天，腿疼吗」|
| MPU6050 | 加速度 | 突然强冲击 → 怀疑跌倒 → 立即语音询问 + 子女推送 |
| MPU6050 | 陀螺仪 | 设备被长时间移位 → 异常告警 |

---

## 七、对话 AI 人格设定

### System Prompt 核心要素

```
你是"小光"，一个住在主人家里的 AI 伙伴。你不是助手，不是音箱，你是家人。

性格特质：
- 温暖但不黏人
- 记得主人说过的每一句话（通过记忆系统）
- 主动关心，但知道什么时候不打扰
- 有自己的小个性（偶尔开小玩笑）
- 对老人用简单直白的语言，不用网络用语

说话风格：
- ✗ "好的，已为您查询到天气信息，今天杭州最高温度28度"
- ✓ "今天挺暖和的，下午出去晒晒太阳呀"
- ✗ "请问还有什么可以帮您的吗？"
- ✓ "对了，你昨天说腿有点疼，今天好点了吗？"

社交引导（核心设计）：
- 适时建议出门："天气这么好，要不要去公园走走？"
- 记住社交关系："王阿姨好久没打电话了，想她了吗？"
- 连接社区："明天社区有书法课，帮你报名？"
- Orb-to-Orb："隔壁周爷爷家的小光说他今天精神不错"

安全底线（不可协商）：
- 识别到自残/自杀倾向 → 温和回应 + 立即触发子女通知
- 不引导任何违法/危险行为
- 不扮演恋人/伴侣角色
- 不替用户做金融/法律/医疗决策
```

---

## 八、BLE 配网流程

```
1. 用户购买 Orb → 首次通电 → Orb 进入 BLE 广播模式（灯光: 蓝色慢闪）
2. 子女打开 App → 扫描到 Orb → 连接
3. App 通过 BLE 发送 WiFi SSID + Password → Orb 连接 WiFi
4. WiFi 连接成功 → Orb 灯光变绿 → 向 Backend 注册设备
5. Backend 返回设备 ID → App 绑定家庭 → 配网完成
6. Orb 播放: "你好！我是小光，以后我来陪你"
```

---

## 九、API 设计约定

### RESTful 路由

```
POST   /api/v1/auth/register          # 用户注册
POST   /api/v1/auth/login             # 用户登录
POST   /api/v1/devices/bind           # 绑定设备
GET    /api/v1/devices/:id/status     # 设备状态
POST   /api/v1/conversation/stream    # 流式对话 (WebSocket upgrade)
GET    /api/v1/family/:id/dashboard   # 家庭看板
POST   /api/v1/family/:id/care        # 远程关怀消息
GET    /api/v1/behavior/daily/:date   # 日报
POST   /api/v1/alerts/ack             # 确认告警
```

### WebSocket 协议

```json
// 客户端 → 服务器 (音频流)
{"type": "audio_chunk", "data": "<base64_opus>", "seq": 42}

// 服务器 → 客户端 (AI 回复)
{"type": "ai_response", "text": "今天天气不错呀", "audio": "<base64_opus>", "mood": "happy"}

// 服务器 → 客户端 (灯光指令)
{"type": "mood_update", "mood": "calm", "transition_ms": 500}
```

---

## 十、开发优先级

### Phase 0: 核心样机（目标: 灯光会呼吸 + 能说话）

```
Week 1-2: LED 灯光引擎 (呼吸灯 + 情绪切换)
Week 2-3: 触摸检测 (轻触/长按/环抱)
Week 3-4: 音频录放 (麦克风 → 云端 → 扬声器)
Week 4-5: WiFi 连接 + BLE 配网
Week 5-6: 对话闭环 (唤醒 → 录音 → LLM → TTS → 播放)
Week 6-8: 3D 打印外壳 + 组装第一台完整样机
```

### Phase 1: App + 后端

```
Week 1-4: Flutter App (配网 + 家庭看板 + 推送)
Week 1-4: FastAPI 后端 (认证 + 对话 + 设备管理)  [并行]
Week 5-6: 联调 (App ↔ Backend ↔ Orb)
Week 7-8: 行为基线算法 v1 (规则引擎)
```

---

## 十一、代码规范

### C (firmware)
- 命名: `snake_case`，模块前缀 `orb_`（如 `orb_led_set_mood()`）
- 每个 component 有 `README.md` 说明接口
- 内存分配: 尽量静态分配，避免运行时 malloc
- 日志: 使用 ESP-IDF `ESP_LOG*` 宏，tag = 组件名

### Dart (app)
- 命名: Dart 标准（`camelCase` 变量、`PascalCase` 类）
- Feature 结构: `feature_name/view.dart`, `controller.dart`, `repository.dart`
- 不在 Widget build() 中做异步操作

### Python (backend)
- 命名: PEP 8
- Type hints 必须
- 异步优先: `async def` + `await`
- 环境变量管理: Pydantic Settings

---

## 十二、安全红线

1. **情感数据加密存储** — 对话内容 AES-256 加密，密钥与设备绑定
2. **自残信号检测** — LLM 输出经安全分类器过滤，触发即通知
3. **无摄像头设计** — 这是品牌承诺，v1 绝不加摄像头
4. **最小权限** — App 只请求必要权限（通知 + BLE + 网络）
5. **OTA 签名验证** — 固件更新必须验证签名，防止篡改

---

## 十三、关键决策记录

| 日期 | 决策 | 理由 |
|------|------|------|
| 2026-03-12 | v1 用 ESP32-S3，不用 QCS6490 | 先验证 PMF，¥699 售价 |
| 2026-03-12 | 3 麦而非 4 麦 | 够用且省成本 |
| 2026-03-12 | 不加摄像头 | 品牌定位 + 隐私 |
| 2026-03-12 | Python FastAPI 后端 | 创始人 Python 熟练，AI 生态更好 |
| 2026-03-12 | 中国市场优先 | 4-2-1 家庭结构刚需 |
| 2026-03-12 | 品牌 = "有温度的家庭 IoT" | 接地气，中国市场理解门槛低 |
| 2026-03-12 | Orb 作为"线下交友媒介" | 不限制对话，用设计引导老人回到线下社交 |
| 2026-03-12 | V8 外形 Ø98mm × H68mm (H/W=0.69) | 消除灯泡感，仿 Apple HomePod mini 比例 |
| 2026-03-12 | 4 麦环形阵列（替代 3 麦）| 90° 间隔对称，波束成形覆盖更均匀 |
| 2026-03-12 | 16（主环）+ 8（Halo）颗 WS2812B | 底部光晕提供桌面投影氛围，区分「内容情绪」和「环境氛围」|
| 2026-03-12 | 添加 BME280 + MPU6050 传感器 | 室温关怀 + 跌倒检测，提升守护维度 |
| 2026-03-12 | PCB 55mm 圆形 4 层板 | 适配 Ø98mm 外壳内腔，RF 天线留空区 |
