idf_component_register(
    SRCS ""
    INCLUDE_DIRS "include"
    REQUIRES driver esp_log nvs_flash
)
# TODO: 替换 SRCS "" 为 "orb_sensor.c" 待实现后
