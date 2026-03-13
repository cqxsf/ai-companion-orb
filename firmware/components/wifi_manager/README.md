# WiFi 管理组件

ESP32-S3 WiFi STA 模式，自动重连，NVS 持久化。

## 配网流程

1. 首次启动：等待 BLE 配网模块传入 SSID + Password
2. 连接成功：保存凭据到 NVS，下次自动连接
3. 连接失败：最多重试 5 次，通知回调

## 接口

```c
esp_err_t orb_wifi_init(orb_wifi_event_cb_t event_cb);
esp_err_t orb_wifi_connect(const orb_wifi_config_t *config);
bool orb_wifi_is_connected(void);
```
