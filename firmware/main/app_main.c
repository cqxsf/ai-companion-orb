/**
 * AI Companion Orb — 主程序入口
 * 
 * 职责：初始化所有组件 + 事件调度
 * 业务逻辑不在此文件中实现
 */

#include <stdio.h>
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "freertos/event_groups.h"
#include "esp_log.h"
#include "nvs_flash.h"

// TODO: 取消注释以下 include（待组件实现后）
// #include "orb_led.h"
// #include "orb_touch.h"
// #include "orb_audio.h"
// #include "orb_wifi.h"
// #include "orb_ble.h"

static const char *TAG = "orb_main";

void app_main(void)
{
    ESP_LOGI(TAG, "=== AI Companion Orb v0.1 ===");
    ESP_LOGI(TAG, "有温度的家庭 IoT");

    // 初始化 NVS（WiFi/BLE 需要）
    esp_err_t ret = nvs_flash_init();
    if (ret == ESP_ERR_NVS_NO_FREE_PAGES || ret == ESP_ERR_NVS_NEW_VERSION_FOUND) {
        ESP_ERROR_CHECK(nvs_flash_erase());
        ret = nvs_flash_init();
    }
    ESP_ERROR_CHECK(ret);

    // TODO: Phase 0 初始化顺序
    // 1. orb_led_init()      — 灯光引擎（最先亮起，表示"活着"）
    // 2. orb_touch_init()    — 触摸检测
    // 3. orb_audio_init()    — 音频系统
    // 4. orb_wifi_init()     — WiFi 连接
    // 5. orb_ble_init()      — BLE 配网（仅首次）

    ESP_LOGI(TAG, "Orb 初始化完成，进入待机模式");

    // 主循环（事件驱动，不用忙等待）
    while (1) {
        vTaskDelay(pdMS_TO_TICKS(1000));
    }
}
