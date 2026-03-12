# AI Companion Orb 🔮

> 有温度的家庭 IoT 伴侣 —— 陪伴、守护、连接

一个 85mm 球形 AI 陪伴设备，用灯光呼吸、触摸互动和语音对话，为独居老人和远程照护家庭提供情感陪伴与安全守护。

## 项目结构

```
ai-companion-orb/
├── firmware/          ← ESP32-S3 固件 (ESP-IDF + C)
│   ├── main/          ← 主程序入口
│   ├── components/    ← 功能组件
│   │   ├── led_engine/     ← WS2812B 灯光引擎
│   │   ├── touch_sensor/   ← 电容触摸检测
│   │   ├── audio/          ← 麦克风 + 扬声器
│   │   ├── wifi_manager/   ← WiFi 连接管理
│   │   ├── ble_provision/  ← BLE 配网
│   │   └── ota/            ← OTA 升级
│   └── test/
├── app/               ← Flutter 移动端 App
│   └── lib/
│       ├── core/           ← 主题、路由、常量
│       ├── features/       ← 功能模块
│       ├── models/         ← 数据模型
│       ├── services/       ← API / BLE / 推送
│       └── widgets/        ← 通用组件
├── backend/           ← 云端服务 (Node.js / Python)
│   └── src/
│       ├── routes/         ← API 路由
│       ├── services/       ← 业务逻辑 (LLM对话/记忆等)
│       ├── models/         ← 数据库模型
│       └── middleware/     ← 认证/限流
├── hardware/          ← 硬件设计文件
│   ├── 3d_models/     ← OpenSCAD / STL 文件
│   ├── pcb/           ← KiCad PCB 设计
│   └── bom/           ← BOM 清单
├── docs/              ← 项目文档
└── scripts/           ← 构建/部署/工具脚本
```

## 硬件规格 (Orb v1)

| 参数 | 规格 |
|------|------|
| 主控 | ESP32-S3-WROOM-1 (N16R8) |
| 外径 | 85mm 球形 |
| LED | WS2812B × 12 (RGB, 环形) |
| 麦克风 | INMP441 × 3 (I2S, 120°均布) |
| 扬声器 | 40mm 4Ω 3W + MAX98357A |
| 触摸 | 电容触摸 (ESP32-S3 内置) |
| IMU | BMI270 |
| 电池 | 2000mAh 锂电 |
| 连接 | WiFi 2.4GHz + BLE 5.0 |
| 外壳 | PC 半透明扩散球壳 + 硅胶底座 |
| 售价目标 | ¥699 |
| BOM 成本 | ≈ ¥261 (@10k) |

## 技术栈

- **固件**: ESP-IDF v5.x + FreeRTOS (C)
- **App**: Flutter 3.x + Dart
- **后端**: Python FastAPI / Node.js
- **AI**: DashScope (通义千问) / DeepSeek API
- **数据库**: PostgreSQL + Redis
- **推送**: 极光推送 / Firebase

## 快速开始

```bash
# 固件开发
cd firmware && idf.py set-target esp32s3 && idf.py build

# App 开发
cd app && flutter pub get && flutter run

# 后端开发
cd backend && pip install -r requirements.txt && uvicorn src.main:app --reload
```

## 品牌定位

> **「有温度的家庭 IoT」**
> 不是冷冰冰的智能硬件，而是家庭成员级的 AI 存在。

## License

MIT
