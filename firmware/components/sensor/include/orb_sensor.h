/**
 * @file orb_sensor.h
 * @brief 环境传感器组件公开接口
 *
 * 硬件：BME280（温湿度+气压）+ MPU6050（六轴 IMU）
 * 总线：I2C，SDA=GPIO8，SCL=GPIO9（参考 orb_pins.h）
 */

#pragma once

#include "esp_err.h"

// ─────────────────────────────────────────────
// 告警类型
// ─────────────────────────────────────────────
typedef enum {
    ORB_SENSOR_ALERT_TEMP_HIGH,     ///< 室温 > 35°C
    ORB_SENSOR_ALERT_TEMP_LOW,      ///< 室温 < 10°C
    ORB_SENSOR_ALERT_HUMIDITY_DRY,  ///< 湿度 < 30%
    ORB_SENSOR_ALERT_HUMIDITY_WET,  ///< 湿度 > 80%
    ORB_SENSOR_ALERT_FALL_DETECT,   ///< 跌倒检测（加速度突变 > 2.5g）
    ORB_SENSOR_ALERT_MOVED,         ///< 设备被移动（陀螺仪持续偏转 > 10°/s）
} orb_sensor_alert_t;

// ─────────────────────────────────────────────
// 数据结构
// ─────────────────────────────────────────────
typedef struct {
    float temp_c;        ///< 温度（摄氏度）
    float humidity_pct;  ///< 相对湿度（%）
    float pressure_hpa;  ///< 气压（hPa）
} orb_env_data_t;

typedef struct {
    float accel_x_g;    ///< X 轴加速度（g）
    float accel_y_g;    ///< Y 轴加速度（g）
    float accel_z_g;    ///< Z 轴加速度（g）
    float gyro_x_dps;   ///< X 轴角速度（°/s）
    float gyro_y_dps;   ///< Y 轴角速度（°/s）
    float gyro_z_dps;   ///< Z 轴角速度（°/s）
} orb_imu_data_t;

// ─────────────────────────────────────────────
// 告警回调
// ─────────────────────────────────────────────
typedef void (*orb_sensor_alert_cb_t)(orb_sensor_alert_t alert);

// ─────────────────────────────────────────────
// 公开接口
// ─────────────────────────────────────────────

/**
 * @brief 初始化 I2C 总线，探测 BME280 和 MPU6050
 * @return ESP_OK 成功；ESP_ERR_NOT_FOUND 器件未响应
 */
esp_err_t orb_sensor_init(void);

/**
 * @brief 读取环境数据（BME280）
 * @param[out] out 温湿度+气压数据
 */
esp_err_t orb_sensor_read_env(orb_env_data_t *out);

/**
 * @brief 读取 IMU 数据（MPU6050）
 * @param[out] out 六轴加速度+角速度
 */
esp_err_t orb_sensor_read_imu(orb_imu_data_t *out);

/**
 * @brief 注册传感器告警回调（异常自动触发）
 */
esp_err_t orb_sensor_set_alert_cb(orb_sensor_alert_cb_t cb);
