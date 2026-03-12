/**
 * AI Companion Orb — 主程序入口
 *
 * 职责：初始化所有组件 + 事件调度
 * 业务逻辑不在此文件中实现
 */

#include <stdio.h>
#include <string.h>
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "esp_log.h"
#include "nvs_flash.h"

#include "orb_led.h"
#include "orb_touch.h"
#include "orb_audio.h"
#include "orb_wifi.h"
#include "orb_ble.h"
#include "orb_ota.h"

static const char *TAG = "orb_main";

/* ── Default OTA server URL — must be overridden before production build ── */
#ifndef OTA_SERVER_URL
#define OTA_SERVER_URL "https://ota.example.com/orb/firmware.bin"
#endif

/* ── Component callbacks ────────────────────────────────────────────────── */

static void on_touch_event(const orb_touch_event_t *event)
{
    ESP_LOGI(TAG, "Touch: gesture=%d area=%.2f duration=%" PRIu32 "ms",
             event->gesture, event->touch_area, event->duration_ms);

    switch (event->gesture) {
        case TOUCH_TAP:
            orb_led_set_mood(ORB_MOOD_TOUCH_RESPONSE);
            break;
        case TOUCH_LONG:
            /* Long press → enter conversation / listening mode */
            orb_led_set_mood(ORB_MOOD_LISTENING);
            break;
        case TOUCH_EMBRACE:
            /* Embrace → calming comfort animation */
            orb_led_set_mood(ORB_MOOD_CALM);
            break;
        case TOUCH_DOUBLE_TAP:
            /* Double-tap → pause / resume, return to idle */
            orb_led_set_mood(ORB_MOOD_IDLE);
            break;
        default:
            break;
    }
}

static void on_wifi_event(orb_wifi_state_t state, const char *ip)
{
    switch (state) {
        case WIFI_STATE_CONNECTING:
            ESP_LOGI(TAG, "WiFi connecting...");
            orb_led_set_mood(ORB_MOOD_THINKING);
            break;
        case WIFI_STATE_CONNECTED:
            ESP_LOGI(TAG, "WiFi connected — IP: %s", ip ? ip : "unknown");
            orb_led_set_mood(ORB_MOOD_OK);
            break;
        case WIFI_STATE_DISCONNECTED:
            ESP_LOGW(TAG, "WiFi disconnected");
            orb_led_set_mood(ORB_MOOD_IDLE);
            break;
        case WIFI_STATE_FAILED:
            ESP_LOGE(TAG, "WiFi connection failed");
            orb_led_set_mood(ORB_MOOD_ALERT);
            break;
        default:
            break;
    }
}

static void on_ble_provision(const char *ssid, const char *password)
{
    ESP_LOGI(TAG, "BLE provisioning received — SSID: %s", ssid);

    orb_wifi_config_t wifi_cfg;
    memset(&wifi_cfg, 0, sizeof(wifi_cfg));
    strlcpy(wifi_cfg.ssid,     ssid,     sizeof(wifi_cfg.ssid));
    strlcpy(wifi_cfg.password, password, sizeof(wifi_cfg.password));

    esp_err_t err = orb_wifi_connect(&wifi_cfg);
    if (err != ESP_OK) {
        ESP_LOGE(TAG, "orb_wifi_connect failed: %s", esp_err_to_name(err));
    }
}

static void on_audio_data(const int16_t *samples, size_t count)
{
    /* Hand off to the backend WebSocket pipeline (not yet implemented). */
    ESP_LOGD(TAG, "Audio chunk received: %zu samples", count);
}

static void on_ota_event(orb_ota_state_t state, int pct)
{
    switch (state) {
        case OTA_STATE_CHECKING:
            ESP_LOGI(TAG, "OTA: checking for update");
            break;
        case OTA_STATE_DOWNLOADING:
            ESP_LOGI(TAG, "OTA: downloading %d%%", pct);
            orb_led_set_mood(ORB_MOOD_THINKING);
            break;
        case OTA_STATE_VERIFYING:
            ESP_LOGI(TAG, "OTA: verifying image");
            break;
        case OTA_STATE_REBOOTING:
            ESP_LOGI(TAG, "OTA: update complete — rebooting");
            orb_led_set_mood(ORB_MOOD_OK);
            break;
        case OTA_STATE_FAILED:
            ESP_LOGE(TAG, "OTA: update failed");
            orb_led_set_mood(ORB_MOOD_ALERT);
            break;
        default:
            break;
    }
}

