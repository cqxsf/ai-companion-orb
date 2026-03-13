# AI Companion Orb — 完整架构提示词

> 本提示词供 SPARK / Copilot / Claude 等 AI 编程代理使用
> 使用方式：在 SPARK 中打开本项目，AI 会自动读取 CLAUDE.md 获取架构约束

## 给 SPARK 的使用说明

1. 打开 `ai-companion-orb` 项目
2. SPARK 会自动读取 `CLAUDE.md` 作为项目上下文
3. 按 Phase 0 优先级开始开发（灯光引擎 → 触摸 → 音频 → WiFi → 对话闭环）

## 第一个任务建议

对 SPARK 说：

```
请阅读 CLAUDE.md，然后从 Phase 0 开始：
实现 firmware/components/led_engine/ 灯光引擎组件。

要求：
1. 基于 ESP-IDF v5.2 RMT 驱动
2. 24 颗 WS2812B RGB LED 环形排列（V2 升级）
3. 实现 CLAUDE.md 中定义的 9 种情绪灯光模式
4. 呼吸灯参数：3.5s 周期 / sine 曲线 / 5%-40% 亮度
5. 所有灯光切换有 200-500ms 渐变过渡
6. 提供 orb_led_init() 和 orb_led_set_mood() 接口
7. 组件必须有 CMakeLists.txt 和 README.md
```

---

## Orb V4 硬件结构设计（量产级）

### 版本演进

| 版本 | 直径 | 高度 | LED | 光学 | 声学 | 状态 |
|------|------|------|-----|------|------|------|
| V1 | 85mm | — | 12 | 直射 | 无 | 概念 |
| V2 | 90mm | 78mm | 24 | 扩散腔 | 密封腔 | 原型 |
| **V4** | **92mm** | **75mm** | **24** | **光导环** | **倒相管** | **当前** |

### 工业设计比例

```
高度 = 直径 × 0.82 → 75mm = 92mm × 0.82
```

消费电子黄金比例，视觉效果最佳。

### 五层模块架构

```
┌──────────────────────────────┐
│  ① 扩散球壳 (Translucent PLA) │  球面上壳，光线均匀散射
├──────────────────────────────┤
│  ② LED 光导环                 │  壁厚 6mm，全反射导光
│     + LED PCB 安装环           │  24× WS2812B, Ø60mm
├──────────────────────────────┤
│  ③ 中框 (结构骨架)             │  承载 PCB, 麦克风拾音孔
│     主控 PCB Ø65mm            │  ESP32-S3 + 3× INMP441
│     3 点 120° M2 固定         │
├──────────────────────────────┤
│  ④ 声学模块 (倒相音箱)         │  40mm 扬声器 + 共振腔
│     共振腔 ~25cc              │  倒相管 Ø8×12mm
│     调谐频率 ~120Hz           │  低频 +40%, +3dB
├──────────────────────────────┤
│  ⑤ 底座 + 电源                │  18650 电池 + USB-C
│     底面 Ø62mm               │  声孔 + 倒相口 + 硅胶垫
└──────────────────────────────┘
```

### 三大核心升级 (V2→V4)

**1. 光导环** — LED 光线经光导体全内反射混合，消灭 LED 颗粒感
```
V2: LED → 扩散腔 → 扩散片 → 球壳  （仍可见光斑）
V4: LED → 光导环(6mm壁厚) → 球壳  （连续均匀光带）
```

**2. 倒相管** — 声学腔体背波相位反转，低频增强 40%
```
扬声器 → 共振腔(25cc) → 倒相管(Ø8×12mm) → 底座声孔
```

**3. 免支撑打印** — 三件式分模，拓竹无需支撑，成功率极高

### 3D 模型文件 (V4)

```
hardware/3d_models/orb_v4/
├── orb_config.scad          ← 全局参数（改尺寸只改这里）
├── orb_assembly.scad        ← 主入口（F5 预览 / F6 渲染）
├── orb_shell_top.scad       ← 上壳（扩散球壳）
├── orb_shell_middle.scad    ← 中框（结构骨架 + 麦克风孔）
├── orb_shell_bottom.scad    ← 底座（声孔 + USB-C + 硅胶垫）
├── orb_lightguide.scad      ← 光导环（核心光学件）
├── orb_led_mount.scad       ← LED PCB 安装环
├── orb_acoustic.scad        ← 声学腔 + 倒相管
├── orb_pcb_mount.scad       ← PCB 支撑柱 (3点 M2)
├── orb_mic_array.scad       ← 麦克风阵列安装座
├── orb_battery.scad         ← 18650 电池槽
└── exports/                 ← STL 导出（打印用）
```

