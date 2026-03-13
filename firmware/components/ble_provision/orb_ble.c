/**
 * @file  orb_ble.c
 * @brief BLE GATT provisioning server for the AI Companion Orb.
 *
 * Architecture
 * ─────────────
 *   • Uses the ESP-IDF Bluedroid stack (Classic BT disabled, BLE only).
 *   • A single GATT service (UUID 0x00FF) exposes three characteristics:
 *       – SSID   (0xFF01): Write-only; stores the WiFi SSID.
 *       – Pass   (0xFF02): Write-only; stores the WiFi password.
 *       – Status (0xFF03): Notify; the App subscribes and receives JSON
 *                          status strings such as {"status":"connected"}.
 *   • When both SSID and password have been received the provision_cb is
 *     called and the state advances to BLE_STATE_PROVISIONED.
 *   • The CCCD (Client Characteristic Configuration Descriptor) on the
 *     Status characteristic is handled manually so notifications are only
 *     sent when the client has enabled them.
 *
 * GATT attribute table layout (index → attribute)
 * ─────────────────────────────────────────────────
 *   IDX_SVC            : Primary service declaration
 *   IDX_CHAR_SSID      : SSID characteristic declaration
 *   IDX_CHAR_SSID_VAL  : SSID characteristic value
 *   IDX_CHAR_PASS      : Password characteristic declaration
 *   IDX_CHAR_PASS_VAL  : Password characteristic value
 *   IDX_CHAR_STATUS    : Status characteristic declaration
 *   IDX_CHAR_STATUS_VAL: Status characteristic value
 *   IDX_CHAR_STATUS_CCC: Status CCCD
 */

#include <string.h>
#include <stdio.h>
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "esp_log.h"
#include "esp_bt.h"
#include "esp_bt_main.h"
#include "esp_gap_ble_api.h"
#include "esp_gatts_api.h"
#include "esp_gatt_common_api.h"

#include "orb_ble.h"

/* ── Compile-time checks ────────────────────────────────────────────────── */

#define GATTS_APP_ID      0
#define GATTS_NUM_HANDLES 8   /* 1 svc + 2×(decl+val) + 1×(decl+val+cccd) */

#define MAX_SSID_LEN      32
#define MAX_PASS_LEN      64
#define MAX_STATUS_LEN    128

/* ── Module-private state ───────────────────────────────────────────────── */

static const char *TAG = "orb_ble";

typedef enum {
    IDX_SVC = 0,
    IDX_CHAR_SSID,
    IDX_CHAR_SSID_VAL,
    IDX_CHAR_PASS,
    IDX_CHAR_PASS_VAL,
    IDX_CHAR_STATUS,
    IDX_CHAR_STATUS_VAL,
    IDX_CHAR_STATUS_CCC,
    IDX_MAX,
} attr_idx_t;

static uint16_t            s_handle_table[IDX_MAX];
static uint16_t            s_gatts_if    = ESP_GATT_IF_NONE;
static uint16_t            s_conn_id     = 0xFFFF;
static bool                s_notify_enabled = false;
static orb_ble_state_t     s_state       = BLE_STATE_IDLE;
static orb_ble_provision_cb_t s_provision_cb = NULL;
static bool                s_initialised = false;

/* Scratch buffers for received credentials */
static char s_ssid[MAX_SSID_LEN + 1] = {0};
static char s_pass[MAX_PASS_LEN + 1] = {0};
static bool s_has_ssid = false;
static bool s_has_pass = false;

/* ── UUIDs ──────────────────────────────────────────────────────────────── */

static const uint16_t PRIMARY_SERVICE_UUID     = ESP_GATT_UUID_PRI_SERVICE;
static const uint16_t CHAR_DECL_UUID           = ESP_GATT_UUID_CHAR_DECLARE;
static const uint16_t CHAR_CFG_UUID            = ESP_GATT_UUID_CHAR_CLIENT_CONFIG;

