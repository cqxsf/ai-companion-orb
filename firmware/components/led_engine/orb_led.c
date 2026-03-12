/**
 * @file  orb_led.c
 * @brief LED engine for the AI Companion Orb.
 *
 * Drives 12 × WS2812B LEDs via the ESP-IDF RMT peripheral.
 *
 * Architecture
 * ─────────────
 *   • A FreeRTOS task (priority 5) runs the animation loop at 50 fps.
 *   • Each mood has a base colour, an animation style, and a transition
 *     duration.  When orb_led_set_mood() is called the engine cross-fades
 *     from the current colour to the new target colour over 200–500 ms
 *     before starting the mood's own animation.
 *   • The breathing envelope uses a sine curve so the rhythm feels organic.
 *   • The minimum duty (BREATH_MIN_DUTY) is enforced at every write so the
 *     LEDs never go completely dark.
 */

#include <string.h>
#include <math.h>
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "freertos/semphr.h"
#include "esp_log.h"
#include "esp_err.h"
#include "esp_timer.h"
#include "driver/rmt_tx.h"
#include "driver/gpio.h"

#include "orb_led.h"

/* ── Logging ────────────────────────────────────────────────────────────── */

static const char *TAG = "orb_led";

/* ── Timing & resolution ────────────────────────────────────────────────── */

#define ANIM_FPS            50                          /* animation frames per second  */
#define ANIM_TICK_MS        (1000 / ANIM_FPS)           /* 20 ms per tick               */
#define RMT_RESOLUTION_HZ   10000000                    /* 10 MHz → 100 ns per tick     */

/* WS2812B bit timings (in RMT ticks at 10 MHz = 100 ns per tick) */
#define WS2812_T0H_TICKS    3   /* 300 ns */
#define WS2812_T0L_TICKS    9   /* 900 ns */
#define WS2812_T1H_TICKS    9   /* 900 ns */
#define WS2812_T1L_TICKS    3   /* 300 ns */
#define WS2812_RESET_US     50  /* ≥50 µs low for latch */

/* ── Transition & animation ─────────────────────────────────────────────── */

#define TRANSITION_MS       300     /* default cross-fade duration          */
#define RIPPLE_DURATION_MS  400     /* TOUCH_RESPONSE ripple lasts 400 ms   */

/* ── Internal types ─────────────────────────────────────────────────────── */

typedef enum {
    ANIM_BREATHE,       /* sine-envelope brightness on all LEDs             */
    ANIM_ROTATE,        /* single lit pixel walks around ring               */
    ANIM_PULSE_CENTER,  /* brightness wave from pixel 0 outward             */
    ANIM_FLASH,         /* alternate between two colours                    */
    ANIM_RIPPLE,        /* radial expand from touch point, then idle        */
    ANIM_SOLID,         /* static colour — used during override             */
} anim_style_t;

typedef struct {
    orb_rgb_t      base_color;
    orb_rgb_t      alt_color;       /* used by FLASH                        */
    anim_style_t   style;
    uint32_t       transition_ms;   /* cross-fade duration to this mood     */
} mood_def_t;

/* ── Mood table ─────────────────────────────────────────────────────────── */

static const mood_def_t k_mood_table[ORB_MOOD_COUNT] = {
    /* IDLE          */ { {0xFF, 0xA0, 0x40}, {0,0,0},          ANIM_BREATHE,      500 },
    /* LISTENING     */ { {0x40, 0xFF, 0xFF}, {0,0,0},          ANIM_ROTATE,       300 },
    /* THINKING      */ { {0xFF, 0xFF, 0xFF}, {0,0,0},          ANIM_PULSE_CENTER, 300 },
    /* HAPPY         */ { {0xFF, 0x80, 0x40}, {0,0,0},          ANIM_BREATHE,      400 },
    /* CONCERNED     */ { {0x80, 0x40, 0xFF}, {0x40, 0x00, 0x80}, ANIM_FLASH,      300 },
    /* CALM          */ { {0x40, 0x80, 0xFF}, {0,0,0},          ANIM_BREATHE,      500 },
    /* OK            */ { {0x40, 0xFF, 0x40}, {0,0,0},          ANIM_BREATHE,      200 },
    /* ALERT         */ { {0xFF, 0x40, 0x40}, {0,0,0},          ANIM_FLASH,        200 },
    /* TOUCH_RESPONSE*/ { {0xFF, 0xFF, 0x40}, {0,0,0},          ANIM_RIPPLE,       100 },
};

