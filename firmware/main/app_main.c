/**
 * AI Companion Orb — 主程序入口
 *
 * 职责：初始化所有组件 + 事件调度
 * 业务逻辑不在此文件中实现
 *
 * 硬件：V8 PCB — ESP32-S3 + 24× WS2812B + 4× INMP441 + MAX98357A
 *              + BME280 + MPU6050（I2C） + 3 区电容触摸
 * GPIO 定义：firmware/main/include/orb_pins.h
 */

#include <stdio.h>
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "freertos/event_groups.h"
#include "esp_log.h"
#include "nvs_flash.h"
#include "orb_pins.h"

// TODO: 取消注释以下 include（待各组件实现后逐一启用）
// #include "orb_led.h"       — GPIO18, 24× WS2812B (16主环+8Halo)
// #include "orb_touch.h"     — ESP32-S3 内置触摸，3 区域
// #include "orb_audio.h"     — Mic I2S GPIO4/5/6 + Spk I2S GPIO1/2/3
// #include "orb_wifi.h"      — WiFi STA 模式
// #include "orb_ble.h"       — BLE 配网（仅首次通电）
// #include "orb_sensor.h"    — BME280 + MPU6050 via I2C GPIO8/9

static const char *TAG = "orb_main";

void app_main(void)
{
    ESP_LOGI(TAG, "=== AI Companion Orb v0.1 ===");
    ESP_LOGI(TAG, "硬件: V8 PCB  LED_DIN=GPIO%d  MIC_BCLK=GPIO%d  I2C_SDA=GPIO%d",
             ORB_PIN_LED_DIN, ORB_PIN_I2S_MIC_BCLK, ORB_PIN_I2C_SDA);

    // 初始化 NVS（WiFi/BLE 需要）
    esp_err_t ret = nvs_flash_init();
    if (ret == ESP_ERR_NVS_NO_FREE_PAGES || ret == ESP_ERR_NVS_NEW_VERSION_FOUND) {
        ESP_ERROR_CHECK(nvs_flash_erase());
        ret = nvs_flash_init();
    }
    ESP_ERROR_CHECK(ret);

    // Phase 0 初始化顺序（依赖关系决定顺序，不可随意调换）
    // 1. orb_led_init()      — 最先启动灯光（通电即亮，表示设备"活着"）
    // 2. orb_sensor_init()   — 初始化 BME280 + MPU6050（I2C GPIO8/9）
    // 3. orb_touch_init()    — 启动触摸控制器（3 区域）
    // 4. orb_audio_init()    — 初始化 I2S 麦克风 + 扬声器
    // 5. orb_wifi_init()     — 连接 WiFi（读 NVS 存储的凭证）
    // 6. orb_ble_init()      — 启动 BLE 配网广播（仅首次/未配置时）

    ESP_LOGI(TAG, "Orb 初始化完成，进入待机模式（灯光呼吸中）");

    // 主循环（事件驱动，不用忙等待）
    while (1) {
        vTaskDelay(pdMS_TO_TICKS(1000));
    }
}