/* ── Entry point ────────────────────────────────────────────────────────── */

void app_main(void)
{
    /* ── NVS flash (required by WiFi, BLE, OTA) ─────────────────────── */
    esp_err_t ret = nvs_flash_init();
    if (ret == ESP_ERR_NVS_NO_FREE_PAGES || ret == ESP_ERR_NVS_NEW_VERSION_FOUND) {
        ESP_ERROR_CHECK(nvs_flash_erase());
        ret = nvs_flash_init();
    }
    ESP_ERROR_CHECK(ret);

    /* ── LED engine — first up so the Orb looks "alive" immediately ──── */
    orb_led_config_t led_cfg = {
        .gpio_num  = ORB_LED_DEFAULT_GPIO,
        .led_count = ORB_LED_COUNT,
    };
    ESP_ERROR_CHECK(orb_led_init(&led_cfg));
    ESP_ERROR_CHECK(orb_led_set_mood(ORB_MOOD_IDLE));

    /* ── Touch sensor ───────────────────────────────────────────────── */
    orb_touch_config_t touch_cfg = {
        .callback             = on_touch_event,
        .long_press_ms        = 1500,
        .embrace_ms           = 3000,
        .double_tap_window_ms = 300,
    };
    ESP_ERROR_CHECK(orb_touch_init(&touch_cfg));

    /* ── Audio — I2S mic + speaker, default GPIO assignments ─────────── */
    orb_audio_config_t audio_cfg = {
        .mic_bck_io  = AUDIO_MIC_BCK_GPIO,
        .mic_ws_io   = AUDIO_MIC_WS_GPIO,
        .mic_data_io = AUDIO_MIC_DATA_GPIO,
        .spk_bck_io  = AUDIO_SPK_BCK_GPIO,
        .spk_ws_io   = AUDIO_SPK_WS_GPIO,
        .spk_data_io = AUDIO_SPK_DATA_GPIO,
    };
    ESP_ERROR_CHECK(orb_audio_init(&audio_cfg));

    /* ── WiFi manager — auto-connects if NVS credentials exist ──────── */
    ESP_ERROR_CHECK(orb_wifi_init(on_wifi_event));

    /* ── BLE provisioning — advertise so App can push WiFi credentials ─ */
    ESP_ERROR_CHECK(orb_ble_init(on_ble_provision));
    if (!orb_wifi_is_connected()) {
        ESP_LOGI(TAG, "No saved WiFi config — starting BLE advertising");
        ESP_ERROR_CHECK(orb_ble_start_advertising());
        orb_led_set_mood(ORB_MOOD_CALM); /* Blue breathing = waiting for setup */
    }

    /* ── OTA — periodic background update checks ─────────────────────── */
    orb_ota_config_t ota_cfg = {
        .check_interval_ms = OTA_CHECK_INTERVAL_MS,
        .firmware_version  = OTA_FIRMWARE_VERSION,
        /* cert_pem: set to embedded PEM before production deployment.
         * See orb_ota_config_t.cert_pem documentation in orb_ota.h. */
        .cert_pem          = NULL,
    };
    strlcpy(ota_cfg.server_url, OTA_SERVER_URL, sizeof(ota_cfg.server_url));
    ESP_ERROR_CHECK(orb_ota_init(&ota_cfg, on_ota_event));

    /* ── Ready ───────────────────────────────────────────────────────── */
    ESP_LOGI(TAG, "=== AI Companion Orb v%s ===", orb_ota_get_running_version());
    ESP_LOGI(TAG, "有温度的家庭 IoT — 设备就绪");

    /* Main loop — components are event-driven; nothing to poll here. */
    while (1) {
        vTaskDelay(pdMS_TO_TICKS(1000));
    }
}

