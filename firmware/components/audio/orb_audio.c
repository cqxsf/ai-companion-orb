#include "orb_audio.h"

#include <string.h>
#include <math.h>

#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "freertos/semphr.h"
#include "driver/i2s_std.h"
#include "esp_log.h"
#include "esp_err.h"
#include "esp_timer.h"

static const char *TAG = "orb_audio";

/* ── VAD energy threshold (RMS of a DMA chunk) ───────────────────────── */
#define VAD_RMS_THRESHOLD   200     /* tune for your environment          */

/* ── Recording task ──────────────────────────────────────────────────── */
#define RECORD_TASK_STACK   4096
#define RECORD_TASK_PRIO    5

/* ── Internal state ──────────────────────────────────────────────────── */
typedef struct {
    i2s_chan_handle_t        mic_chan;
    i2s_chan_handle_t        spk_chan;
    orb_audio_state_t        state;
    SemaphoreHandle_t        mutex;
    orb_audio_data_callback_t data_cb;
    TaskHandle_t             record_task;
    volatile bool            stop_recording;
    uint8_t                  volume_pct;    /* 0-100 */
} orb_audio_ctx_t;

static orb_audio_ctx_t s_ctx = {
    .mic_chan      = NULL,
    .spk_chan      = NULL,
    .state         = AUDIO_STATE_IDLE,
    .mutex         = NULL,
    .data_cb       = NULL,
    .record_task   = NULL,
    .stop_recording = false,
    .volume_pct    = AUDIO_VOLUME_DEFAULT,
};

/* ── Helpers ─────────────────────────────────────────────────────────── */

/** Compute RMS energy of a 16-bit PCM buffer. */
static uint32_t calc_rms(const int16_t *samples, size_t count)
{
    if (count == 0) return 0;

    uint64_t sum = 0;
    for (size_t i = 0; i < count; i++) {
        int32_t s = samples[i];
        sum += (uint64_t)(s * s);
    }
    return (uint32_t)sqrtf((float)(sum / count));
}

/** Apply software volume scaling in-place. */
static void apply_volume(int16_t *samples, size_t count, uint8_t pct)
{
    if (pct >= 100) return;
    for (size_t i = 0; i < count; i++) {
        samples[i] = (int16_t)((int32_t)samples[i] * pct / 100);
    }
}

/* ── Recording task ──────────────────────────────────────────────────── */

static void recording_task(void *arg)
{
    /* DMA read buffer: AUDIO_DMA_BUF_LEN bytes = 512 int16 samples */
    static int16_t dma_buf[AUDIO_DMA_BUF_LEN / sizeof(int16_t)];
    const size_t samples_per_chunk = sizeof(dma_buf) / sizeof(int16_t);

    /* VAD silence tracking */
    const uint32_t silence_ticks =
        pdMS_TO_TICKS(AUDIO_VAD_SILENCE_MS);
    TickType_t silence_since = xTaskGetTickCount();
    bool voice_ever_detected = false;

    ESP_LOGI(TAG, "recording task started");

    while (!s_ctx.stop_recording) {
        size_t bytes_read = 0;
        esp_err_t ret = i2s_channel_read(s_ctx.mic_chan,
                                         dma_buf,
                                         sizeof(dma_buf),
                                         &bytes_read,
                                         pdMS_TO_TICKS(100));

        if (ret != ESP_OK || bytes_read == 0) {
            continue;
        }

        size_t samples_read = bytes_read / sizeof(int16_t);
        uint32_t rms = calc_rms(dma_buf, samples_read);

        if (rms >= VAD_RMS_THRESHOLD) {
            voice_ever_detected = true;
            silence_since = xTaskGetTickCount();

            if (s_ctx.data_cb) {
                s_ctx.data_cb(dma_buf, samples_read);
            }
        } else {
            /* Still forward audio while we wait out the silence window so
             * the tail of a word is not clipped. */
            if (voice_ever_detected && s_ctx.data_cb) {
                s_ctx.data_cb(dma_buf, samples_read);
            }

            if (voice_ever_detected &&
                (xTaskGetTickCount() - silence_since) >= silence_ticks) {
                ESP_LOGI(TAG, "VAD: silence timeout – stopping recording");
                break;
            }
        }
    }

    /* Update state under mutex */
    if (xSemaphoreTake(s_ctx.mutex, portMAX_DELAY) == pdTRUE) {
        s_ctx.state = AUDIO_STATE_IDLE;
        s_ctx.stop_recording = false;
        s_ctx.data_cb = NULL;
        xSemaphoreGive(s_ctx.mutex);
    }

    ESP_LOGI(TAG, "recording task finished");
    s_ctx.record_task = NULL;
    vTaskDelete(NULL);
}

