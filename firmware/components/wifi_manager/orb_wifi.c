/**
 * @file  orb_wifi.c
 * @brief WiFi STA manager for the AI Companion Orb.
 *
 * Architecture
 * ─────────────
 *   • Uses the default ESP event loop for WIFI_EVENT and IP_EVENT.
 *   • A binary semaphore (s_conn_sem) lets orb_wifi_connect() block until
 *     the connection either succeeds or exhausts all retries.
 *   • Retry count is reset to zero on every fresh orb_wifi_connect() call.
 *   • Credentials are stored in NVS namespace "orb_wifi" under keys "ssid"
 *     and "pass".  On init, any stored credentials trigger an automatic
 *     connection attempt.
 */

#include <string.h>
#include "freertos/FreeRTOS.h"
#include "freertos/semphr.h"
#include "esp_wifi.h"
#include "esp_event.h"
#include "esp_log.h"
#include "esp_netif.h"
#include "nvs_flash.h"
#include "nvs.h"

#include "orb_wifi.h"

/* ── Module-private state ───────────────────────────────────────────────── */

static const char *TAG = "orb_wifi";

#define NVS_NAMESPACE "orb_wifi"
#define NVS_KEY_SSID  "ssid"
#define NVS_KEY_PASS  "pass"

static orb_wifi_event_cb_t s_event_cb    = NULL;
static orb_wifi_state_t    s_state       = WIFI_STATE_DISCONNECTED;
static int                 s_retry_count = 0;
static SemaphoreHandle_t   s_conn_sem    = NULL;
static esp_netif_t        *s_netif_sta   = NULL;
static bool                s_initialised = false;

/* ── Internal helpers ───────────────────────────────────────────────────── */

static void set_state(orb_wifi_state_t new_state, const char *ip_str)
{
    s_state = new_state;
    if (s_event_cb) {
        s_event_cb(new_state, ip_str);
    }
}

/* ── Event handler ──────────────────────────────────────────────────────── */

static void wifi_event_handler(void *arg, esp_event_base_t event_base,
                               int32_t event_id, void *event_data)
{
    if (event_base == WIFI_EVENT) {
        switch (event_id) {
        case WIFI_EVENT_STA_START:
            ESP_LOGI(TAG, "STA started - connecting");
            set_state(WIFI_STATE_CONNECTING, NULL);
            esp_wifi_connect();
            break;

        case WIFI_EVENT_STA_DISCONNECTED: {
            wifi_event_sta_disconnected_t *disc =
                (wifi_event_sta_disconnected_t *)event_data;
            ESP_LOGW(TAG, "Disconnected (reason %d), retry %d/%d",
                     disc->reason, s_retry_count + 1, WIFI_RETRY_MAX);

            if (s_retry_count < WIFI_RETRY_MAX) {
                s_retry_count++;
                set_state(WIFI_STATE_CONNECTING, NULL);
                esp_wifi_connect();
            } else {
                ESP_LOGE(TAG, "Max retries reached - giving up");
                set_state(WIFI_STATE_FAILED, NULL);
                /* Unblock orb_wifi_connect() if it is waiting */
                if (s_conn_sem) {
                    xSemaphoreGive(s_conn_sem);
                }
            }
            break;
        }

        case WIFI_EVENT_STA_CONNECTED:
            ESP_LOGI(TAG, "Associated with AP - waiting for IP");
            break;

        default:
            break;
        }
    } else if (event_base == IP_EVENT && event_id == IP_EVENT_STA_GOT_IP) {
        ip_event_got_ip_t *ev = (ip_event_got_ip_t *)event_data;
        char ip_str[16];
        snprintf(ip_str, sizeof(ip_str), IPSTR, IP2STR(&ev->ip_info.ip));
        ESP_LOGI(TAG, "Got IP: %s", ip_str);
        s_retry_count = 0;
        set_state(WIFI_STATE_CONNECTED, ip_str);
        if (s_conn_sem) {
            xSemaphoreGive(s_conn_sem);
        }
    }
}

/* ── Public API ─────────────────────────────────────────────────────────── */

esp_err_t orb_wifi_init(orb_wifi_event_cb_t event_cb)
{
    if (s_initialised) {
        ESP_LOGW(TAG, "Already initialised");
        return ESP_OK;
    }

    s_event_cb = event_cb;

    /* Semaphore used to block callers in orb_wifi_connect() */
    s_conn_sem = xSemaphoreCreateBinary();
    if (!s_conn_sem) {
        ESP_LOGE(TAG, "Failed to create connection semaphore");
        return ESP_ERR_NO_MEM;
    }

    ESP_ERROR_CHECK(esp_netif_init());
    s_netif_sta = esp_netif_create_default_wifi_sta();

    wifi_init_config_t cfg = WIFI_INIT_CONFIG_DEFAULT();
    ESP_ERROR_CHECK(esp_wifi_init(&cfg));

    ESP_ERROR_CHECK(esp_event_handler_instance_register(
        WIFI_EVENT, ESP_EVENT_ANY_ID, &wifi_event_handler, NULL, NULL));
    ESP_ERROR_CHECK(esp_event_handler_instance_register(
        IP_EVENT, IP_EVENT_STA_GOT_IP, &wifi_event_handler, NULL, NULL));

    ESP_ERROR_CHECK(esp_wifi_set_mode(WIFI_MODE_STA));
    ESP_ERROR_CHECK(esp_wifi_start());

    s_initialised = true;
    ESP_LOGI(TAG, "Initialised");

    /* Auto-connect if credentials are already stored */
    orb_wifi_config_t saved = {0};
    if (orb_wifi_load_config(&saved) == ESP_OK && saved.ssid[0] != '\0') {
        ESP_LOGI(TAG, "Found saved credentials - connecting to \"%s\"", saved.ssid);
        orb_wifi_connect(&saved);
    }

    return ESP_OK;
}

