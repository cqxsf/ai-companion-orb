# Orb 3D 模型 — 硬件结构设计

> 从概念到量产的结构迭代

## 版本演进

| 版本 | 目录 | 核心特征 |
|------|------|----------|
| V2 | `modules/` + `orb_v2_assembly.scad` | 5 层模块、扩散腔、基础声学 |
| **V4** | **`orb_v4/`** | **光导环、倒相管、工业比例、免支撑打印** |

**当前主力版本: V4**

---

## V4 总体参数

| 参数 | 数值 | 设计依据 |
|------|------|----------|
| 直径 | 92 mm | 桌面设备最佳尺寸 |
| 高度 | 75 mm | 黄金比例 0.82 × 直径 |
| 壁厚 | 2.2 mm | 注塑级壁厚 |
| 底面 | Ø62 mm | 桌面稳定性 |
| LED | 24× WS2812B | Ø60mm 环形 |
| 扬声器 | 40mm 4Ω 3W | 共振腔 + 倒相管 |
| 电池 | 18650 | 单节 3.7V |
| 麦克风 | 3× INMP441 | 120° 均布 |

---

## V4 文件结构

```
orb_v4/
├── orb_config.scad         ← 全局参数（改这里调尺寸）
├── orb_assembly.scad       ← 主入口（F5 预览 / F6 渲染）
├── orb_shell_top.scad      ← 上壳（扩散球壳）
├── orb_shell_middle.scad   ← 中框（结构骨架）
├── orb_shell_bottom.scad   ← 底座（声孔 + USB-C）
├── orb_lightguide.scad     ← 光导环（核心光学件）
├── orb_led_mount.scad      ← LED PCB 安装环
├── orb_acoustic.scad       ← 声学腔 + 倒相管
├── orb_pcb_mount.scad      ← PCB 支撑柱 (M2)
├── orb_mic_array.scad      ← 麦克风阵列安装座
├── orb_battery.scad        ← 18650 电池槽
└── exports/                ← STL 导出目录
```

---

## V4 三大核心升级

### 1. LED 光导环 (Light Guide Ring)

```
V2: LED → 扩散腔(12mm) → 二次扩散片 → 球壳    （仍有颗粒感）
V4: LED → 光导环(壁厚6mm) → 球壳               （连续光带）
```

- 光导壁厚 6mm，全内反射混合光线
- LED 入光槽精确对位 24 颗 WS2812B
- 效果接近 Apple HomePod / Google Nest

### 2. 倒相管声学 (Bass Reflex)

```
┌─────────────┐
│   扬声器     │  40mm 4Ω 3W
├─────────────┤
│  共振腔      │  ~25cc 容积
├──┐     ┌───┤
│  │倒相管│   │  Ø8 × 12mm
└──┘     └───┘
     ↓ 底座声孔
```

- 调谐频率 ~120Hz，低频增强 ~40%，声压级 +3dB

### 3. 免支撑打印

| 部件 | 材料 | 支撑 |
|------|------|------|
| 上壳 | Translucent PLA | 无 |
| 中框 | PLA+ | 无 |
| 底座 | PLA+ | 无 |
| 光导环 | Translucent PLA | 无 |

---

## 使用方法

### OpenSCAD 环境验证

已在 Apple Silicon macOS 上验证以下安装结果：

- OpenSCAD 版本：2025.05.16
- 安装路径：`/Applications/OpenSCAD.app`
- 命令行入口：`/opt/homebrew/bin/openscad`
- 二进制架构：universal binary（包含 arm64，可原生运行于 M1/M2/M3）

可用以下命令复核本机安装：

```bash
file /Applications/OpenSCAD.app/Contents/MacOS/OpenSCAD
/opt/homebrew/bin/openscad --version
```

### 预览装配体

1. OpenSCAD 打开 `orb_v4/orb_assembly.scad`
2. F5 预览 / `EXPLODE = 15;` 爆炸视图 / `SECTION = true;` 剖面

也可直接从命令行启动 GUI：

```bash
open -a /Applications/OpenSCAD.app hardware/3d_models/orb_v4/orb_assembly.scad
```

### 导出 STL

1. 设置 `PRINT_PART = "top";`（或 `"mid"` / `"bottom"` / `"lightguide"`）
2. F6 渲染 → 导出 STL → 保存到 `exports/`

也可用命令行直接导出：

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

建议优先导出这 4 个打印件：上壳、中框、底座、光导环。

### 修改尺寸

编辑 `orb_v4/orb_config.scad`，所有模块自动更新。

---

## 拓竹打印配置

| 参数 | 设置 |
|------|------|
| 层高 | 0.2 mm |
| 外壁 | 3 层 |
| 填充 | 15% |
| 支撑 | **无** (免支撑设计) |
| 温度 | 210°C / 热床 60°C |

---

## V5 升级方向

| 特性 | 描述 |
|------|------|
| 热管理 | ESP32 散热通道 |
| 磁吸外壳 | 免螺丝装配 |
| 声学罩 | 麦克风降噪微结构 |
| 微纹理 | 扩散壳内壁消除颗粒感 |
| 触摸区域 | 电容触摸铜箔定位 |

---

## V2 (旧版，保留参考)

V2 文件位于根目录 `modules/` + `orb_v2_assembly.scad`，5 层模块结构。详见各文件注释。