/* ── Module state ───────────────────────────────────────────────────────── */

static rmt_channel_handle_t  led_chan      = NULL;
static rmt_encoder_handle_t  led_encoder  = NULL;
static rmt_transmit_config_t tx_config    = { .loop_count = 0 };

static uint8_t  s_pixels[ORB_LED_COUNT * 3]; /* GRB order for WS2812B     */
static uint32_t s_led_count  = ORB_LED_COUNT;

static orb_mood_t   s_current_mood   = ORB_MOOD_IDLE;
static orb_mood_t   s_target_mood    = ORB_MOOD_IDLE;
static orb_rgb_t    s_from_color     = {0xFF, 0xA0, 0x40};
static orb_rgb_t    s_to_color       = {0xFF, 0xA0, 0x40};
static uint32_t     s_transition_ticks_total = 0;
static uint32_t     s_transition_ticks_done  = 0;
static bool         s_in_transition  = false;

static uint8_t      s_master_brightness = 255; /* 255 = no scaling         */
static bool         s_color_override    = false;
static orb_rgb_t    s_override_color    = {0};

static uint32_t     s_anim_tick     = 0;    /* monotonic counter           */

static TaskHandle_t s_anim_task     = NULL;
static SemaphoreHandle_t s_mutex    = NULL;
static bool         s_running       = false;

/* ── RMT / WS2812B encoder ──────────────────────────────────────────────── */

/*
 * We use a simple bytes encoder that converts each byte into 8 RMT symbols
 * using the WS2812B timing defined above.
 */

typedef struct {
    rmt_encoder_t base;
    rmt_encoder_t *bytes_encoder;
    rmt_encoder_t *copy_encoder;
    rmt_symbol_word_t reset_code;
    int state;
} ws2812_encoder_t;

static size_t ws2812_encode(rmt_encoder_t *encoder,
                             rmt_channel_handle_t channel,
                             const void *primary_data, size_t data_size,
                             rmt_encode_state_t *ret_state)
{
    ws2812_encoder_t *enc = __containerof(encoder, ws2812_encoder_t, base);
    rmt_encode_state_t session_state = RMT_ENCODING_RESET;
    rmt_encode_state_t state         = RMT_ENCODING_RESET;
    size_t encoded_symbols = 0;

    switch (enc->state) {
    case 0:
        encoded_symbols += enc->bytes_encoder->encode(
            enc->bytes_encoder, channel, primary_data, data_size, &session_state);
        if (session_state & RMT_ENCODING_COMPLETE) {
            enc->state = 1;
        }
        if (session_state & RMT_ENCODING_MEM_FULL) {
            state |= RMT_ENCODING_MEM_FULL;
            goto out;
        }
        /* fall through */
    case 1:
        encoded_symbols += enc->copy_encoder->encode(
            enc->copy_encoder, channel,
            &enc->reset_code, sizeof(enc->reset_code), &session_state);
        if (session_state & RMT_ENCODING_COMPLETE) {
            enc->state = RMT_ENCODING_RESET;
            state |= RMT_ENCODING_COMPLETE;
        }
        if (session_state & RMT_ENCODING_MEM_FULL) {
            state |= RMT_ENCODING_MEM_FULL;
        }
        break;
    }
out:
    *ret_state = state;
    return encoded_symbols;
}

static esp_err_t ws2812_del(rmt_encoder_t *encoder)
{
    ws2812_encoder_t *enc = __containerof(encoder, ws2812_encoder_t, base);
    rmt_del_encoder(enc->bytes_encoder);
    rmt_del_encoder(enc->copy_encoder);
    free(enc);
    return ESP_OK;
}

