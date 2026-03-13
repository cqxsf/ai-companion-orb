/**
 * @file  orb_ota.c
 * @brief HTTPS dual-partition OTA upgrade component for the AI Companion Orb.
 *
 * Behaviour:
 *  - On init: confirm running partition (handles first boot after OTA).
 *  - Periodic timer fires every check_interval_ms; posts to an update task.
 *  - Manual trigger via orb_ota_check_and_update().
 *  - Downloads image with esp_https_ota, streams progress via callback.
 *  - Writes to the next OTA partition (A/B), marks it pending-verify, reboots.
 *  - If the new firmware fails to call orb_ota_init() on next boot within
 *    the rollback window, esp-idf rolls back automatically.
 */

#include "orb_ota.h"

#include <string.h>
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "esp_log.h"
#include "esp_ota_ops.h"
#include "esp_https_ota.h"
#include "esp_http_client.h"
#include "esp_timer.h"
#include "esp_system.h"

/* ── Module tag ─────────────────────────────────────────────────────────── */

static const char *TAG = "orb_ota";

/* ── Internal state ─────────────────────────────────────────────────────── */

typedef struct {
    orb_ota_config_t    config;
    orb_ota_event_cb_t  event_cb;
    orb_ota_state_t     state;
    esp_timer_handle_t  timer;
    bool                initialized;
} orb_ota_ctx_t;

static orb_ota_ctx_t s_ctx = {
    .state       = OTA_STATE_IDLE,
    .initialized = false,
};

/* ── Helpers ────────────────────────────────────────────────────────────── */

static void notify(orb_ota_state_t state, int pct)
{
    s_ctx.state = state;
    if (s_ctx.event_cb) {
        s_ctx.event_cb(state, pct);
    }
}

/* ── OTA worker task ────────────────────────────────────────────────────── */

static void ota_task(void *arg)
{
    ESP_LOGI(TAG, "OTA check started — server: %s", s_ctx.config.server_url);
    notify(OTA_STATE_CHECKING, 0);

    /* Verify a next partition exists (dual-partition scheme required). */
    const esp_partition_t *update_part = esp_ota_get_next_update_partition(NULL);
    if (update_part == NULL) {
        ESP_LOGE(TAG, "No OTA update partition found — check partition table");
        notify(OTA_STATE_FAILED, 0);
        vTaskDelete(NULL);
        return;
    }
    ESP_LOGI(TAG, "Target partition: %s (offset 0x%08" PRIx32 ")",
             update_part->label, update_part->address);

    /* Configure HTTPS client. */
    esp_http_client_config_t http_cfg = {
        .url               = s_ctx.config.server_url,
        .timeout_ms        = 30000,
        .keep_alive_enable = true,
        .cert_pem          = s_ctx.config.cert_pem,    /* NULL = skip verify (dev only) */
    };

    if (s_ctx.config.cert_pem == NULL) {
        ESP_LOGW(TAG, "cert_pem is NULL — TLS server certificate NOT verified. "
                      "Set orb_ota_config_t.cert_pem in production firmware!");
    }

    esp_https_ota_config_t ota_cfg = {
        .http_config = &http_cfg,
    };

    /* Begin OTA handle. */
    esp_https_ota_handle_t ota_handle = NULL;
    esp_err_t err = esp_https_ota_begin(&ota_cfg, &ota_handle);
    if (err != ESP_OK) {
        ESP_LOGE(TAG, "esp_https_ota_begin failed: %s", esp_err_to_name(err));
        notify(OTA_STATE_FAILED, 0);
        vTaskDelete(NULL);
        return;
    }

    /* Retrieve total image size for progress calculation. */
    int image_size = esp_https_ota_get_image_size(ota_handle);
    ESP_LOGI(TAG, "Firmware image size: %d bytes", image_size);

    notify(OTA_STATE_DOWNLOADING, 0);

    /* Stream download — report progress. */
    int last_pct = -1;
    while (true) {
        err = esp_https_ota_perform(ota_handle);
        if (err == ESP_ERR_HTTPS_OTA_IN_PROGRESS) {
            if (image_size > 0) {
                int downloaded = esp_https_ota_get_image_len_read(ota_handle);
                int pct = (downloaded * 100) / image_size;
                if (pct != last_pct) {
                    last_pct = pct;
                    notify(OTA_STATE_DOWNLOADING, pct);
                    ESP_LOGD(TAG, "OTA progress: %d%%", pct);
                }
            }
        } else {
            break;
        }
    }

    if (err != ESP_OK) {
        ESP_LOGE(TAG, "esp_https_ota_perform failed: %s", esp_err_to_name(err));
        esp_https_ota_abort(ota_handle);
        notify(OTA_STATE_FAILED, 0);
        vTaskDelete(NULL);
        return;
    }

    /* Verify image integrity before finalising. */
    notify(OTA_STATE_VERIFYING, 100);

    if (!esp_https_ota_is_complete_data_received(ota_handle)) {
        ESP_LOGE(TAG, "Incomplete image data received");
        esp_https_ota_abort(ota_handle);
        notify(OTA_STATE_FAILED, 0);
        vTaskDelete(NULL);
        return;
    }

    err = esp_https_ota_finish(ota_handle);
    if (err != ESP_OK) {
        ESP_LOGE(TAG, "esp_https_ota_finish failed: %s", esp_err_to_name(err));
        if (err == ESP_ERR_OTA_VALIDATE_FAILED) {
            ESP_LOGE(TAG, "Image validation failed — possible corruption or bad signature");
        }
        notify(OTA_STATE_FAILED, 0);
        vTaskDelete(NULL);
        return;
    }

    ESP_LOGI(TAG, "OTA image verified — scheduling reboot");
    notify(OTA_STATE_REBOOTING, 100);

    /* Brief delay so the callback can propagate (e.g. flush logs, notify app). */
    vTaskDelay(pdMS_TO_TICKS(1000));

    ESP_LOGI(TAG, "Rebooting into new firmware...");
    esp_restart();

    /* Never reached. */
    vTaskDelete(NULL);
}

