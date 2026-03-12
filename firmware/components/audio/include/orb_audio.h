#pragma once

#include <stdint.h>
#include <stddef.h>
#include "esp_err.h"
#include "driver/i2s_types.h"

#ifdef __cplusplus
extern "C" {
#endif

/* ── Timing & buffering ───────────────────────────────────────────────── */
#define AUDIO_SAMPLE_RATE           16000   /* 16 kHz mono                */
#define AUDIO_BITS_PER_SAMPLE       16
#define AUDIO_DMA_BUF_COUNT         8
#define AUDIO_DMA_BUF_LEN           1024    /* bytes per DMA descriptor   */
#define AUDIO_RING_BUF_SAMPLES      32000   /* 2 s at 16 kHz – recommended
                                             * caller-side jitter buffer   */
#define AUDIO_VAD_SILENCE_MS        1500    /* auto-stop after 1.5 s      */
#define AUDIO_VOLUME_DEFAULT        60      /* default output volume (%)  */

/* ── I2S port assignments ─────────────────────────────────────────────── */
#define AUDIO_I2S_MIC_PORT          I2S_NUM_0
#define AUDIO_I2S_SPK_PORT          I2S_NUM_1

/* ── Default GPIO pin assignments ────────────────────────────────────── */
#define AUDIO_MIC_BCK_GPIO          14
#define AUDIO_MIC_WS_GPIO           15
#define AUDIO_MIC_DATA_GPIO         16
#define AUDIO_SPK_BCK_GPIO          17
#define AUDIO_SPK_WS_GPIO           18
#define AUDIO_SPK_DATA_GPIO         19

/* ── State machine ───────────────────────────────────────────────────── */
typedef enum {
    AUDIO_STATE_IDLE,       /* no activity                                */
    AUDIO_STATE_LISTENING,  /* recording from microphone                  */
    AUDIO_STATE_PLAYING,    /* playing back through speaker               */
} orb_audio_state_t;

/* ── Hardware configuration ──────────────────────────────────────────── */
typedef struct {
    /* INMP441 microphone (I2S_NUM_0) */
    int mic_bck_io;
    int mic_ws_io;
    int mic_data_io;
    /* MAX98357A amplifier (I2S_NUM_1) */
    int spk_bck_io;
    int spk_ws_io;
    int spk_data_io;
} orb_audio_config_t;

/**
 * @brief Called from the recording task with decoded PCM samples.
 *
 * The callback must return quickly; heavy processing should be deferred to
 * another task.  The @p samples buffer is only valid for the duration of
 * the call.
 *
 * @param samples  Pointer to 16-bit signed PCM samples (mono, 16 kHz).
 * @param count    Number of samples in the buffer.
 */
typedef void (*orb_audio_data_callback_t)(const int16_t *samples, size_t count);

/* ── Public API ──────────────────────────────────────────────────────── */

/**
 * @brief Initialise both I2S channels and internal state.
 *
 * Must be called once before any other orb_audio_* function.
 *
 * @param config  Hardware pin configuration.  Pass NULL to use the
 *                AUDIO_*_GPIO defaults defined above.
 * @return ESP_OK on success.
 */
esp_err_t orb_audio_init(const orb_audio_config_t *config);

/**
 * @brief Start the recording task.
 *
 * The task reads I2S data, runs VAD, invokes @p callback with each chunk,
 * and automatically calls orb_audio_stop_recording() after
 * AUDIO_VAD_SILENCE_MS of silence.
 *
 * @param callback  Function invoked with each PCM chunk.  Must not be NULL.
 * @return ESP_OK if the recording task was started successfully.
 */
esp_err_t orb_audio_start_recording(orb_audio_data_callback_t callback);

/**
 * @brief Stop an in-progress recording.
 *
 * Safe to call even when not recording (returns ESP_OK).
 */
esp_err_t orb_audio_stop_recording(void);

/**
 * @brief Write PCM samples to the speaker output.
 *
 * Blocks until all samples are written to the I2S DMA buffer.  Volume
 * scaling is applied before writing.
 *
 * @param samples  16-bit signed PCM samples (mono, 16 kHz).
 * @param count    Number of samples.
 * @return ESP_OK on success.
 */
esp_err_t orb_audio_play_samples(const int16_t *samples, size_t count);

/**
 * @brief Set the speaker output volume.
 *
 * @param percent  0–100 (clamped if out of range).
 * @return ESP_OK on success.
 */
esp_err_t orb_audio_set_volume(uint8_t percent);

/**
 * @brief Return the current audio state.
 */
orb_audio_state_t orb_audio_get_state(void);

/**
 * @brief Tear down I2S channels and free all resources.
 */
void orb_audio_deinit(void);

#ifdef __cplusplus
}
#endif