static esp_err_t ws2812_reset(rmt_encoder_t *encoder)
{
    ws2812_encoder_t *enc = __containerof(encoder, ws2812_encoder_t, base);
    rmt_encoder_reset(enc->bytes_encoder);
    rmt_encoder_reset(enc->copy_encoder);
    enc->state = RMT_ENCODING_RESET;
    return ESP_OK;
}

static esp_err_t create_ws2812_encoder(rmt_encoder_handle_t *ret_encoder)
{
    ws2812_encoder_t *enc = calloc(1, sizeof(ws2812_encoder_t));
    if (!enc) {
        return ESP_ERR_NO_MEM;
    }

    enc->base.encode = ws2812_encode;
    enc->base.del    = ws2812_del;
    enc->base.reset  = ws2812_reset;

    /* Bytes encoder: turns each byte into 8 RMT symbols */
    rmt_bytes_encoder_config_t bytes_cfg = {
        .bit0 = {
            .level0    = 1, .duration0 = WS2812_T0H_TICKS,
            .level1    = 0, .duration1 = WS2812_T0L_TICKS,
        },
        .bit1 = {
            .level0    = 1, .duration0 = WS2812_T1H_TICKS,
            .level1    = 0, .duration1 = WS2812_T1L_TICKS,
        },
        .flags.msb_first = 1,
    };
    ESP_RETURN_ON_ERROR(
        rmt_new_bytes_encoder(&bytes_cfg, &enc->bytes_encoder),
        TAG, "create bytes encoder failed");

    /* Copy encoder: used to emit the reset pulse */
    rmt_copy_encoder_config_t copy_cfg = {};
    ESP_RETURN_ON_ERROR(
        rmt_new_copy_encoder(&copy_cfg, &enc->copy_encoder),
        TAG, "create copy encoder failed");

    /* Reset code: line low for ≥50 µs — expressed as ticks at 10 MHz */
    enc->reset_code = (rmt_symbol_word_t){
        .level0    = 0,
        .duration0 = WS2812_RESET_US * (RMT_RESOLUTION_HZ / 1000000),
        .level1    = 0,
        .duration1 = WS2812_RESET_US * (RMT_RESOLUTION_HZ / 1000000),
    };

    *ret_encoder = &enc->base;
    return ESP_OK;
}

/* ── Helpers ────────────────────────────────────────────────────────────── */

/**
 * @brief  Apply master brightness and minimum-duty floor, then write one
 *         pixel into the GRB frame buffer at position @p idx.
 */
static inline void set_pixel(uint32_t idx, orb_rgb_t c, uint8_t brightness)
{
    /* Scale colour component by brightness (0-255) */
    uint8_t r = (uint8_t)((c.r * brightness) >> 8);
    uint8_t g = (uint8_t)((c.g * brightness) >> 8);
    uint8_t b = (uint8_t)((c.b * brightness) >> 8);

    /* Enforce minimum duty so Orb never goes completely dark.
     * We only apply the floor when the LED is "on" (base colour != black). */
    if (c.r || c.g || c.b) {
        if (r < BREATH_MIN_DUTY && c.r) r = BREATH_MIN_DUTY;
        if (g < BREATH_MIN_DUTY && c.g) g = BREATH_MIN_DUTY;
        if (b < BREATH_MIN_DUTY && c.b) b = BREATH_MIN_DUTY;
    }

    /* WS2812B expects GRB byte order */
    s_pixels[idx * 3 + 0] = g;
    s_pixels[idx * 3 + 1] = r;
    s_pixels[idx * 3 + 2] = b;
}

/** @brief  Fill all LEDs with the same colour and brightness. */
static void fill_all(orb_rgb_t c, uint8_t brightness)
{
    for (uint32_t i = 0; i < s_led_count; i++) {
        set_pixel(i, c, brightness);
    }
}

/** @brief  Push the frame buffer to the strip via RMT. */
static void flush_pixels(void)
{
    if (!led_chan || !led_encoder) {
        return;
    }
    esp_err_t err = rmt_transmit(led_chan, led_encoder,
                                  s_pixels, s_led_count * 3,
                                  &tx_config);
    if (err != ESP_OK) {
        ESP_LOGW(TAG, "rmt_transmit: %s", esp_err_to_name(err));
        return;
    }
    /* Wait for the transmission to complete so we don't mutate the buffer
     * mid-transfer.  Timeout = 2 × frame time at 800 kbps. */
    rmt_tx_wait_all_done(led_chan, pdMS_TO_TICKS(10));
}

