idf_component_register(
    SRCS "app_main.c"
    INCLUDE_DIRS "."
    REQUIRES led_engine touch_sensor audio wifi_manager ble_provision ota
)
