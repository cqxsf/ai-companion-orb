#pragma once

#include <stdbool.h>
#include <stdint.h>
#include "esp_err.h"
#include "driver/touch_pad.h"

#ifdef __cplusplus
extern "C" {
#endif

/* Touch pad channel assignments for the three sphere zones */
#define TOUCH_PAD_TOP   TOUCH_PAD_NUM1
#define TOUCH_PAD_MID   TOUCH_PAD_NUM2
#define TOUCH_PAD_BOT   TOUCH_PAD_NUM3

/* Percentage drop in raw reading required to register a touch */
#define TOUCH_THRESHOLD_PERCENT  20

/**
 * @brief Gesture types produced by the touch FSM.
 */
typedef enum {
    TOUCH_TAP,        /**< Single light touch < 300 ms        */
    TOUCH_LONG,       /**< Sustained press > 1500 ms           */
    TOUCH_EMBRACE,    /**< Multi-pad contact > 3000 ms         */
    TOUCH_DOUBLE_TAP, /**< Two taps within double_tap_window_ms */
} touch_gesture_t;

/**
 * @brief Event delivered to the application callback.
 */
typedef struct {
    touch_gesture_t gesture;     /**< Detected gesture                          */
    float           touch_area;  /**< Fraction of active pads: 0.33/0.66/1.0   */
    uint32_t        duration_ms; /**< How long the touch lasted (ms)            */
} orb_touch_event_t;

/**
 * @brief Callback invoked from the touch scan task when a gesture completes.
 *
 * @note  The callback runs in the context of the touch scan task.
 *        Keep it short or post to another queue.
 */
typedef void (*orb_touch_callback_t)(const orb_touch_event_t *event);

/**
 * @brief Component configuration passed to orb_touch_init().
 */
typedef struct {
    orb_touch_callback_t callback;            /**< Called on every completed gesture        */
    uint32_t             long_press_ms;       /**< Duration threshold for LONG (default 1500) */
    uint32_t             embrace_ms;          /**< Duration threshold for EMBRACE (default 3000) */
    uint32_t             double_tap_window_ms;/**< Window to detect second tap (default 300)    */
} orb_touch_config_t;

/**
 * @brief Initialise the touch sensor component.
 *
 * Configures the three touch pads, starts the background calibration task
 * and the gesture-detection scan task.
 *
 * @param config  Non-NULL pointer to configuration.  Zero-value thresholds
 *                are replaced with the defaults listed in orb_touch_config_t.
 * @return ESP_OK on success, or an esp_err_t error code.
 */
esp_err_t orb_touch_init(const orb_touch_config_t *config);

/**
 * @brief Stop tasks and release touch hardware resources.
 */
void orb_touch_deinit(void);

/**
 * @brief Returns true while at least one pad is currently touched.
 */
bool orb_touch_is_active(void);

#ifdef __cplusplus
}
#endif