/**
 * @brief  Linearly interpolate between two RGB colours.
 * @param  t  0 = full @p a, 255 = full @p b.
 */
static orb_rgb_t rgb_lerp(orb_rgb_t a, orb_rgb_t b, uint8_t t)
{
    orb_rgb_t out;
    out.r = (uint8_t)(a.r + (((int16_t)b.r - a.r) * t) / 255);
    out.g = (uint8_t)(a.g + (((int16_t)b.g - a.g) * t) / 255);
    out.b = (uint8_t)(a.b + (((int16_t)b.b - a.b) * t) / 255);
    return out;
}

/**
 * @brief  Compute the sine breathing envelope.
 *
 * Returns a brightness value in [BREATH_MIN_DUTY, BREATH_MAX_DUTY]
 * following a sine wave with period BREATH_PERIOD_MS.
 *
 * @param  tick_ms  Current absolute time in milliseconds.
 */
static uint8_t breath_brightness(uint32_t tick_ms)
{
    float phase = (2.0f * (float)M_PI * (tick_ms % BREATH_PERIOD_MS))
                  / (float)BREATH_PERIOD_MS;
    /* sin() ranges [-1, 1] → map to [MIN, MAX] */
    float norm   = (sinf(phase) + 1.0f) * 0.5f;          /* 0.0 – 1.0      */
    float duty   = BREATH_MIN_DUTY
                   + norm * (BREATH_MAX_DUTY - BREATH_MIN_DUTY);
    return (uint8_t)duty;
}

/* ── Animation renderer ─────────────────────────────────────────────────── */

/**
 * @brief  Render one frame for the current mood.
 *
 * Must be called with s_mutex held.
 */
static void render_frame(void)
{
    uint32_t now_ms = s_anim_tick * ANIM_TICK_MS;

    /* ── Colour-override mode (set by orb_led_set_color) ── */
    if (s_color_override) {
        fill_all(s_override_color, s_master_brightness);
        flush_pixels();
        return;
    }

    /* ── Cross-fade transition ── */
    if (s_in_transition) {
        s_transition_ticks_done++;
        uint8_t t = (uint8_t)(
            (s_transition_ticks_done * 255) / s_transition_ticks_total);
        orb_rgb_t blend = rgb_lerp(s_from_color, s_to_color, t);
        fill_all(blend, s_master_brightness);
        flush_pixels();

        if (s_transition_ticks_done >= s_transition_ticks_total) {
            s_in_transition   = false;
            s_current_mood    = s_target_mood;
            s_anim_tick       = 0;   /* restart mood-local clock */
            now_ms            = 0;
        }
        return;
    }

    /* ── Mood-specific animations ── */
    const mood_def_t *m = &k_mood_table[s_current_mood];

    switch (m->style) {

    case ANIM_BREATHE: {
        uint8_t bri = breath_brightness(now_ms);
        fill_all(m->base_color, bri);
        break;
    }

    case ANIM_ROTATE: {
        /* One bright pixel rotates; all others at minimum brightness. */
        uint32_t period_ticks = (BREATH_PERIOD_MS / ANIM_TICK_MS);
        uint32_t head = s_anim_tick % s_led_count;
        for (uint32_t i = 0; i < s_led_count; i++) {
            uint8_t bri = (i == head) ? BREATH_MAX_DUTY : BREATH_MIN_DUTY;
            set_pixel(i, m->base_color, bri);
        }
        (void)period_ticks;
        break;
    }

    case ANIM_PULSE_CENTER: {
        /* Wave radiates outward from LED 0. */
        float phase = (2.0f * (float)M_PI * (now_ms % BREATH_PERIOD_MS))
                      / (float)BREATH_PERIOD_MS;
        for (uint32_t i = 0; i < s_led_count; i++) {
            float offset = (float)i / (float)s_led_count * (float)M_PI;
            float norm   = (sinf(phase - offset) + 1.0f) * 0.5f;
            uint8_t bri  = (uint8_t)(BREATH_MIN_DUTY
                           + norm * (BREATH_MAX_DUTY - BREATH_MIN_DUTY));
            set_pixel(i, m->base_color, bri);
        }
        break;
    }

    case ANIM_FLASH: {
        /* Alternate between base and alt colour every half-period. */
        uint32_t flash_period_ticks = (800 / ANIM_TICK_MS); /* 800 ms cycle */
        bool use_base = ((s_anim_tick % flash_period_ticks)
                         < (flash_period_ticks / 2));
        orb_rgb_t c   = use_base ? m->base_color : m->alt_color;
        uint8_t bri   = breath_brightness(now_ms);
        fill_all(c, bri);
        break;
    }

    case ANIM_RIPPLE: {
        /* Expand brightness wave outward, then fall back to IDLE. */
        uint32_t ripple_ticks = (RIPPLE_DURATION_MS / ANIM_TICK_MS);
        if (s_anim_tick >= ripple_ticks) {
            /* Ripple done — switch back to IDLE without another transition */
            s_current_mood = ORB_MOOD_IDLE;
            s_target_mood  = ORB_MOOD_IDLE;
            s_anim_tick    = 0;
            fill_all(k_mood_table[ORB_MOOD_IDLE].base_color,
                     breath_brightness(0));
            break;
        }
        float progress = (float)s_anim_tick / (float)ripple_ticks; /* 0→1 */
        for (uint32_t i = 0; i < s_led_count; i++) {
            float pos  = (float)i / (float)s_led_count;
            /* Circular distance from LED 0 on a ring */
            float dist = fabsf(pos - progress);
            if (dist > 0.5f) dist = 1.0f - dist;
            float norm  = 1.0f - (dist * 4.0f);
            if (norm < 0.0f) norm = 0.0f;
            uint8_t bri = (uint8_t)(BREATH_MIN_DUTY
                          + norm * (BREATH_MAX_DUTY - BREATH_MIN_DUTY));
            set_pixel(i, m->base_color, bri);
        }
        break;
    }

    case ANIM_SOLID:
        fill_all(m->base_color, s_master_brightness);
        break;
    }

    flush_pixels();
}