static const uint16_t SVC_UUID                 = BLE_SERVICE_UUID;
static const uint16_t CHAR_SSID_UUID           = BLE_CHAR_SSID_UUID;
static const uint16_t CHAR_PASS_UUID           = BLE_CHAR_PASS_UUID;
static const uint16_t CHAR_STATUS_UUID         = BLE_CHAR_STATUS_UUID;

static const uint8_t PROP_WRITE                = ESP_GATT_CHAR_PROP_BIT_WRITE;
static const uint8_t PROP_NOTIFY               = ESP_GATT_CHAR_PROP_BIT_NOTIFY;

/* ── GATT attribute table ───────────────────────────────────────────────── */

static const esp_gatts_attr_db_t s_gatt_db[IDX_MAX] = {
    /* Primary service */
    [IDX_SVC] = {
        {ESP_GATT_AUTO_RSP},
        {ESP_UUID_LEN_16, (uint8_t *)&PRIMARY_SERVICE_UUID,
         ESP_GATT_PERM_READ, sizeof(SVC_UUID), sizeof(SVC_UUID),
         (uint8_t *)&SVC_UUID}
    },

    /* SSID: characteristic declaration */
    [IDX_CHAR_SSID] = {
        {ESP_GATT_AUTO_RSP},
        {ESP_UUID_LEN_16, (uint8_t *)&CHAR_DECL_UUID,
         ESP_GATT_PERM_READ, sizeof(PROP_WRITE), sizeof(PROP_WRITE),
         (uint8_t *)&PROP_WRITE}
    },
    /* SSID: characteristic value */
    [IDX_CHAR_SSID_VAL] = {
        {ESP_GATT_AUTO_RSP},
        {ESP_UUID_LEN_16, (uint8_t *)&CHAR_SSID_UUID,
         ESP_GATT_PERM_WRITE, MAX_SSID_LEN, 0, NULL}
    },

    /* Password: characteristic declaration */
    [IDX_CHAR_PASS] = {
        {ESP_GATT_AUTO_RSP},
        {ESP_UUID_LEN_16, (uint8_t *)&CHAR_DECL_UUID,
         ESP_GATT_PERM_READ, sizeof(PROP_WRITE), sizeof(PROP_WRITE),
         (uint8_t *)&PROP_WRITE}
    },
    /* Password: characteristic value */
    [IDX_CHAR_PASS_VAL] = {
        {ESP_GATT_AUTO_RSP},
        {ESP_UUID_LEN_16, (uint8_t *)&CHAR_PASS_UUID,
         ESP_GATT_PERM_WRITE, MAX_PASS_LEN, 0, NULL}
    },

    /* Status: characteristic declaration */
    [IDX_CHAR_STATUS] = {
        {ESP_GATT_AUTO_RSP},
        {ESP_UUID_LEN_16, (uint8_t *)&CHAR_DECL_UUID,
         ESP_GATT_PERM_READ, sizeof(PROP_NOTIFY), sizeof(PROP_NOTIFY),
         (uint8_t *)&PROP_NOTIFY}
    },
    /* Status: characteristic value (no direct read/write; notify only) */
    [IDX_CHAR_STATUS_VAL] = {
        {ESP_GATT_AUTO_RSP},
        {ESP_UUID_LEN_16, (uint8_t *)&CHAR_STATUS_UUID,
         ESP_GATT_PERM_READ, MAX_STATUS_LEN, 0, NULL}
    },
    /* Status: CCCD */
    [IDX_CHAR_STATUS_CCC] = {
        {ESP_GATT_AUTO_RSP},
        {ESP_UUID_LEN_16, (uint8_t *)&CHAR_CFG_UUID,
         ESP_GATT_PERM_READ | ESP_GATT_PERM_WRITE,
         sizeof(uint16_t), sizeof(uint16_t),
         (uint8_t *)"\x00\x00"}
    },
};

/* ── GAP advertising data ───────────────────────────────────────────────── */