/* ── I2S channel initialisation helpers ─────────────────────────────── */

static esp_err_t init_mic_channel(const orb_audio_config_t *cfg)
{
    i2s_chan_config_t chan_cfg = I2S_CHANNEL_DEFAULT_CONFIG(
        AUDIO_I2S_MIC_PORT, I2S_ROLE_MASTER);
    chan_cfg.dma_desc_num  = AUDIO_DMA_BUF_COUNT;
    chan_cfg.dma_frame_num = AUDIO_DMA_BUF_LEN / (AUDIO_BITS_PER_SAMPLE / 8);

    ESP_RETURN_ON_ERROR(
        i2s_new_channel(&chan_cfg, NULL, &s_ctx.mic_chan),
        TAG, "failed to create mic channel");

    i2s_std_config_t std_cfg = {
        .clk_cfg  = I2S_STD_CLK_DEFAULT_CONFIG(AUDIO_SAMPLE_RATE),
        .slot_cfg = I2S_STD_MSB_SLOT_DEFAULT_CONFIG(
            I2S_DATA_BIT_WIDTH_16BIT, I2S_SLOT_MODE_MONO),
        .gpio_cfg = {
            .mclk = I2S_GPIO_UNUSED,
            .bclk = cfg->mic_bck_io,
            .ws   = cfg->mic_ws_io,
            .dout = I2S_GPIO_UNUSED,
            .din  = cfg->mic_data_io,
            .invert_flags = {
                .mclk_inv = false,
                .bclk_inv = false,
                .ws_inv   = false,
            },
        },
    };

    ESP_RETURN_ON_ERROR(
        i2s_channel_init_std_mode(s_ctx.mic_chan, &std_cfg),
        TAG, "failed to init mic std mode");

    ESP_RETURN_ON_ERROR(
        i2s_channel_enable(s_ctx.mic_chan),
        TAG, "failed to enable mic channel");

    return ESP_OK;
}

static esp_err_t init_spk_channel(const orb_audio_config_t *cfg)
{
    i2s_chan_config_t chan_cfg = I2S_CHANNEL_DEFAULT_CONFIG(
        AUDIO_I2S_SPK_PORT, I2S_ROLE_MASTER);
    chan_cfg.dma_desc_num  = AUDIO_DMA_BUF_COUNT;
    chan_cfg.dma_frame_num = AUDIO_DMA_BUF_LEN / (AUDIO_BITS_PER_SAMPLE / 8);

    ESP_RETURN_ON_ERROR(
        i2s_new_channel(&chan_cfg, &s_ctx.spk_chan, NULL),
        TAG, "failed to create speaker channel");

    i2s_std_config_t std_cfg = {
        .clk_cfg  = I2S_STD_CLK_DEFAULT_CONFIG(AUDIO_SAMPLE_RATE),
        .slot_cfg = I2S_STD_MSB_SLOT_DEFAULT_CONFIG(
            I2S_DATA_BIT_WIDTH_16BIT, I2S_SLOT_MODE_MONO),
        .gpio_cfg = {
            .mclk = I2S_GPIO_UNUSED,
            .bclk = cfg->spk_bck_io,
            .ws   = cfg->spk_ws_io,
            .dout = cfg->spk_data_io,
            .din  = I2S_GPIO_UNUSED,
            .invert_flags = {
                .mclk_inv = false,
                .bclk_inv = false,
                .ws_inv   = false,
            },
        },
    };

    ESP_RETURN_ON_ERROR(
        i2s_channel_init_std_mode(s_ctx.spk_chan, &std_cfg),
        TAG, "failed to init speaker std mode");

    ESP_RETURN_ON_ERROR(
        i2s_channel_enable(s_ctx.spk_chan),
        TAG, "failed to enable speaker channel");

    return ESP_OK;
}