/* ── Animation task ─────────────────────────────────────────────────────── */

static void anim_task(void *arg)
{
    ESP_LOGI(TAG, "animation task started at %d fps", ANIM_FPS);

    while (s_running) {
        xSemaphoreTake(s_mutex, portMAX_DELAY);
        render_frame();
        s_anim_tick++;
        xSemaphoreGive(s_mutex);

        vTaskDelay(pdMS_TO_TICKS(ANIM_TICK_MS));
    }

    ESP_LOGI(TAG, "animation task stopped");
    vTaskDelete(NULL);
}

/* ── Public API ─────────────────────────────────────────────────────────── */

esp_err_t orb_led_init(const orb_led_config_t *config)
{
    if (led_chan) {
        ESP_LOGW(TAG, "already initialised");
        return ESP_ERR_INVALID_STATE;
    }

    gpio_num_t gpio    = config ? config->gpio_num  : ORB_LED_DEFAULT_GPIO;
    s_led_count        = config ? config->led_count : ORB_LED_COUNT;

    ESP_LOGI(TAG, "init: GPIO %d, %lu LEDs", gpio, s_led_count);

    /* ── RMT channel ── */
    rmt_tx_channel_config_t chan_cfg = {
        .gpio_num            = gpio,
        .clk_src             = RMT_CLK_SRC_DEFAULT,
        .resolution_hz       = RMT_RESOLUTION_HZ,
        .mem_block_symbols   = 64,
        .trans_queue_depth   = 4,
        .flags.invert_out    = false,
        .flags.with_dma      = false,
    };
    ESP_RETURN_ON_ERROR(
        rmt_new_tx_channel(&chan_cfg, &led_chan),
        TAG, "create RMT channel failed");

    /* ── WS2812B encoder ── */
    ESP_RETURN_ON_ERROR(
        create_ws2812_encoder(&led_encoder),
        TAG, "create WS2812B encoder failed");

    /* ── Enable channel ── */
    ESP_RETURN_ON_ERROR(
        rmt_enable(led_chan),
        TAG, "enable RMT channel failed");

    /* ── Mutex ── */
    s_mutex = xSemaphoreCreateMutex();
    if (!s_mutex) {
        ESP_LOGE(TAG, "failed to create mutex");
        return ESP_ERR_NO_MEM;
    }

    /* ── Initial state ── */
    s_current_mood   = ORB_MOOD_IDLE;
    s_target_mood    = ORB_MOOD_IDLE;
    s_from_color     = k_mood_table[ORB_MOOD_IDLE].base_color;
    s_to_color       = k_mood_table[ORB_MOOD_IDLE].base_color;
    s_in_transition  = false;
    s_anim_tick      = 0;
    s_running        = true;

    /* Blank all LEDs first */
    memset(s_pixels, 0, sizeof(s_pixels));
    flush_pixels();

    /* ── Animation task ── */
    BaseType_t xret = xTaskCreate(anim_task, "orb_led_anim",
                                   4096, NULL, 5, &s_anim_task);
    if (xret != pdPASS) {
        ESP_LOGE(TAG, "failed to create animation task");
        return ESP_FAIL;
    }

    ESP_LOGI(TAG, "init complete");
    return ESP_OK;
}

