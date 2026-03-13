#include "orb_touch.h"

#include <string.h>
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "freertos/semphr.h"
#include "esp_log.h"
#include "esp_err.h"
#include "esp_timer.h"
#include "driver/touch_pad.h"

static const char *TAG = "orb_touch";

/* ── Tuning constants ────────────────────────────────────────────────────── */
#define SCAN_INTERVAL_MS        10
#define DEBOUNCE_MS             50
#define CALIBRATION_INTERVAL_MS 5000
#define CALIBRATION_SAMPLES     16
#define TAP_MAX_MS              300   /* touches shorter than this → TAP      */

/* Number of touch channels monitored */
#define NUM_PADS 3
static const touch_pad_t k_pads[NUM_PADS] = {
    TOUCH_PAD_TOP,
    TOUCH_PAD_MID,
    TOUCH_PAD_BOT,
};

/* ── FSM states ───────────────────────────────────────────────────────────── */
typedef enum {
    FSM_IDLE,           /* no touch activity                                  */
    FSM_DEBOUNCE,       /* waiting out the debounce period                    */
    FSM_TOUCHED,        /* at least one pad active, timing in progress        */
    FSM_AWAIT_SECOND,   /* first tap completed, watching for a second tap     */
} fsm_state_t;

/* ── Module state ────────────────────────────────────────────────────────── */
typedef struct {
    orb_touch_config_t  cfg;
    uint32_t            baseline[NUM_PADS]; /* calibrated raw readings        */
    uint32_t            threshold[NUM_PADS];/* absolute threshold per pad     */

    fsm_state_t         state;
    int64_t             touch_start_us;     /* esp_timer_get_time() at onset  */
    int64_t             first_tap_end_us;   /* end of first tap (AWAIT_SECOND)*/
    uint8_t             active_mask;        /* bitmask of currently-touched pads */
    uint8_t             peak_mask;          /* widest simultaneous active mask*/
    bool                second_tap_seen;    /* true once a second touch starts in AWAIT_SECOND */

    TaskHandle_t        scan_task_handle;
    TaskHandle_t        calib_task_handle;
    SemaphoreHandle_t   mutex;
    volatile bool       running;
    volatile bool       any_active;
} orb_touch_ctx_t;

static orb_touch_ctx_t s_ctx;
static bool s_initialised = false;

/* ── Forward declarations ────────────────────────────────────────────────── */
static void     touch_scan_task(void *arg);
static void     touch_calib_task(void *arg);
static void     calibrate_all(void);
static uint8_t  read_active_mask(void);
static float    mask_to_area(uint8_t mask);
static void     fire_event(touch_gesture_t gesture, uint8_t mask, uint32_t duration_ms);

/* ── Public API ──────────────────────────────────────────────────────────── */