### OpenSCAD 安装与验证

当前开发环境已验证可用：

- OpenSCAD: 2025.05.16
- 安装路径: `/Applications/OpenSCAD.app`
- CLI 路径: `/opt/homebrew/bin/openscad`
- 架构: universal binary，包含 arm64，可原生运行于 Apple Silicon

安装校验命令：

```bash
file /Applications/OpenSCAD.app/Contents/MacOS/OpenSCAD
/opt/homebrew/bin/openscad --version
```

预期结果：二进制信息包含 `arm64`，版本输出为 `OpenSCAD version 2025.05.16`。

### V4 预览与 STL 导出

打开 GUI 预览：

```bash
open -a /Applications/OpenSCAD.app hardware/3d_models/orb_v4/orb_assembly.scad
```

推荐预览方式：

1. 打开 `hardware/3d_models/orb_v4/orb_assembly.scad`
2. 使用 F5 快速预览整体装配
3. 设置 `EXPLODE = 15;` 查看爆炸图
4. 设置 `SECTION = true;` 检查内部剖面

命令行导出 STL：

```bash
mkdir -p hardware/3d_models/orb_v4/exports

/opt/homebrew/bin/openscad -o hardware/3d_models/orb_v4/exports/top.stl \
	-D 'PRINT_PART="top"' hardware/3d_models/orb_v4/orb_assembly.scad

/opt/homebrew/bin/openscad -o hardware/3d_models/orb_v4/exports/mid.stl \
	-D 'PRINT_PART="mid"' hardware/3d_models/orb_v4/orb_assembly.scad

/opt/homebrew/bin/openscad -o hardware/3d_models/orb_v4/exports/bottom.stl \
	-D 'PRINT_PART="bottom"' hardware/3d_models/orb_v4/orb_assembly.scad

/opt/homebrew/bin/openscad -o hardware/3d_models/orb_v4/exports/lightguide.stl \
	-D 'PRINT_PART="lightguide"' hardware/3d_models/orb_v4/orb_assembly.scad
```

已验证 `top`、`bottom`、`lightguide` 可正常导出，其中 `lightguide` 的非流形警告已修正。

### 拓竹打印配置

| 参数 | 设置 |
|------|------|
| 材料 | PLA+（结构）/ Translucent PLA（上壳 + 光导环） |
| 层高 | 0.2 mm |
| 外壁 | 3 层 |
| 填充 | 15% |
| 支撑 | **无**（免支撑设计） |
| 温度 | 210°C / 热床 60°C |
| 分件 | 上壳 / 中框 / 底座 / 光导环 分别打印 |

### V5 升级方向

1. **热管理** — ESP32 散热通道设计
2. **磁吸外壳** — 免螺丝磁吸装配
3. **声学罩** — 麦克风降噪微结构
4. **微纹理** — 扩散壳内壁消除最后的颗粒感

---

## 后续任务队列

| 序号 | 任务 | 对 SPARK 的指令 |
|------|------|----------------|
| 1 | 灯光引擎 | "实现 led_engine 组件，24 颗 LED，参考 CLAUDE.md §四" |
| 2 | 触摸检测 | "实现 touch_sensor 组件，参考 CLAUDE.md §五" |
| 3 | 音频录放 | "实现 audio 组件，参考 CLAUDE.md §六" |
| 4 | WiFi 管理 | "实现 wifi_manager 组件，处理连接/重连/状态上报" |
| 5 | BLE 配网 | "实现 ble_provision 组件，参考 CLAUDE.md §八" |
| 6 | 主程序 | "实现 main/app_main.c，整合所有组件，用事件驱动" |
| 7 | 3D 外壳 V4 | "优化 hardware/3d_models/orb_v4/ 中的 OpenSCAD 模型" |
| 8 | 后端 API | "实现 FastAPI 后端，参考 CLAUDE.md §九" |
| 9 | Flutter App | "实现 Flutter App 配网流程，参考 CLAUDE.md §八" |
| 10 | 对话闭环 | "实现完整对话链路：唤醒→录音→STT→LLM→TTS→播放" |