esp_err_t orb_led_set_mood(orb_mood_t mood)
{
    if (!led_chan) {
        return ESP_ERR_INVALID_STATE;
    }
    if (mood >= ORB_MOOD_COUNT) {
        return ESP_ERR_INVALID_ARG;
    }

    xSemaphoreTake(s_mutex, portMAX_DELAY);

    if (mood == s_current_mood && !s_in_transition) {
        xSemaphoreGive(s_mutex);
        return ESP_OK;
    }

    const mood_def_t *m = &k_mood_table[mood];

    /* Snapshot the pixel colour we are currently showing as the blend start.
     * Use the centre LED's colour from the last rendered frame. */
    s_from_color = (orb_rgb_t){
        .r = s_pixels[1],   /* GRB: index 1 is R */
        .g = s_pixels[0],   /* GRB: index 0 is G */
        .b = s_pixels[2],
    };
    s_to_color   = m->base_color;
    s_target_mood = mood;

    uint32_t dur_ms              = m->transition_ms;
    s_transition_ticks_total     = MAX(1, dur_ms / ANIM_TICK_MS);
    s_transition_ticks_done      = 0;
    s_in_transition              = true;
    s_color_override             = false;   /* exit override mode if active */

    ESP_LOGI(TAG, "mood → %d (%lums transition)", mood, dur_ms);

    xSemaphoreGive(s_mutex);
    return ESP_OK;
}

esp_err_t orb_led_set_brightness(uint8_t brightness)
{
    if (!led_chan) {
        return ESP_ERR_INVALID_STATE;
    }
    xSemaphoreTake(s_mutex, portMAX_DELAY);
    s_master_brightness = brightness;
    xSemaphoreGive(s_mutex);
    return ESP_OK;
}

esp_err_t orb_led_set_color(orb_rgb_t color)
{
    if (!led_chan) {
        return ESP_ERR_INVALID_STATE;
    }
    xSemaphoreTake(s_mutex, portMAX_DELAY);
    s_override_color = color;
    s_color_override = true;
    s_in_transition  = false;
    xSemaphoreGive(s_mutex);
    return ESP_OK;
}

void orb_led_deinit(void)
{
    if (!led_chan) {
        return;
    }

    s_running = false;

    /* Give the task time to exit cleanly */
    if (s_anim_task) {
        vTaskDelay(pdMS_TO_TICKS(ANIM_TICK_MS * 3));
        s_anim_task = NULL;
    }

    if (s_mutex) {
        vSemaphoreDelete(s_mutex);
        s_mutex = NULL;
    }

    rmt_disable(led_chan);

    if (led_encoder) {
        rmt_del_encoder(led_encoder);
        led_encoder = NULL;
    }

    rmt_del_channel(led_chan);
    led_chan = NULL;

    ESP_LOGI(TAG, "deinit complete");
}