static esp_ble_adv_data_t s_adv_data = {
    .set_scan_rsp        = false,
    .include_name        = true,
    .include_txpower     = false,
    .min_interval        = 0x0006,  /* 7.5 ms */
    .max_interval        = 0x0010,  /* 20 ms  */
    .appearance          = 0x0000,
    .manufacturer_len    = 0,
    .p_manufacturer_data = NULL,
    .service_data_len    = 0,
    .p_service_data      = NULL,
    .service_uuid_len    = 0,
    .p_service_uuid      = NULL,
    .flag = (ESP_BLE_ADV_FLAG_GEN_DISC | ESP_BLE_ADV_FLAG_BREDR_NOT_SPT),
};

static esp_ble_adv_params_t s_adv_params = {
    .adv_int_min       = 0x0020,  /* 20 ms */
    .adv_int_max       = 0x0040,  /* 40 ms */
    .adv_type          = ADV_TYPE_IND,
    .own_addr_type     = BLE_ADDR_TYPE_PUBLIC,
    .channel_map       = ADV_CHNL_ALL,
    .adv_filter_policy = ADV_FILTER_ALLOW_SCAN_ANY_CON_ANY,
};

/* ── Internal helpers ───────────────────────────────────────────────────── */

static void try_provision(void)
{
    if (s_has_ssid && s_has_pass && s_provision_cb) {
        ESP_LOGI(TAG, "Both credentials received – invoking provision callback");
        s_state = BLE_STATE_PROVISIONED;
        s_provision_cb(s_ssid, s_pass);
    }
}

/* ── GAP event handler ──────────────────────────────────────────────────── */

static void gap_event_handler(esp_gap_ble_cb_event_t event,
                               esp_ble_gap_cb_param_t *param)
{
    switch (event) {
    case ESP_GAP_BLE_ADV_DATA_SET_COMPLETE_EVT:
        ESP_LOGI(TAG, "Adv data set – starting advertising");
        esp_ble_gap_start_advertising(&s_adv_params);
        break;

    case ESP_GAP_BLE_ADV_START_COMPLETE_EVT:
        if (param->adv_start_cmpl.status == ESP_BT_STATUS_SUCCESS) {
            ESP_LOGI(TAG, "Advertising started");
            s_state = BLE_STATE_ADVERTISING;
        } else {
            ESP_LOGE(TAG, "Advertising start failed");
        }
        break;

    case ESP_GAP_BLE_ADV_STOP_COMPLETE_EVT:
        if (param->adv_stop_cmpl.status == ESP_BT_STATUS_SUCCESS) {
            ESP_LOGI(TAG, "Advertising stopped");
            if (s_state == BLE_STATE_ADVERTISING) {
                s_state = BLE_STATE_IDLE;
            }
        }
        break;

    default:
        break;
    }
}

/* ── GATTS event handler ────────────────────────────────────────────────── */

