# LED 灯光引擎组件

> Orb 的灵魂组件。灯光 = Orb 的面部表情。

## 接口

```c
esp_err_t orb_led_init(void);
esp_err_t orb_led_set_mood(orb_mood_t mood);
esp_err_t orb_led_set_brightness(uint8_t brightness);
```

## 规格

- 12 颗 WS2812B RGB LED，环形排列
- 呼吸灯: 3.5s 周期, sine 曲线, 5%-40% 亮度
- 9 种情绪模式（见 CLAUDE.md §四）
- 所有切换有 200-500ms 渐变过渡
- 最低亮度 5%（永不完全熄灭）

## 实现指南

使用 SPARK 生成：
```
实现 led_engine 组件。用 ESP-IDF RMT 驱动 WS2812B。
参考项目根目录 CLAUDE.md §四 的完整规格。
```
