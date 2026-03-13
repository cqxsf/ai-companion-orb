# Orb V8 PCB — KiCad 工程

> ESP32-S3 核心，55mm 圆形 4 层板，适配 Ø98mm × H68mm 球壳内腔。

---

## 工程文件结构

```
hardware/pcb/
├── README.md                    ← 本文件
├── orb_main.kicad_pro           ← KiCad 工程文件
├── schematics/
│   ├── main.kicad_sch           ← MCU + 电源入口总图
│   ├── power.kicad_sch          ← 充电管理 (TP4056 + DW01 + ME6211)
│   ├── audio.kicad_sch          ← 麦克风阵列 (4× INMP441) + 功放 (MAX98357A)
│   ├── led.kicad_sch            ← LED 驱动 (16+8 WS2812B, GPIO18)
│   └── sensor.kicad_sch         ← BME280 + MPU6050 I2C 传感器
├── layout/
│   ├── orb_main.kicad_pcb       ← PCB 布局 (55mm 圆形)
│   └── orb_main.kicad_dru       ← DRC 规则文件
├── fabrication/
│   ├── gerbers/                 ← 生产 Gerber 文件（导出后放此处）
│   └── bom.csv                  ← 物料清单
└── datasheets/                  ← 关键器件规格书（PDF）
```

---

## 层叠结构（4 层板，1.6mm）

| 层 | 功能 | 说明 |
|----|------|------|
| L1 Top Signal | 信号线 + 器件面 | ESP32-S3、传感器、麦克风在此 |
| L2 GND | 地平面 | 完整铺铜，屏蔽 EMI |
| L3 3.3V Power | 电源平面 | 3.3V LDO 输出覆铜 |
| L4 Bottom Signal | 信号线 + 焊盘 | LED 驱动线、部分去耦电容 |

---

## GPIO 引脚分配（V8 最终版）

| GPIO | 功能 | 器件 | 备注 |
|------|------|------|------|
| GPIO1 | I2S_SPK_BCLK | MAX98357A | 扬声器 I2S Bit Clock |
| GPIO2 | I2S_SPK_LRC | MAX98357A | 扬声器 I2S LR Clock |
| GPIO3 | I2S_SPK_DIN | MAX98357A | 扬声器 I2S Data |
| GPIO4 | I2S_MIC_BCLK | 4× INMP441 | 麦克风 I2S Bit Clock |
| GPIO5 | I2S_MIC_LRCK | 4× INMP441 | 麦克风 I2S LR Clock |
| GPIO6 | I2S_MIC_DATA | 4× INMP441 | 麦克风 I2S Data (并联输出) |
| GPIO8 | I2C_SDA | BME280 + MPU6050 | I2C 数据线 (4.7kΩ 上拉) |
| GPIO9 | I2C_SCL | BME280 + MPU6050 | I2C 时钟线 (4.7kΩ 上拉) |
| GPIO18 | LED_DIN | 16+8 WS2812B | RMT 输出，330Ω 串联保护 |
| TOUCH1~3 | 触摸区域 | ESP32-S3 内置 | 上/中/下 3 个触摸感应极板 |

> 扬声器 I2S（GPIO1/2/3）与麦克风 I2S（GPIO4/5/6）使用**独立 I2S 总线**，避免回声。

---

## 电源链设计

```
USB-C (5V)
  │
  ▼
TP4056 充电管理
  ├── Rprog = 1.2kΩ → 充电电流 1000mA
  ├── CHRG LED (红): 充电中
  └── STDBY LED (绿): 充电完成
        │
        ▼
    18650 锂电池 (3.7V nominal)
        │
    DW01 + 8205A 保护电路
  ├── 过充保护 (>4.25V 截止)
  ├── 过放保护 (<2.4V 截止)
  └── 短路保护
        │
        ▼
    ME6211 LDO (3.3V / 500mA)
  ├── 输入电容: 10µF
  ├── 输出电容: 22µF
  └── 3.3V 给 ESP32-S3 + 传感器
        
LED 独立 5V 轨道
  ├── 从 USB 或升压模块供 5V
  ├── 主滤波: 1000µF 电解
  ├── 去耦: 100nF × LED区domain
  └── 每颗 WS2812B 串 33Ω 限流
```