/* ── Public API ──────────────────────────────────────────────────────── */

esp_err_t orb_audio_init(const orb_audio_config_t *config)
{
    static const orb_audio_config_t defaults = {
        .mic_bck_io  = AUDIO_MIC_BCK_GPIO,
        .mic_ws_io   = AUDIO_MIC_WS_GPIO,
        .mic_data_io = AUDIO_MIC_DATA_GPIO,
        .spk_bck_io  = AUDIO_SPK_BCK_GPIO,
        .spk_ws_io   = AUDIO_SPK_WS_GPIO,
        .spk_data_io = AUDIO_SPK_DATA_GPIO,
    };

    const orb_audio_config_t *cfg = (config != NULL) ? config : &defaults;

    if (s_ctx.mutex == NULL) {
        s_ctx.mutex = xSemaphoreCreateMutex();
        if (s_ctx.mutex == NULL) {
            ESP_LOGE(TAG, "failed to create mutex");
            return ESP_ERR_NO_MEM;
        }
    }

    s_ctx.volume_pct = AUDIO_VOLUME_DEFAULT;
    s_ctx.state      = AUDIO_STATE_IDLE;

    ESP_RETURN_ON_ERROR(init_mic_channel(cfg), TAG, "mic init failed");
    ESP_RETURN_ON_ERROR(init_spk_channel(cfg), TAG, "spk init failed");

    ESP_LOGI(TAG, "audio initialised – mic I2S%d, spk I2S%d, %d Hz mono",
             AUDIO_I2S_MIC_PORT, AUDIO_I2S_SPK_PORT, AUDIO_SAMPLE_RATE);
    return ESP_OK;
}

esp_err_t orb_audio_start_recording(orb_audio_data_callback_t callback)
{
    if (callback == NULL) {
        return ESP_ERR_INVALID_ARG;
    }

    if (xSemaphoreTake(s_ctx.mutex, pdMS_TO_TICKS(200)) != pdTRUE) {
        return ESP_ERR_TIMEOUT;
    }

    if (s_ctx.state != AUDIO_STATE_IDLE) {
        xSemaphoreGive(s_ctx.mutex);
        ESP_LOGW(TAG, "start_recording called while state=%d", s_ctx.state);
        return ESP_ERR_INVALID_STATE;
    }

    s_ctx.data_cb        = callback;
    s_ctx.stop_recording = false;
    s_ctx.state          = AUDIO_STATE_LISTENING;
    xSemaphoreGive(s_ctx.mutex);

    BaseType_t created = xTaskCreate(recording_task,
                                     "orb_record",
                                     RECORD_TASK_STACK,
                                     NULL,
                                     RECORD_TASK_PRIO,
                                     &s_ctx.record_task);
    if (created != pdPASS) {
        xSemaphoreTake(s_ctx.mutex, portMAX_DELAY);
        s_ctx.state  = AUDIO_STATE_IDLE;
        s_ctx.data_cb = NULL;
        xSemaphoreGive(s_ctx.mutex);
        ESP_LOGE(TAG, "failed to create recording task");
        return ESP_ERR_NO_MEM;
    }

    ESP_LOGI(TAG, "recording started");
    return ESP_OK;
}

esp_err_t orb_audio_stop_recording(void)
{
    if (xSemaphoreTake(s_ctx.mutex, pdMS_TO_TICKS(200)) != pdTRUE) {
        return ESP_ERR_TIMEOUT;
    }

    if (s_ctx.state != AUDIO_STATE_LISTENING) {
        xSemaphoreGive(s_ctx.mutex);
        return ESP_OK;
    }

    s_ctx.stop_recording = true;
    xSemaphoreGive(s_ctx.mutex);

    /* Give the task time to finish its current DMA read and exit cleanly. */
    uint32_t waited_ms = 0;
    while (s_ctx.record_task != NULL && waited_ms < 2000) {
        vTaskDelay(pdMS_TO_TICKS(10));
        waited_ms += 10;
    }

    ESP_LOGI(TAG, "recording stopped");
    return ESP_OK;
}

