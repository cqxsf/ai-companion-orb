/**
 * @file  orb_wifi.h
 * @brief WiFi STA manager for the AI Companion Orb.
 *
 * Handles connection, auto-reconnect, and NVS credential persistence.
 */

#pragma once

#include <stdbool.h>
#include "esp_err.h"

#ifdef __cplusplus
extern "C" {
#endif

/* ── Constants ─────────────────────────────────────────────────────────── */

#define WIFI_SSID_MAX_LEN       32
#define WIFI_PASS_MAX_LEN       64
#define WIFI_RETRY_MAX          5
#define WIFI_CONNECT_TIMEOUT_MS 30000

/* ── Types ──────────────────────────────────────────────────────────────── */

typedef enum {
    WIFI_STATE_DISCONNECTED,
    WIFI_STATE_CONNECTING,
    WIFI_STATE_CONNECTED,
    WIFI_STATE_FAILED,
} orb_wifi_state_t;

typedef struct {
    char ssid[WIFI_SSID_MAX_LEN];
    char password[WIFI_PASS_MAX_LEN];
} orb_wifi_config_t;

/**
 * @brief Event callback invoked on every WiFi state change.
 *
 * @param state   New connection state.
 * @param ip_str  Dotted-decimal IP string when state == WIFI_STATE_CONNECTED,
 *                NULL otherwise.
 */
typedef void (*orb_wifi_event_cb_t)(orb_wifi_state_t state, const char *ip_str);

/* ── Public API ─────────────────────────────────────────────────────────── */

/**
 * @brief Initialise the WiFi subsystem and register the event callback.
 *
 * Must be called once before any other orb_wifi_* function.  If NVS already
 * holds valid credentials the component connects automatically.
 *
 * @param event_cb  State-change callback (may be NULL).
 * @return ESP_OK on success.
 */
esp_err_t orb_wifi_init(orb_wifi_event_cb_t event_cb);

/**
 * @brief Connect using the supplied credentials.
 *
 * Saves the credentials to NVS on success.
 *
 * @param config  SSID and password.
 * @return ESP_OK if the connection attempt was started successfully.
 */
esp_err_t orb_wifi_connect(const orb_wifi_config_t *config);

/** @brief Disconnect from the current AP. */
esp_err_t orb_wifi_disconnect(void);

/** @brief Return the current connection state. */
orb_wifi_state_t orb_wifi_get_state(void);

/** @brief Convenience: true when state == WIFI_STATE_CONNECTED. */
bool orb_wifi_is_connected(void);

/** @brief Tear down WiFi and free all resources. */
void orb_wifi_deinit(void);

/**
 * @brief Persist WiFi credentials to NVS namespace "orb_wifi".
 *
 * @param config  Credentials to save.
 * @return ESP_OK on success.
 */
esp_err_t orb_wifi_save_config(const orb_wifi_config_t *config);

/**
 * @brief Load WiFi credentials previously saved by orb_wifi_save_config().
 *
 * @param config  Output buffer for the loaded credentials.
 * @return ESP_OK if credentials were found and loaded, ESP_ERR_NVS_NOT_FOUND
 *         if no credentials are stored yet.
 */
esp_err_t orb_wifi_load_config(orb_wifi_config_t *config);

#ifdef __cplusplus
}
#endif