static void gatts_event_handler(esp_gatts_cb_event_t event,
                                 esp_gatt_if_t gatts_if,
                                 esp_ble_gatts_cb_param_t *param)
{
    switch (event) {
    case ESP_GATTS_REG_EVT:
        if (param->reg.status == ESP_GATT_OK) {
            s_gatts_if = gatts_if;
            ESP_LOGI(TAG, "GATTS registered, app_id %d", param->reg.app_id);
            esp_ble_gap_set_device_name(BLE_DEVICE_NAME);
            esp_ble_gap_config_adv_data(&s_adv_data);
            esp_ble_gatts_create_attr_tab(s_gatt_db, gatts_if,
                                          IDX_MAX, 0);
        } else {
            ESP_LOGE(TAG, "GATTS register failed, status %d", param->reg.status);
        }
        break;

    case ESP_GATTS_CREAT_ATTR_TAB_EVT:
        if (param->add_attr_tab.status == ESP_GATT_OK &&
            param->add_attr_tab.num_handle == IDX_MAX) {
            memcpy(s_handle_table, param->add_attr_tab.handles,
                   sizeof(s_handle_table));
            ESP_LOGI(TAG, "Attribute table created, starting service");
            esp_ble_gatts_start_service(s_handle_table[IDX_SVC]);
        } else {
            ESP_LOGE(TAG, "Attribute table creation failed (status %d, handles %d)",
                     param->add_attr_tab.status,
                     param->add_attr_tab.num_handle);
        }
        break;

    case ESP_GATTS_CONNECT_EVT:
        s_conn_id = param->connect.conn_id;
        s_state   = BLE_STATE_CONNECTED;
        ESP_LOGI(TAG, "Client connected, conn_id=%d", s_conn_id);
        /* Stop advertising once a client connects */
        esp_ble_gap_stop_advertising();
        break;

    case ESP_GATTS_DISCONNECT_EVT:
        ESP_LOGI(TAG, "Client disconnected, reason=0x%02x",
                 param->disconnect.reason);
        s_conn_id        = 0xFFFF;
        s_notify_enabled = false;
        if (s_state != BLE_STATE_PROVISIONED) {
            s_state = BLE_STATE_IDLE;
            /* Re-advertise so the App can reconnect on failure */
            esp_ble_gap_start_advertising(&s_adv_params);
        }
        break;

    case ESP_GATTS_WRITE_EVT: {
        uint16_t handle = param->write.handle;
        uint16_t len    = param->write.len;
        uint8_t *val    = param->write.value;

        if (handle == s_handle_table[IDX_CHAR_SSID_VAL]) {
            size_t copy_len = (len < MAX_SSID_LEN) ? len : MAX_SSID_LEN;
            memcpy(s_ssid, val, copy_len);
            s_ssid[copy_len] = '\0';
            s_has_ssid = true;
            ESP_LOGI(TAG, "SSID written: \"%s\"", s_ssid);
            try_provision();

        } else if (handle == s_handle_table[IDX_CHAR_PASS_VAL]) {
            size_t copy_len = (len < MAX_PASS_LEN) ? len : MAX_PASS_LEN;
            memcpy(s_pass, val, copy_len);
            s_pass[copy_len] = '\0';
            s_has_pass = true;
            ESP_LOGI(TAG, "Password written");
            ESP_LOGD(TAG, "Password length: %zu chars", copy_len);
            try_provision();

        } else if (handle == s_handle_table[IDX_CHAR_STATUS_CCC]) {
            if (len == 2) {
                uint16_t cccd_val = val[0] | ((uint16_t)val[1] << 8);
                s_notify_enabled = (cccd_val == 0x0001);
                ESP_LOGI(TAG, "Status notifications %s",
                         s_notify_enabled ? "enabled" : "disabled");
            }
        }

        /* Send Write Response if needed */
        if (param->write.need_rsp) {
            esp_ble_gatts_send_response(gatts_if, param->write.conn_id,
                                        param->write.trans_id,
                                        ESP_GATT_OK, NULL);
        }
        break;
    }

    case ESP_GATTS_MTU_EVT:
        ESP_LOGI(TAG, "MTU set to %d", param->mtu.mtu);
        break;

    default:
        break;
    }
}

/* ── Public API ─────────────────────────────────────────────────────────── */

