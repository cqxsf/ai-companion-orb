/**
 * @file  orb_ota.h
 * @brief HTTPS dual-partition OTA upgrade component for the AI Companion Orb.
 *
 * Supports background periodic checks, manual triggers, rollback on bad boot,
 * and progress reporting via a callback.
 */

#pragma once

#include "esp_err.h"

#ifdef __cplusplus
extern "C" {
#endif

/* ── Constants ─────────────────────────────────────────────────────────── */

/** Periodic check interval: 1 hour in milliseconds. */
#define OTA_CHECK_INTERVAL_MS   3600000

/** Maximum length of the OTA server URL string (including null terminator). */
#define OTA_URL_MAX_LEN         256

/** Current firmware version string embedded in the binary. */
#define OTA_FIRMWARE_VERSION    "0.1.0"

/* ── Types ──────────────────────────────────────────────────────────────── */

/**
 * @brief OTA state machine states.
 */
typedef enum {
    OTA_STATE_IDLE,         /**< No OTA activity                              */
    OTA_STATE_CHECKING,     /**< Contacting server to check for updates       */
    OTA_STATE_DOWNLOADING,  /**< Downloading new firmware image               */
    OTA_STATE_VERIFYING,    /**< Verifying image integrity and signature      */
    OTA_STATE_REBOOTING,    /**< Reboot pending to activate new firmware      */
    OTA_STATE_FAILED,       /**< OTA attempt failed; staying on current image */
} orb_ota_state_t;

/**
 * @brief Configuration passed to orb_ota_init().
 */
typedef struct {
    char        server_url[OTA_URL_MAX_LEN]; /**< HTTPS URL to the firmware binary */
    uint32_t    check_interval_ms;           /**< Periodic check period (ms).
                                              *   0 = use OTA_CHECK_INTERVAL_MS.  */
    const char *firmware_version;            /**< Currently running version string.
                                              *   NULL = use OTA_FIRMWARE_VERSION. */
    /**
     * PEM-encoded server CA certificate for TLS verification.
     *
     * Required for production use (per CLAUDE.md 安全红线 §5: "OTA 签名验证").
     * Set to NULL to skip server certificate validation — **do not use NULL
     * in production firmware**.
     *
     * Typical usage: embed the PEM file via CMake and pass the embedded
     * symbol here.
     * @code
     *   extern const uint8_t ota_server_cert_pem_start[] asm("_binary_ca_cert_pem_start");
     *   cfg.cert_pem = (const char *)ota_server_cert_pem_start;
     * @endcode
     */
    const char *cert_pem;
} orb_ota_config_t;

/**
 * @brief Progress/state callback invoked from the OTA task.
 *
 * @param state        Current OTA state.
 * @param progress_pct Download progress 0–100 (meaningful only during
 *                     OTA_STATE_DOWNLOADING; 0 for all other states).
 *
 * @note  Keep the callback short; heavy work should be deferred to another
 *        task or queue.
 */
typedef void (*orb_ota_event_cb_t)(orb_ota_state_t state, int progress_pct);

/* ── Public API ─────────────────────────────────────────────────────────── */

/**
 * @brief Initialise the OTA component and start the periodic check timer.
 *
 * Validates the running partition and marks it as confirmed (handles the
 * first boot after a successful OTA).  Starts an esp_timer that fires every
 * @c config->check_interval_ms to trigger background updates.
 *
 * @param config    Component configuration.  Must not be NULL.
 * @param event_cb  Optional callback for state/progress events.  May be NULL.
 * @return ESP_OK on success, ESP_ERR_* on failure.
 */
esp_err_t orb_ota_init(const orb_ota_config_t *config, orb_ota_event_cb_t event_cb);

/**
 * @brief Manually trigger an OTA check and update.
 *
 * Spawns a one-shot FreeRTOS task that contacts the server, downloads the
 * image (if newer), verifies it, writes it to the next OTA partition, and
 * schedules a reboot.  Returns immediately; progress is reported via the
 * callback.
 *
 * @return ESP_OK if the task was created, ESP_ERR_INVALID_STATE if an OTA
 *         is already in progress.
 */
esp_err_t orb_ota_check_and_update(void);

/**
 * @brief Return the current OTA state.
 */
orb_ota_state_t orb_ota_get_state(void);

/**
 * @brief Return the running firmware version string.
 *
 * Returns the version supplied in orb_ota_config_t::firmware_version, or
 * OTA_FIRMWARE_VERSION if none was provided.
 *
 * @return Null-terminated version string.  The pointer is valid for the
 *         lifetime of the component.
 */
const char *orb_ota_get_running_version(void);

/**
 * @brief Stop the periodic timer and release all OTA resources.
 *
 * Safe to call even if orb_ota_init() was never called.
 */
void orb_ota_deinit(void);

#ifdef __cplusplus
}
#endif
