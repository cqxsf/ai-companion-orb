idf_component_register(
    SRCS "orb_audio.c"
    INCLUDE_DIRS "include"
    REQUIRES driver esp_timer freertos
)
