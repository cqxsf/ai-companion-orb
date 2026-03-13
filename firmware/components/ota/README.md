# OTA 升级组件

HTTPS 双分区 OTA，支持回滚。

## 接口

```c
esp_err_t orb_ota_init(const orb_ota_config_t *config, orb_ota_event_cb_t event_cb);
esp_err_t orb_ota_check_and_update(void);
```

## 分区方案

使用 ESP-IDF 标准双 OTA 分区：ota_0 / ota_1 交替升级，启动失败自动回滚。
