# 触摸检测组件

ESP32-S3 内置电容触摸，3 个检测区域（上/中/下）。

## 接口

```c
esp_err_t orb_touch_init(const orb_touch_config_t *config);
void orb_touch_deinit(void);
bool orb_touch_is_active(void);
```

## 手势识别

| 手势 | 触发条件 | 灯光响应 |
|------|----------|----------|
| TAP | 轻触 < 300ms | 微亮波纹 |
| LONG | 长按 > 1.5s | 进入对话模式 |
| EMBRACE | 大面积 > 3s | 安抚模式 |
| DOUBLE_TAP | 双击 300ms 内 | 暂停/继续 |
