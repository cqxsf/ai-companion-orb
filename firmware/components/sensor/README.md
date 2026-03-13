# 环境传感器组件 (sensor)

> BME280（温湿度+气压）+ MPU6050（六轴 IMU）通过 I2C 共享总线读取。

## 硬件连接

| 信号 | GPIO | 说明 |
|------|------|------|
| SDA  | GPIO8 | I2C 数据（4.7kΩ 上拉至 3.3V）|
| SCL  | GPIO9 | I2C 时钟（4.7kΩ 上拉至 3.3V）|
| BME280 地址 | 0x76 | SDO 引脚接 GND |
| MPU6050 地址 | 0x68 | AD0 引脚接 GND |

## 接口

```c
esp_err_t orb_sensor_init(void);

// 环境数据读取
esp_err_t orb_sensor_read_env(float *temp_c, float *humidity_pct, float *pressure_hpa);

// IMU 数据读取
esp_err_t orb_sensor_read_imu(float *accel_g[3], float *gyro_dps[3]);

// 注册回调（异常事件驱动）
typedef void (*orb_sensor_alert_cb_t)(orb_sensor_alert_t alert);
esp_err_t orb_sensor_set_alert_cb(orb_sensor_alert_cb_t cb);
```

## 告警类型

```c
typedef enum {
    ORB_SENSOR_ALERT_TEMP_HIGH,    // 室温 > 35°C
    ORB_SENSOR_ALERT_TEMP_LOW,     // 室温 < 10°C
    ORB_SENSOR_ALERT_HUMIDITY_DRY, // 湿度 < 30%
    ORB_SENSOR_ALERT_HUMIDITY_WET, // 湿度 > 80%
    ORB_SENSOR_ALERT_FALL_DETECT,  // 跌倒检测（加速度突变 > 2.5g）
    ORB_SENSOR_ALERT_MOVED,        // 设备被移动（陀螺仪持续偏转）
} orb_sensor_alert_t;
```

## 采样策略

- 环境数据（BME280）：每 30 秒采样一次，上传后端
- IMU（MPU6050）：100Hz 持续采样，本地滑窗分析跌倒特征
- 跌倒判断：合加速度 a_total = sqrt(ax² + ay² + az²) > 2.5g 持续 50ms → 触发告警

## 实现指南

```
使用 SPARK 生成：
实现 sensor 组件。用 ESP-IDF i2c_master 接口初始化 BME280 和 MPU6050。
所有引脚来自 firmware/main/include/orb_pins.h。
参考 CLAUDE.md §六·五 传感器规格。
```