esp_err_t orb_ble_init(orb_ble_provision_cb_t provision_cb)
{
    if (s_initialised) {
        ESP_LOGW(TAG, "Already initialised");
        return ESP_OK;
    }

    s_provision_cb = provision_cb;

    /* Release memory reserved for Classic BT – we only need BLE */
    ESP_ERROR_CHECK(esp_bt_controller_mem_release(ESP_BT_MODE_CLASSIC_BT));

    esp_bt_controller_config_t bt_cfg = BT_CONTROLLER_INIT_CONFIG_DEFAULT();
    esp_err_t ret = esp_bt_controller_init(&bt_cfg);
    if (ret != ESP_OK) {
        ESP_LOGE(TAG, "BT controller init failed: %s", esp_err_to_name(ret));
        return ret;
    }

    ret = esp_bt_controller_enable(ESP_BT_MODE_BLE);
    if (ret != ESP_OK) {
        ESP_LOGE(TAG, "BT controller enable failed: %s", esp_err_to_name(ret));
        return ret;
    }

    ret = esp_bluedroid_init();
    if (ret != ESP_OK) {
        ESP_LOGE(TAG, "Bluedroid init failed: %s", esp_err_to_name(ret));
        return ret;
    }

    ret = esp_bluedroid_enable();
    if (ret != ESP_OK) {
        ESP_LOGE(TAG, "Bluedroid enable failed: %s", esp_err_to_name(ret));
        return ret;
    }

    ret = esp_ble_gap_register_callback(gap_event_handler);
    if (ret != ESP_OK) {
        ESP_LOGE(TAG, "GAP callback register failed: %s", esp_err_to_name(ret));
        return ret;
    }

    ret = esp_ble_gatts_register_callback(gatts_event_handler);
    if (ret != ESP_OK) {
        ESP_LOGE(TAG, "GATTS callback register failed: %s", esp_err_to_name(ret));
        return ret;
    }

    ret = esp_ble_gatts_app_register(GATTS_APP_ID);
    if (ret != ESP_OK) {
        ESP_LOGE(TAG, "GATTS app register failed: %s", esp_err_to_name(ret));
        return ret;
    }

    /* Raise the MTU ceiling; the stack will negotiate the actual value */
    esp_ble_gatt_set_local_mtu(500);

    s_initialised = true;
    ESP_LOGI(TAG, "Initialised (device name: %s)", BLE_DEVICE_NAME);
    return ESP_OK;
}

esp_err_t orb_ble_start_advertising(void)
{
    if (!s_initialised) {
        ESP_LOGE(TAG, "Not initialised");
        return ESP_ERR_INVALID_STATE;
    }
    if (s_state == BLE_STATE_ADVERTISING) {
        return ESP_OK;
    }

    /* Advertising actually starts in gap_event_handler after adv data is set */
    esp_err_t ret = esp_ble_gap_config_adv_data(&s_adv_data);
    if (ret != ESP_OK) {
        ESP_LOGE(TAG, "gap_config_adv_data failed: %s", esp_err_to_name(ret));
    }
    return ret;
}

esp_err_t orb_ble_stop_advertising(void)
{
    if (!s_initialised) {
        return ESP_ERR_INVALID_STATE;
    }
    return esp_ble_gap_stop_advertising();
}

esp_err_t orb_ble_send_status(const char *status_json)
{
    if (!s_initialised) {
        return ESP_ERR_INVALID_STATE;
    }
    if (!status_json) {
        return ESP_ERR_INVALID_ARG;
    }
    if (s_conn_id == 0xFFFF || !s_notify_enabled) {
        ESP_LOGW(TAG, "Cannot send status – no subscribed client");
        return ESP_ERR_INVALID_STATE;
    }

    size_t len = strnlen(status_json, MAX_STATUS_LEN);
    esp_err_t ret = esp_ble_gatts_send_indicate(
        s_gatts_if, s_conn_id,
        s_handle_table[IDX_CHAR_STATUS_VAL],
        (uint16_t)len, (uint8_t *)status_json,
        false /* indicate = false → notify */);

    if (ret != ESP_OK) {
        ESP_LOGE(TAG, "send_indicate failed: %s", esp_err_to_name(ret));
    }
    return ret;
}

orb_ble_state_t orb_ble_get_state(void)
{
    return s_state;
}

void orb_ble_deinit(void)
{
    if (!s_initialised) {
        return;
    }

    esp_ble_gap_stop_advertising();

    if (s_conn_id != 0xFFFF) {
        esp_ble_gatts_close(s_gatts_if, s_conn_id);
        s_conn_id = 0xFFFF;
    }

    esp_ble_gatts_app_unregister(s_gatts_if);
    esp_bluedroid_disable();
    esp_bluedroid_deinit();
    esp_bt_controller_disable();
    esp_bt_controller_deinit();

    s_gatts_if       = ESP_GATT_IF_NONE;
    s_notify_enabled = false;
    s_state          = BLE_STATE_IDLE;
    s_initialised    = false;
    s_has_ssid       = false;
    s_has_pass       = false;
    ESP_LOGI(TAG, "Deinitialised");
}
