# 底部光晕组件 (halo_led)

> 8 颗 WS2812B 以 30° 向下斜射，通过 3mm 硅胶扩散缝在桌面形成柔和光晕投影。
> 与主灯环同为 GPIO18 菊链（接在主环 LED16 的 DOUT 后），由 led_engine 统一驱动。

## 硬件连接

- GPIO18 → 主灯环 16 颗 → Halo 8 颗（菊链末尾）
- 阵列编号：LED[0..15] = 主灯环，LED[16..23] = Halo

## 设计意图

| 模式 | Halo 效果 |
|------|-----------|
| 待机呼吸 | 与主环同步，但亮度降至 30%，色温偏暖 |
| 倾听 | 静态柔光，不动，避免分散注意力 |
| 思考 | 缓慢脉动，0.5Hz |
| 触摸响应 | 波纹从 Halo 向外扩散（桌面效果） |
| 告警 | 与主环同色闪烁，增强可见性 |

## 实现说明

Halo 不是独立组件，由 `led_engine` 组件的 `orb_led_set_mood()` 统一控制。
此目录保存 Halo 专属动效的设计记录和参数。

## Halo 动效参数

```c
#define HALO_IDX_START      16   // Halo 起始 LED 编号
#define HALO_IDX_END        23   // Halo 结束 LED 编号
#define HALO_MAX_BRIGHTNESS 77   // 最大亮度 = 主环的 75%（避免桌面过亮）
#define HALO_ANGLE_DEG      30   // 向下倾斜角（PCB 安装角）
```