esp_err_t orb_touch_init(const orb_touch_config_t *config)
{
    if (s_initialised) {
        ESP_LOGW(TAG, "already initialised");
        return ESP_ERR_INVALID_STATE;
    }
    if (config == NULL || config->callback == NULL) {
        ESP_LOGE(TAG, "config or callback is NULL");
        return ESP_ERR_INVALID_ARG;
    }

    memset(&s_ctx, 0, sizeof(s_ctx));
    s_ctx.cfg = *config;

    /* Apply defaults for zero-valued thresholds */
    if (s_ctx.cfg.long_press_ms == 0)        s_ctx.cfg.long_press_ms        = 1500;
    if (s_ctx.cfg.embrace_ms == 0)           s_ctx.cfg.embrace_ms           = 3000;
    if (s_ctx.cfg.double_tap_window_ms == 0) s_ctx.cfg.double_tap_window_ms = 300;

    s_ctx.mutex = xSemaphoreCreateMutex();
    if (s_ctx.mutex == NULL) {
        ESP_LOGE(TAG, "failed to create mutex");
        return ESP_ERR_NO_MEM;
    }

    /* Initialise touch peripheral */
    ESP_ERROR_CHECK(touch_pad_init());

    /*
     * TOUCH_HVOLT_2V7 / TOUCH_LVOLT_0V5 / TOUCH_HVOLT_ATTEN_1V give a
     * good dynamic range for a 85 mm sphere with exposed copper pads.
     */
    ESP_ERROR_CHECK(touch_pad_set_voltage(TOUCH_HVOLT_2V7, TOUCH_LVOLT_0V5,
                                          TOUCH_HVOLT_ATTEN_1V));

    for (int i = 0; i < NUM_PADS; i++) {
        ESP_ERROR_CHECK(touch_pad_config(k_pads[i]));
    }

    /* FSM starts idle */
    s_ctx.state   = FSM_IDLE;
    s_ctx.running = true;

    /* Initial calibration (blocking, runs before tasks start) */
    calibrate_all();

    xTaskCreate(touch_scan_task,  "orb_touch_scan",  2048, NULL, 10,
                &s_ctx.scan_task_handle);
    xTaskCreate(touch_calib_task, "orb_touch_calib", 2048, NULL,  5,
                &s_ctx.calib_task_handle);

    if (s_ctx.scan_task_handle == NULL || s_ctx.calib_task_handle == NULL) {
        ESP_LOGE(TAG, "failed to create tasks");
        orb_touch_deinit();
        return ESP_ERR_NO_MEM;
    }

    s_initialised = true;
    ESP_LOGI(TAG, "initialised (long=%"PRIu32"ms, embrace=%"PRIu32"ms, dtap=%"PRIu32"ms)",
             s_ctx.cfg.long_press_ms, s_ctx.cfg.embrace_ms,
             s_ctx.cfg.double_tap_window_ms);
    return ESP_OK;
}

void orb_touch_deinit(void)
{
    if (!s_initialised) return;

    s_ctx.running = false;

    /* Give tasks time to exit their loops */
    vTaskDelay(pdMS_TO_TICKS(SCAN_INTERVAL_MS * 3));

    if (s_ctx.scan_task_handle) {
        vTaskDelete(s_ctx.scan_task_handle);
        s_ctx.scan_task_handle = NULL;
    }
    if (s_ctx.calib_task_handle) {
        vTaskDelete(s_ctx.calib_task_handle);
        s_ctx.calib_task_handle = NULL;
    }
    if (s_ctx.mutex) {
        vSemaphoreDelete(s_ctx.mutex);
        s_ctx.mutex = NULL;
    }

    touch_pad_deinit();
    s_initialised  = false;
    s_ctx.any_active = false;
    ESP_LOGI(TAG, "deinitialised");
}

bool orb_touch_is_active(void)
{
    return s_ctx.any_active;
}

/* ── Internal helpers ────────────────────────────────────────────────────── */

/**
 * @brief Sample each pad CALIBRATION_SAMPLES times and store average as
 *        baseline, then derive absolute threshold from TOUCH_THRESHOLD_PERCENT.
 */
static void calibrate_all(void)
{
    ESP_LOGI(TAG, "calibrating baselines…");
    for (int i = 0; i < NUM_PADS; i++) {
        uint64_t sum = 0;
        for (int s = 0; s < CALIBRATION_SAMPLES; s++) {
            uint32_t raw = 0;
            touch_pad_read_raw_data(k_pads[i], &raw);
            sum += raw;
            vTaskDelay(pdMS_TO_TICKS(5));
        }
        s_ctx.baseline[i]  = (uint32_t)(sum / CALIBRATION_SAMPLES);
        /* Threshold = baseline reduced by TOUCH_THRESHOLD_PERCENT */
        s_ctx.threshold[i] = s_ctx.baseline[i]
                             * (100 - TOUCH_THRESHOLD_PERCENT) / 100;
        ESP_LOGD(TAG, "pad%d baseline=%"PRIu32" threshold=%"PRIu32,
                 i, s_ctx.baseline[i], s_ctx.threshold[i]);
    }
}

/**
 * @brief Read all pads and return a bitmask of which ones are below threshold.
 *        Bit 0 = TOP, bit 1 = MID, bit 2 = BOT.
 */
static uint8_t read_active_mask(void)
{
    uint8_t mask = 0;
    for (int i = 0; i < NUM_PADS; i++) {
        uint32_t raw = 0;
        touch_pad_read_raw_data(k_pads[i], &raw);
        if (raw < s_ctx.threshold[i]) {
            mask |= (1u << i);
        }
    }
    return mask;
}

