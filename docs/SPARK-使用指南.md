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
2. 12 颗 WS2812B RGB LED 环形排列
3. 实现 CLAUDE.md 中定义的 9 种情绪灯光模式
4. 呼吸灯参数：3.5s 周期 / sine 曲线 / 5%-40% 亮度
5. 所有灯光切换有 200-500ms 渐变过渡
6. 提供 orb_led_init() 和 orb_led_set_mood() 接口
7. 组件必须有 CMakeLists.txt 和 README.md
```

## 后续任务队列

| 序号 | 任务 | 对 SPARK 的指令 |
|------|------|----------------|
| 1 | 灯光引擎 | "实现 led_engine 组件，参考 CLAUDE.md §四" |
| 2 | 触摸检测 | "实现 touch_sensor 组件，参考 CLAUDE.md §五" |
| 3 | 音频录放 | "实现 audio 组件，参考 CLAUDE.md §六" |
| 4 | WiFi 管理 | "实现 wifi_manager 组件，处理连接/重连/状态上报" |
| 5 | BLE 配网 | "实现 ble_provision 组件，参考 CLAUDE.md §八" |
| 6 | 主程序 | "实现 main/app_main.c，整合所有组件，用事件驱动" |
| 7 | 3D 外壳 | "用 OpenSCAD 设计 85mm 球壳，参考 CLAUDE.md" |
| 8 | 后端 API | "实现 FastAPI 后端，参考 CLAUDE.md §九" |
| 9 | Flutter App | "实现 Flutter App 配网流程，参考 CLAUDE.md §八" |
| 10 | 对话闭环 | "实现完整对话链路：唤醒→录音→STT→LLM→TTS→播放" |
