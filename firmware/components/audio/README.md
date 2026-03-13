# 音频流水线组件

INMP441 × 3 麦克风（三颗麦共享同一 I2S 数据线，通过 L/R 声道选择焊接）+ MAX98357A 扬声器，I2S 双工，16kHz mono。

## 接口

```c
esp_err_t orb_audio_init(const orb_audio_config_t *config);
esp_err_t orb_audio_start_recording(orb_audio_data_callback_t callback);
esp_err_t orb_audio_stop_recording(void);
esp_err_t orb_audio_play_samples(const int16_t *samples, size_t count);
esp_err_t orb_audio_set_volume(uint8_t percent);
```

## 规格

- 采样率：16kHz mono
- VAD 静音检测：1.5s 静音自动停止录音
- 环形缓冲：2s（防网络抖动）
- 默认音量：60%
