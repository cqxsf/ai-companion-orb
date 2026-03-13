/**
 * @file orb_pins.h
 * @brief AI Companion Orb V8 — GPIO 引脚定义（中央定义文件）
 *
 * 所有固件组件通过此头文件获取引脚编号，不允许在组件内硬编码 GPIO。
 * 引脚来源：V8 PCB 原理图（hardware/pcb/README.md）
 */

#pragma once

// ─────────────────────────────────────────────
// LED 驱动（RMT，WS2812B）
// ─────────────────────────────────────────────
#define ORB_PIN_LED_DIN         18   ///< 主灯环 + Halo 菊链 DIN（串 330Ω）
#define ORB_LED_MAIN_COUNT      16   ///< 主灯环 WS2812B 颗数
#define ORB_LED_HALO_COUNT       8   ///< 底部 Halo WS2812B 颗数
#define ORB_LED_TOTAL_COUNT     24   ///< 总颗数（主环 + Halo）

// ─────────────────────────────────────────────
// I2S 麦克风（4× INMP441，90° 环形阵列）
// ─────────────────────────────────────────────
#define ORB_PIN_I2S_MIC_BCLK     4   ///< Bit Clock
#define ORB_PIN_I2S_MIC_LRCK     5   ///< Left/Right Clock
#define ORB_PIN_I2S_MIC_DATA     6   ///< Data（4 路并联，L/R 分时复用）
#define ORB_MIC_COUNT            4   ///< 麦克风数量

// ─────────────────────────────────────────────
// I2S 扬声器（MAX98357A）— 独立 I2S 总线
// ─────────────────────────────────────────────
#define ORB_PIN_I2S_SPK_BCLK     1   ///< Bit Clock
#define ORB_PIN_I2S_SPK_LRC      2   ///< Left/Right Clock
#define ORB_PIN_I2S_SPK_DIN      3   ///< Data Input

// ─────────────────────────────────────────────
// I2C 传感器总线（BME280 + MPU6050）
// ─────────────────────────────────────────────
#define ORB_PIN_I2C_SDA          8   ///< SDA (4.7kΩ 上拉至 3.3V)
#define ORB_PIN_I2C_SCL          9   ///< SCL (4.7kΩ 上拉至 3.3V)

// I2C 设备地址
#define ORB_I2C_ADDR_BME280   0x76   ///< BME280 SDO=GND → 0x76
#define ORB_I2C_ADDR_MPU6050  0x68   ///< MPU6050 AD0=GND → 0x68

// ─────────────────────────────────────────────
// 触摸（ESP32-S3 内置电容触摸控制器）
// 具体通道号待测试板确认后在此更新
// ─────────────────────────────────────────────
#define ORB_TOUCH_TOP_CH         1   ///< 顶部触摸区
#define ORB_TOUCH_MID_CH         2   ///< 中部触摸区
#define ORB_TOUCH_BOT_CH         3   ///< 底部触摸区