esp_err_t orb_audio_play_samples(const int16_t *samples, size_t count)
{
    if (samples == NULL || count == 0) {
        return ESP_ERR_INVALID_ARG;
    }
    if (s_ctx.spk_chan == NULL) {
        return ESP_ERR_INVALID_STATE;
    }

    /* Work on a stack-local copy so we can apply volume without touching the
     * caller's buffer.  Process in chunks to avoid large stack allocations. */
    const size_t CHUNK = 256;
    int16_t tmp[CHUNK];

    if (xSemaphoreTake(s_ctx.mutex, pdMS_TO_TICKS(200)) != pdTRUE) {
        return ESP_ERR_TIMEOUT;
    }
    if (s_ctx.state == AUDIO_STATE_LISTENING) {
        xSemaphoreGive(s_ctx.mutex);
        ESP_LOGW(TAG, "play_samples called while recording – ignoring");
        return ESP_ERR_INVALID_STATE;
    }
    s_ctx.state = AUDIO_STATE_PLAYING;
    uint8_t vol = s_ctx.volume_pct;
    xSemaphoreGive(s_ctx.mutex);

    esp_err_t ret = ESP_OK;
    size_t offset = 0;

    while (offset < count) {
        size_t chunk_samples = count - offset;
        if (chunk_samples > CHUNK) chunk_samples = CHUNK;

        memcpy(tmp, samples + offset, chunk_samples * sizeof(int16_t));
        apply_volume(tmp, chunk_samples, vol);

        size_t bytes_written = 0;
        ret = i2s_channel_write(s_ctx.spk_chan,
                                tmp,
                                chunk_samples * sizeof(int16_t),
                                &bytes_written,
                                pdMS_TO_TICKS(500));
        if (ret != ESP_OK) {
            ESP_LOGE(TAG, "i2s_channel_write error: %s", esp_err_to_name(ret));
            break;
        }
        offset += chunk_samples;
    }

    xSemaphoreTake(s_ctx.mutex, portMAX_DELAY);
    if (s_ctx.state == AUDIO_STATE_PLAYING) {
        s_ctx.state = AUDIO_STATE_IDLE;
    }
    xSemaphoreGive(s_ctx.mutex);

    return ret;
}

esp_err_t orb_audio_set_volume(uint8_t percent)
{
    if (percent > 100) percent = 100;

    if (xSemaphoreTake(s_ctx.mutex, pdMS_TO_TICKS(200)) != pdTRUE) {
        return ESP_ERR_TIMEOUT;
    }
    s_ctx.volume_pct = percent;
    xSemaphoreGive(s_ctx.mutex);

    ESP_LOGI(TAG, "volume set to %u%%", percent);
    return ESP_OK;
}

orb_audio_state_t orb_audio_get_state(void)
{
    orb_audio_state_t state;
    if (xSemaphoreTake(s_ctx.mutex, pdMS_TO_TICKS(100)) == pdTRUE) {
        state = s_ctx.state;
        xSemaphoreGive(s_ctx.mutex);
    } else {
        state = AUDIO_STATE_IDLE;
    }
    return state;
}

void orb_audio_deinit(void)
{
    orb_audio_stop_recording();

    if (s_ctx.mic_chan) {
        i2s_channel_disable(s_ctx.mic_chan);
        i2s_del_channel(s_ctx.mic_chan);
        s_ctx.mic_chan = NULL;
    }

    if (s_ctx.spk_chan) {
        i2s_channel_disable(s_ctx.spk_chan);
        i2s_del_channel(s_ctx.spk_chan);
        s_ctx.spk_chan = NULL;
    }

    if (s_ctx.mutex) {
        vSemaphoreDelete(s_ctx.mutex);
        s_ctx.mutex = NULL;
    }

    s_ctx.state = AUDIO_STATE_IDLE;
    ESP_LOGI(TAG, "audio deinitialized");
}
