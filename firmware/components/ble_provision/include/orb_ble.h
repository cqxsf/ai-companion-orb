/**
 * @file  orb_ble.h
 * @brief BLE GATT provisioning server for the AI Companion Orb.
 *
 * Exposes a single GATT service that lets the companion App push WiFi
 * credentials to the Orb and receive connection-status notifications.
 */

#pragma once

#include "esp_err.h"

#ifdef __cplusplus
extern "C" {
#endif

/* ── Constants ─────────────────────────────────────────────────────────── */

#define BLE_DEVICE_NAME      "OrbLight"
#define BLE_SERVICE_UUID     0x00FF
#define BLE_CHAR_SSID_UUID   0xFF01
#define BLE_CHAR_PASS_UUID   0xFF02
#define BLE_CHAR_STATUS_UUID 0xFF03

/* ── Types ──────────────────────────────────────────────────────────────── */

typedef enum {
    BLE_STATE_IDLE,
    BLE_STATE_ADVERTISING,
    BLE_STATE_CONNECTED,
    BLE_STATE_PROVISIONED,
} orb_ble_state_t;

/**
 * @brief Callback invoked when both SSID and password have been received.
 *
 * @param ssid      Null-terminated WiFi SSID.
 * @param password  Null-terminated WiFi password.
 */
typedef void (*orb_ble_provision_cb_t)(const char *ssid, const char *password);

/* ── Public API ─────────────────────────────────────────────────────────── */

/**
 * @brief Initialise the Bluedroid stack and register the GATT server.
 *
 * Does not start advertising; call orb_ble_start_advertising() afterwards.
 *
 * @param provision_cb  Called when a complete set of credentials is received.
 * @return ESP_OK on success.
 */
esp_err_t orb_ble_init(orb_ble_provision_cb_t provision_cb);

/** @brief Begin GAP advertising so the App can discover the Orb. */
esp_err_t orb_ble_start_advertising(void);

/** @brief Stop GAP advertising. */
esp_err_t orb_ble_stop_advertising(void);

/**
 * @brief Send a JSON status string via the Status NOTIFY characteristic.
 *
 * Example values: "{\"status\":\"connecting\"}", "{\"status\":\"connected\",\"ip\":\"192.168.1.42\"}"
 *
 * @param status_json  Null-terminated JSON string (≤ 512 bytes).
 * @return ESP_OK on success, ESP_ERR_INVALID_STATE if no client is subscribed.
 */
esp_err_t orb_ble_send_status(const char *status_json);

/** @brief Return the current BLE provisioning state. */
orb_ble_state_t orb_ble_get_state(void);

/** @brief Stop advertising, disconnect any client, and free BLE resources. */
void orb_ble_deinit(void);

#ifdef __cplusplus
}
#endif
