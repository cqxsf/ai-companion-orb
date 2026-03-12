idf_component_register(
    SRCS "orb_ota.c"
    INCLUDE_DIRS "include"
    REQUIRES esp_https_ota app_update esp_http_client esp_timer
)