/** Convert an active-pad bitmask to a 0.0–1.0 area fraction. */
static float mask_to_area(uint8_t mask)
{
    int count = __builtin_popcount(mask);
    return (float)count / (float)NUM_PADS;
}

/** Build an event and invoke the user callback. */
static void fire_event(touch_gesture_t gesture, uint8_t mask, uint32_t duration_ms)
{
    orb_touch_event_t ev = {
        .gesture     = gesture,
        .touch_area  = mask_to_area(mask),
        .duration_ms = duration_ms,
    };
    ESP_LOGI(TAG, "gesture=%d area=%.2f duration=%"PRIu32"ms",
             (int)gesture, ev.touch_area, duration_ms);
    s_ctx.cfg.callback(&ev);
}

/* ── Gesture FSM ─────────────────────────────────────────────────────────── */

/**
 * @brief Core FSM tick — called every SCAN_INTERVAL_MS from the scan task.
 *
 * State transitions:
 *
 *  IDLE ──(any pad active)──► DEBOUNCE
 *  DEBOUNCE ──(still active after DEBOUNCE_MS)──► TOUCHED
 *  DEBOUNCE ──(gone before DEBOUNCE_MS)──► IDLE     (noise, ignored)
 *  TOUCHED ──(all released)──► classify: TAP / LONG / EMBRACE or AWAIT_SECOND
 *  AWAIT_SECOND ──(tap within window)──► DOUBLE_TAP → IDLE
 *  AWAIT_SECOND ──(timeout)──► emit TAP for first tap → IDLE
 */