esp_err_t orb_wifi_connect(const orb_wifi_config_t *config)
{
    if (!s_initialised) {
        ESP_LOGE(TAG, "Not initialised");
        return ESP_ERR_INVALID_STATE;
    }
    if (!config || config->ssid[0] == '\0') {
        return ESP_ERR_INVALID_ARG;
    }

    /* Disconnect first if already associated */
    if (s_state == WIFI_STATE_CONNECTED || s_state == WIFI_STATE_CONNECTING) {
        esp_wifi_disconnect();
    }

    s_retry_count = 0;

    wifi_config_t wifi_cfg = {0};
    strlcpy((char *)wifi_cfg.sta.ssid,     config->ssid,     sizeof(wifi_cfg.sta.ssid));
    strlcpy((char *)wifi_cfg.sta.password, config->password, sizeof(wifi_cfg.sta.password));
    wifi_cfg.sta.threshold.authmode = WIFI_AUTH_WPA2_PSK;
    wifi_cfg.sta.pmf_cfg.capable    = true;
    wifi_cfg.sta.pmf_cfg.required   = false;

    ESP_ERROR_CHECK(esp_wifi_set_config(WIFI_IF_STA, &wifi_cfg));

    /* Drain any leftover semaphore token before waiting */
    xSemaphoreTake(s_conn_sem, 0);

    esp_err_t ret = esp_wifi_connect();
    if (ret != ESP_OK) {
        ESP_LOGE(TAG, "esp_wifi_connect failed: %s", esp_err_to_name(ret));
        return ret;
    }

    set_state(WIFI_STATE_CONNECTING, NULL);

    /* Block until connected or failed (timeout = WIFI_CONNECT_TIMEOUT_MS) */
    TickType_t ticks = pdMS_TO_TICKS(WIFI_CONNECT_TIMEOUT_MS);
    if (xSemaphoreTake(s_conn_sem, ticks) == pdFALSE) {
        ESP_LOGE(TAG, "Connection timed out");
        set_state(WIFI_STATE_FAILED, NULL);
        return ESP_ERR_TIMEOUT;
    }

    if (s_state == WIFI_STATE_CONNECTED) {
        orb_wifi_save_config(config);
        return ESP_OK;
    }

    return ESP_FAIL;
}

esp_err_t orb_wifi_disconnect(void)
{
    if (!s_initialised) {
        return ESP_ERR_INVALID_STATE;
    }
    esp_err_t ret = esp_wifi_disconnect();
    if (ret == ESP_OK) {
        set_state(WIFI_STATE_DISCONNECTED, NULL);
    }
    return ret;
}

orb_wifi_state_t orb_wifi_get_state(void)
{
    return s_state;
}

bool orb_wifi_is_connected(void)
{
    return s_state == WIFI_STATE_CONNECTED;
}

void orb_wifi_deinit(void)
{
    if (!s_initialised) {
        return;
    }

    esp_event_handler_unregister(WIFI_EVENT, ESP_EVENT_ANY_ID, &wifi_event_handler);
    esp_event_handler_unregister(IP_EVENT, IP_EVENT_STA_GOT_IP, &wifi_event_handler);

    esp_wifi_stop();
    esp_wifi_deinit();

    if (s_netif_sta) {
        esp_netif_destroy_default_wifi(s_netif_sta);
        s_netif_sta = NULL;
    }

    if (s_conn_sem) {
        vSemaphoreDelete(s_conn_sem);
        s_conn_sem = NULL;
    }

    s_state       = WIFI_STATE_DISCONNECTED;
    s_initialised = false;
    ESP_LOGI(TAG, "Deinitialised");
}

esp_err_t orb_wifi_save_config(const orb_wifi_config_t *config)
{
    if (!config) {
        return ESP_ERR_INVALID_ARG;
    }

    nvs_handle_t handle;
    esp_err_t ret = nvs_open(NVS_NAMESPACE, NVS_READWRITE, &handle);
    if (ret != ESP_OK) {
        ESP_LOGE(TAG, "nvs_open failed: %s", esp_err_to_name(ret));
        return ret;
    }

    ret = nvs_set_str(handle, NVS_KEY_SSID, config->ssid);
    if (ret == ESP_OK) {
        ret = nvs_set_str(handle, NVS_KEY_PASS, config->password);
    }
    if (ret == ESP_OK) {
        ret = nvs_commit(handle);
    }

    nvs_close(handle);

    if (ret == ESP_OK) {
        ESP_LOGI(TAG, "Credentials saved (ssid=\"%s\")", config->ssid);
    } else {
        ESP_LOGE(TAG, "Failed to save credentials: %s", esp_err_to_name(ret));
    }
    return ret;
}

esp_err_t orb_wifi_load_config(orb_wifi_config_t *config)
{
    if (!config) {
        return ESP_ERR_INVALID_ARG;
    }

    nvs_handle_t handle;
    esp_err_t ret = nvs_open(NVS_NAMESPACE, NVS_READONLY, &handle);
    if (ret != ESP_OK) {
        return ret;
    }

    size_t ssid_len = WIFI_SSID_MAX_LEN;
    size_t pass_len = WIFI_PASS_MAX_LEN;

    ret = nvs_get_str(handle, NVS_KEY_SSID, config->ssid, &ssid_len);
    if (ret == ESP_OK) {
        ret = nvs_get_str(handle, NVS_KEY_PASS, config->password, &pass_len);
    }

    nvs_close(handle);

    if (ret == ESP_OK) {
        ESP_LOGI(TAG, "Credentials loaded (ssid=\"%s\")", config->ssid);
    }
    return ret;
}