/* ── Periodic timer callback ────────────────────────────────────────────── */

static void timer_cb(void *arg)
{
    /* Trigger a check only when idle to avoid stacking updates. */
    if (s_ctx.state == OTA_STATE_IDLE) {
        ESP_LOGI(TAG, "Periodic OTA check triggered");
        esp_err_t err = orb_ota_check_and_update();
        if (err != ESP_OK) {
            ESP_LOGW(TAG, "Could not start OTA task: %s", esp_err_to_name(err));
        }
    } else {
        ESP_LOGD(TAG, "Skipping periodic check — OTA already in state %d", s_ctx.state);
    }
}

/* ── Public API ─────────────────────────────────────────────────────────── */

esp_err_t orb_ota_init(const orb_ota_config_t *config, orb_ota_event_cb_t event_cb)
{
    if (config == NULL) {
        return ESP_ERR_INVALID_ARG;
    }
    if (s_ctx.initialized) {
        ESP_LOGW(TAG, "orb_ota_init() called more than once — ignoring");
        return ESP_OK;
    }

    memcpy(&s_ctx.config, config, sizeof(orb_ota_config_t));
    s_ctx.event_cb = event_cb;
    s_ctx.state    = OTA_STATE_IDLE;

    /* Apply defaults. */
    if (s_ctx.config.check_interval_ms == 0) {
        s_ctx.config.check_interval_ms = OTA_CHECK_INTERVAL_MS;
    }
    if (s_ctx.config.firmware_version == NULL) {
        s_ctx.config.firmware_version = OTA_FIRMWARE_VERSION;
    }

    /*
     * Rollback confirmation: mark the running partition as valid so that
     * esp-idf's rollback watchdog does not revert to the previous image.
     * This is a no-op when the running partition is already confirmed.
     */
    const esp_partition_t *running = esp_ota_get_running_partition();
    esp_ota_img_states_t   ota_state;
    if (esp_ota_get_state_partition(running, &ota_state) == ESP_OK) {
        if (ota_state == ESP_OTA_IMG_PENDING_VERIFY) {
            ESP_LOGI(TAG, "First boot after OTA — marking partition '%s' as valid",
                     running->label);
            ESP_ERROR_CHECK(esp_ota_mark_app_valid_cancel_rollback());
        }
    }

    ESP_LOGI(TAG, "Running firmware version: %s", s_ctx.config.firmware_version);
    ESP_LOGI(TAG, "OTA check interval: %" PRIu32 " ms", s_ctx.config.check_interval_ms);

    /* Start periodic check timer. */
    esp_timer_create_args_t timer_args = {
        .callback        = timer_cb,
        .arg             = NULL,
        .name            = "orb_ota_timer",
        .dispatch_method = ESP_TIMER_TASK,
    };

    esp_err_t err = esp_timer_create(&timer_args, &s_ctx.timer);
    if (err != ESP_OK) {
        ESP_LOGE(TAG, "Failed to create OTA timer: %s", esp_err_to_name(err));
        return err;
    }

    err = esp_timer_start_periodic(s_ctx.timer,
                                   (uint64_t)s_ctx.config.check_interval_ms * 1000ULL);
    if (err != ESP_OK) {
        ESP_LOGE(TAG, "Failed to start OTA timer: %s", esp_err_to_name(err));
        esp_timer_delete(s_ctx.timer);
        s_ctx.timer = NULL;
        return err;
    }

    s_ctx.initialized = true;
    ESP_LOGI(TAG, "OTA component initialised — periodic checks active");
    return ESP_OK;
}

esp_err_t orb_ota_check_and_update(void)
{
    if (!s_ctx.initialized) {
        return ESP_ERR_INVALID_STATE;
    }
    if (s_ctx.state != OTA_STATE_IDLE) {
        ESP_LOGW(TAG, "OTA already in progress (state %d)", s_ctx.state);
        return ESP_ERR_INVALID_STATE;
    }

    BaseType_t ret = xTaskCreate(
        ota_task,
        "orb_ota_task",
        8192,       /* OTA needs a larger stack for TLS and HTTP */
        NULL,
        5,
        NULL
    );

    if (ret != pdPASS) {
        ESP_LOGE(TAG, "Failed to create OTA task");
        return ESP_ERR_NO_MEM;
    }

    return ESP_OK;
}

orb_ota_state_t orb_ota_get_state(void)
{
    return s_ctx.state;
}

const char *orb_ota_get_running_version(void)
{
    if (s_ctx.initialized && s_ctx.config.firmware_version != NULL) {
        return s_ctx.config.firmware_version;
    }
    return OTA_FIRMWARE_VERSION;
}

void orb_ota_deinit(void)
{
    if (!s_ctx.initialized) {
        return;
    }

    if (s_ctx.timer != NULL) {
        esp_timer_stop(s_ctx.timer);
        esp_timer_delete(s_ctx.timer);
        s_ctx.timer = NULL;
    }

    s_ctx.state       = OTA_STATE_IDLE;
    s_ctx.initialized = false;
    ESP_LOGI(TAG, "OTA component deinitialised");
}
