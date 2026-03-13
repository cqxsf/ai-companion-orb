# BLE 配网组件

蓝牙 GATT Server，用于首次 WiFi 配网。

## 配网流程

```
App 扫描 → 发现 "OrbLight" → 连接 → 写入 SSID + Password → Orb 连接 WiFi → 通知状态
```

## GATT 服务

| 特征 | UUID | 属性 | 说明 |
|------|------|------|------|
| SSID | 0xFF01 | Write | WiFi SSID |
| Password | 0xFF02 | Write | WiFi 密码 |
| Status | 0xFF03 | Notify | 连接状态 JSON |

## 接口

```c
esp_err_t orb_ble_init(orb_ble_provision_cb_t provision_cb);
esp_err_t orb_ble_start_advertising(void);
esp_err_t orb_ble_send_status(const char *status_json);
```
