idf_component_register(
    SRCS "main.c"
    INCLUDE_DIRS "../include"
    # Nur was nicht ohnehin automatisch dabei ist: freertos, log, esp_system,
    # esp_common und hal sind Common-Requires. "esp_log" gibt es in ESP-IDF 6.1
    # NICHT als Komponente - der Header esp_log.h kommt aus "log".
    REQUIRES nvs_flash
)

# ---------------------------------------------------------------------------
# Build-Zaehler: bei jedem Build eins hochzaehlen und include/version.h neu
# schreiben (tools/increment_build.py, liest APP_VERSION_MAJOR/MINOR aus
# include/config.h). main.c meldet BUILD_NUMBER im Log, damit nach mehreren
# Flashvorgaengen erkennbar bleibt, welcher Stand laeuft.
# ---------------------------------------------------------------------------
find_package(Python3 COMPONENTS Interpreter)
if(NOT Python3_Interpreter_FOUND)
    set(Python3_EXECUTABLE python)
endif()

add_custom_target(app_version ALL
    COMMAND ${Python3_EXECUTABLE} ${CMAKE_SOURCE_DIR}/tools/increment_build.py
            --project-dir ${CMAKE_SOURCE_DIR}
    BYPRODUCTS ${CMAKE_SOURCE_DIR}/include/version.h
    COMMENT "Build-Zaehler erhoehen und include/version.h erzeugen"
    VERBATIM
)

add_dependencies(${COMPONENT_LIB} app_version)