static void fsm_tick(void)
{
    int64_t  now_us   = esp_timer_get_time();
    uint8_t  cur_mask = read_active_mask();
    bool     touching = (cur_mask != 0);

    /* Update the public active flag */
    s_ctx.any_active = touching;

    switch (s_ctx.state) {

    case FSM_IDLE:
        if (touching) {
            s_ctx.touch_start_us = now_us;
            s_ctx.peak_mask      = cur_mask;
            s_ctx.state          = FSM_DEBOUNCE;
        }
        break;

    case FSM_DEBOUNCE: {
        uint32_t elapsed_ms = (uint32_t)((now_us - s_ctx.touch_start_us) / 1000);
        if (!touching) {
            /* Gone before debounce — treat as noise */
            s_ctx.state = FSM_IDLE;
        } else if (elapsed_ms >= DEBOUNCE_MS) {
            s_ctx.active_mask = cur_mask;
            s_ctx.peak_mask   = cur_mask;
            s_ctx.state       = FSM_TOUCHED;
        } else {
            /* Accumulate peak mask during debounce */
            s_ctx.peak_mask |= cur_mask;
        }
        break;
    }

    case FSM_TOUCHED: {
        /* Keep track of the widest simultaneous contact area */
        s_ctx.peak_mask |= cur_mask;

        uint32_t held_ms = (uint32_t)((now_us - s_ctx.touch_start_us) / 1000);

        if (touching) {
            /*
             * Fire long-hold gestures eagerly while the finger is still down,
             * then reset the start time so they don't re-fire every tick.
             */
            if (__builtin_popcount(s_ctx.peak_mask) > 1
                && held_ms >= s_ctx.cfg.embrace_ms) {
                fire_event(TOUCH_EMBRACE, s_ctx.peak_mask, held_ms);
                s_ctx.touch_start_us = now_us; /* reset to avoid re-firing */
            } else if (__builtin_popcount(s_ctx.peak_mask) == 1
                       && held_ms >= s_ctx.cfg.long_press_ms) {
                fire_event(TOUCH_LONG, s_ctx.peak_mask, held_ms);
                s_ctx.touch_start_us = now_us;
            }
        } else {
            /* All pads released — classify by total duration */
            if (held_ms >= s_ctx.cfg.embrace_ms
                && __builtin_popcount(s_ctx.peak_mask) > 1) {
                fire_event(TOUCH_EMBRACE, s_ctx.peak_mask, held_ms);
                s_ctx.state = FSM_IDLE;
            } else if (held_ms >= s_ctx.cfg.long_press_ms) {
                fire_event(TOUCH_LONG, s_ctx.peak_mask, held_ms);
                s_ctx.state = FSM_IDLE;
            } else if (held_ms < TAP_MAX_MS) {
                /* Short tap — wait to see if a second follows */
                s_ctx.first_tap_end_us  = now_us;
                s_ctx.second_tap_seen   = false;
                s_ctx.state             = FSM_AWAIT_SECOND;
            } else {
                /* Duration between TAP_MAX_MS and long_press_ms — plain TAP */
                fire_event(TOUCH_TAP, s_ctx.peak_mask, held_ms);
                s_ctx.state = FSM_IDLE;
            }
        }
        break;
    }

    case FSM_AWAIT_SECOND: {
        uint32_t wait_ms =
            (uint32_t)((now_us - s_ctx.first_tap_end_us) / 1000);

        if (touching) {
            if (wait_ms <= s_ctx.cfg.double_tap_window_ms) {
                /* Second tap arrived in time — track area, wait for release */
                s_ctx.peak_mask        |= cur_mask;
                s_ctx.second_tap_seen   = true;
            } else {
                /*
                 * New touch after window expired — emit the pending TAP and
                 * restart detection from DEBOUNCE for this new touch.
                 * Use first_tap_end_us to get the first tap's actual duration.
                 */
                uint32_t duration_ms =
                    (uint32_t)((s_ctx.first_tap_end_us - s_ctx.touch_start_us) / 1000);
                fire_event(TOUCH_TAP, s_ctx.peak_mask, duration_ms);
                s_ctx.touch_start_us  = now_us;
                s_ctx.peak_mask       = cur_mask;
                s_ctx.second_tap_seen = false;
                s_ctx.first_tap_end_us = now_us;
                s_ctx.state           = FSM_DEBOUNCE;
            }
        } else {
            if (s_ctx.second_tap_seen) {
                /*
                 * Second tap was seen and finger just lifted → DOUBLE_TAP.
                 * duration_ms spans the full gesture window (first-tap-start
                 * to second-tap-end), giving the caller the total interaction
                 * time for the double-tap.
                 */
                uint32_t duration_ms =
                    (uint32_t)((now_us - s_ctx.touch_start_us) / 1000);
                fire_event(TOUCH_DOUBLE_TAP, s_ctx.peak_mask, duration_ms);
                s_ctx.state = FSM_IDLE;
            } else if (wait_ms > s_ctx.cfg.double_tap_window_ms) {
                /* Window expired, no second tap seen → emit single TAP with
                 * the first tap's actual duration. */
                uint32_t duration_ms =
                    (uint32_t)((s_ctx.first_tap_end_us - s_ctx.touch_start_us) / 1000);
                fire_event(TOUCH_TAP, s_ctx.peak_mask, duration_ms);
                s_ctx.state = FSM_IDLE;
            }
            /* else: still within window, no second tap yet — keep waiting */
        }
        break;
    }
    }
}

/* ── FreeRTOS tasks ──────────────────────────────────────────────────────── */

static void touch_scan_task(void *arg)
{
    ESP_LOGI(TAG, "scan task started");
    while (s_ctx.running) {
        xSemaphoreTake(s_ctx.mutex, portMAX_DELAY);
        fsm_tick();
        xSemaphoreGive(s_ctx.mutex);
        vTaskDelay(pdMS_TO_TICKS(SCAN_INTERVAL_MS));
    }
    ESP_LOGI(TAG, "scan task exiting");
    vTaskDelete(NULL);
}

static void touch_calib_task(void *arg)
{
    ESP_LOGI(TAG, "calibration task started");
    while (s_ctx.running) {
        vTaskDelay(pdMS_TO_TICKS(CALIBRATION_INTERVAL_MS));
        /* Only recalibrate while no touch is active to avoid skewing baseline */
        if (!s_ctx.any_active) {
            xSemaphoreTake(s_ctx.mutex, portMAX_DELAY);
            calibrate_all();
            xSemaphoreGive(s_ctx.mutex);
        }
    }
    ESP_LOGI(TAG, "calibration task exiting");
    vTaskDelete(NULL);
}
