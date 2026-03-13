#pragma once

#include <stdint.h>
#include "esp_err.h"
#include "driver/gpio.h"

#ifdef __cplusplus
extern "C" {
#endif

/* ── Hardware constants ─────────────────────────────────────────────────── */

#define ORB_LED_DEFAULT_GPIO    48      /**< Default WS2812B data pin (GPIO 48) */
#define ORB_LED_COUNT           12      /**< Number of LEDs in the ring          */

/* ── Breathing animation parameters ────────────────────────────────────── */

#define BREATH_PERIOD_MS        3500    /**< Full breath cycle: 3.5 s            */
#define BREATH_MIN_DUTY         13      /**< ~5% of 255 — Orb never goes dark    */
#define BREATH_MAX_DUTY         102     /**< ~40% of 255 — gentle ambient level  */

/* ── Types ──────────────────────────────────────────────────────────────── */

/**
 * @brief  Emotional state of the Orb, maps 1-to-1 to a light animation.
 */
typedef enum {
    ORB_MOOD_IDLE           = 0,  /**< Standby   — warm yellow, faint breathing   */
    ORB_MOOD_LISTENING      = 1,  /**< Listening — cyan ring slowly rotates       */
    ORB_MOOD_THINKING       = 2,  /**< Thinking  — white pulse, centre → edge     */
    ORB_MOOD_HAPPY          = 3,  /**< Happy     — warm orange, soft diffuse fade */
    ORB_MOOD_CONCERNED      = 4,  /**< Concerned — purple slow flash              */
    ORB_MOOD_CALM           = 5,  /**< Calm      — soft blue breathing            */
    ORB_MOOD_OK             = 6,  /**< OK        — green micro-pulse              */
    ORB_MOOD_ALERT          = 7,  /**< Alert     — red micro-flash                */
    ORB_MOOD_TOUCH_RESPONSE = 8,  /**< Touch     — warm yellow ripple expand      */
    ORB_MOOD_COUNT                /**< Sentinel — keep last                       */
} orb_mood_t;

/**
 * @brief  24-bit RGB colour value.
 */
typedef struct {
    uint8_t r;
    uint8_t g;
    uint8_t b;
} orb_rgb_t;

/**
 * @brief  Configuration passed to orb_led_init().
 */
typedef struct {
    gpio_num_t gpio_num;    /**< GPIO connected to WS2812B DIN              */
    uint32_t   led_count;   /**< Number of LEDs in the strip                */
} orb_led_config_t;

/* ── Public API ─────────────────────────────────────────────────────────── */

/**
 * @brief  Initialise the LED engine and start the animation task.
 *
 * Configures the RMT peripheral, starts the FreeRTOS animation task, and
 * sets the initial mood to ORB_MOOD_IDLE.  Must be called once before any
 * other orb_led_* function.
 *
 * @param  config  Hardware configuration (GPIO, LED count).
 *                 Pass NULL to use ORB_LED_DEFAULT_GPIO / ORB_LED_COUNT.
 * @return ESP_OK on success, ESP_ERR_* on failure.
 */
esp_err_t orb_led_init(const orb_led_config_t *config);

/**
 * @brief  Transition to a new emotional state.
 *
 * The transition is animated with a 200–500 ms cross-fade; there are no
 * hard colour cuts.  Safe to call from any task.
 *
 * @param  mood  Target mood.
 * @return ESP_OK on success.
 */
esp_err_t orb_led_set_mood(orb_mood_t mood);

/**
 * @brief  Override the master brightness (0–255).
 *
 * The value is applied on top of the animation engine; BREATH_MIN_DUTY
 * still acts as an absolute floor — the LEDs never go completely dark.
 *
 * @param  brightness  0 = minimum (floor applied), 255 = full.
 * @return ESP_OK on success.
 */
esp_err_t orb_led_set_brightness(uint8_t brightness);

/**
 * @brief  Set all LEDs to a fixed colour immediately (bypasses animation).
 *
 * Useful for testing or for simple solid-colour states.  Calling
 * orb_led_set_mood() afterwards resumes normal animation.
 *
 * @param  color  RGB colour to display.
 * @return ESP_OK on success.
 */
esp_err_t orb_led_set_color(orb_rgb_t color);

/**
 * @brief  Stop the animation task and release all resources.
 *
 * After this call the LEDs are left in an undefined state; call
 * orb_led_init() again to restart.
 */
void orb_led_deinit(void);

#ifdef __cplusplus
}
#endif
