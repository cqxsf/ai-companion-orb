# LED 灯光引擎组件

> Orb 的灵魂组件。灯光 = Orb 的面部表情。
> 统一管理主灯环（16 颗）+ 底部 Halo（8 颗），共 24 颗 WS2812B。

## 接口

```c
esp_err_t orb_led_init(void);
esp_err_t orb_led_set_mood(orb_mood_t mood);
esp_err_t orb_led_set_brightness(uint8_t brightness);
esp_err_t orb_led_transition(orb_mood_t next_mood, uint32_t transition_ms);
```

## 硬件规格

| 参数 | 值 |
|------|----|
| 主灯环 | 16 颗 WS2812B，GPIO18，RMT 驱动，330Ω 串联保护 |
| 底部 Halo | 8 颗 WS2812B，30° 向下，菊链接在主环末尾 |
| 总颗数 | 24（LED[0..15] = 主环，LED[16..23] = Halo）|
| 呼吸周期 | 3500ms，sine 曲线，5%-40% 亮度 |
| 切换过渡 | 200-500ms 渐变，禁止硬切 |
| 最低亮度 | 5%（永不完全熄灭） |
| 触摸响应 | ≤100ms 内起反应 |

## GPIO 来源

所有引脚定义从 `firmware/main/include/orb_pins.h` 引用：
```c
#include "orb_pins.h"
// ORB_PIN_LED_DIN     = 18
// ORB_LED_MAIN_COUNT  = 16
// ORB_LED_HALO_COUNT  = 8
// ORB_LED_TOTAL_COUNT = 24
```

## 实现指南

使用 SPARK 生成：
```
实现 led_engine 组件。用 ESP-IDF RMT 外设驱动 WS2812B（共 24 颗）。
GPIO 引脚从 orb_pins.h 获取（ORB_PIN_LED_DIN = 18）。
LED[0..15] 为主灯环，LED[16..23] 为底部 Halo 光晕。
参考 CLAUDE.md §四 的完整情绪映射规格。
```