---

## 布局关键规则

### RF 约束
- ESP32-S3 天线（FCC 认证 PCB 天线）必须伸出 PCB 边缘
- 天线底部及两侧 5mm 范围内**禁止铺铜**（包括地平面开窗）
- 天线附近避免高速信号线

### 麦克风布局
- 4× INMP441 以 90° 间隔均匀环形排列在 PCB 中轴外圈
- 每个麦克风正上方的外壳对应一个 Ø1.5mm 拾音孔
- 麦克风与功放（MAX98357A）相互隔离，避免声学耦合

### LED 走线
- GPIO18 → 330Ω 保护电阻 → 主灯环 LED1 DIN
- 主灯环 16 颗首尾菊链：DOUT(n) → DIN(n+1)
- Halo 8 颗从主灯环 DOUT(16) 继续菊链
- LED 5V 引脚旁置 100nF 去耦电容
- 总 5V 主滤波 1000µF 电解电容靠近 USB 输入端

### I2C 总线
- SDA/SCL 线长尽量短，避免过孔
- 总线末端 4.7kΩ 上拉至 3.3V
- BME280 和 MPU6050 地址不冲突（BME280: 0x76/0x77，MPU6050: 0x68/0x69）

---

## BOM 清单（V8 主要器件）

| 位号 | 器件 | 封装 | 数量 | 单价(¥) | 备注 |
|------|------|------|------|---------|------|
| U1 | ESP32-S3-WROOM-1 | SMD | 1 | ¥25 | 16MB Flash / 8MB PSRAM |
| U2 | TP4056 | SOT23-6 | 1 | ¥0.5 | 1A 充电管理 |
| U3 | ME6211 | SOT23-3 | 1 | ¥0.3 | 3.3V 500mA LDO |
| U4 | DW01A | SOT23-6 | 1 | ¥0.3 | 电池保护 IC |
| Q1 | 8205A | DFN-8 | 1 | ¥0.5 | 双 MOS 保护管 |
| U5 | MAX98357A | WLCSP-9 | 1 | ¥8 | I2S DAC + D类功放 |
| U6~U9 | INMP441 | LGA-6 | 4 | ¥6×4 | MEMS I2S 麦克风 |
| U10 | BME280 | LCC-8 | 1 | ¥8 | 温湿度+气压传感器 |
| U11 | MPU6050 | QFN-24 | 1 | ¥5 | 六轴 IMU |
| LED1~16 | WS2812B | 5050 | 16 | ¥0.5×16 | 主灯环 |
| LED17~24 | WS2812B | 5050 | 8 | ¥0.5×8 | 底部 Halo |
| R1 | 330Ω | 0402 | 1 | ¥0.02 | LED DIN 保护 |
| R2 | 1.2kΩ | 0402 | 1 | ¥0.02 | TP4056 Rprog (1A) |
| R3,R4 | 4.7kΩ | 0402 | 2 | ¥0.02 | I2C 上拉 |
| C1 | 1000µF/10V | 电解 | 1 | ¥0.5 | LED 主滤波 |
| C2 | 10µF | 0805 | 1 | ¥0.1 | LDO 输入滤波 |
| C3 | 22µF | 0805 | 1 | ¥0.1 | LDO 输出滤波 |
| C4~C28 | 100nF | 0402 | 25 | ¥0.02 | 去耦 (各 IC 旁) |
| J1 | USB-C 16P | SMD | 1 | ¥1.5 | 充电 + 调试 |
| BAT1 | 18650 | 通孔 | 1 | ¥15 | 3.7V 2600mAh |
| SP1 | 4Ω 3W | SMD | 1 | ¥5 | 扬声器 |

**BOM 估算总成本：约 ¥120-140（含 PCB 打样 5 片分摊）**

---

## 开发状态

- [ ] KiCad 原理图（5 张子图）
- [ ] PCB 布局布线（55mm 圆形）
- [ ] DRC 通过（0 错误）
- [ ] Gerber 导出验证
- [ ] PCB 打样（嘉立创/JLCPCB）
- [ ] 首批焊板验证
