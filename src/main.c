#include <stdio.h>
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "esp_log.h"
#include "esp_system.h"
#include "nvs_flash.h"
#include "nvs.h"
#include "config.h"
#include "version.h"
#include "esp_chip_info.h"

static const char *TAG = "${PROJECT_NAME}";

// NVS handle for persistent storage
/* NICHT "nvs_handle" nennen: der Name kollidiert mit dem Typ und der Compiler
 * meldet "redeclared as different kind of symbol". */
nvs_handle_t g_nvs_handle;

/**
 * @brief Initialize NVS (Non-Volatile Storage)
 */
static esp_err_t init_nvs(void)
{
    esp_err_t ret = nvs_flash_init();
    if (ret == ESP_ERR_NVS_NO_FREE_PAGES || ret == ESP_ERR_NVS_NEW_VERSION_FOUND) {
        ESP_LOGW(TAG, "NVS partition invalid, erasing...");
        ESP_ERROR_CHECK(nvs_flash_erase());
        ret = nvs_flash_init();
    }
    ESP_ERROR_CHECK(ret);
    
    ret = nvs_open("${PROJECT_NAME}", NVS_READWRITE, &g_nvs_handle);
    if (ret != ESP_OK) {
        ESP_LOGE(TAG, "Failed to open NVS handle: %s", esp_err_to_name(ret));
        return ret;
    }
    
    return ESP_OK;
}

/**
 * @brief FreeRTOS task - Main application logic
 */
static void app_task(void *pvParameters)
{
    ESP_LOGI(TAG, "Application task started");
    
    // Initialize configuration
    // config_init();  // Uncomment when config.h is implemented
    
    // Main application loop
    for (int i = 0; ; i++) {
        ESP_LOGI(TAG, "Task running [%d]", i);
        vTaskDelay(pdMS_TO_TICKS(5000));  // 5 second delay
        
        // TODO: Add your application logic here
    }
    
    vTaskDelete(NULL);
}

/**
 * @brief Application entry point
 */
void app_main(void)
{
    ESP_LOGI(TAG, "ESP32 Template Application Started");
    ESP_LOGI(TAG, "Project: ${PROJECT_NAME}");
    /* Build-Nummer sichtbar machen: sie steht in include/version.h, das bei
     * jedem Build neu erzeugt wird. So laesst sich nach mehreren
     * Flashvorgaengen sagen, welcher Stand laeuft. */
    ESP_LOGI(TAG, "%s bereit - Build %d", APP_VERSION_STRING, BUILD_NUMBER);
    
    // Initialize NVS
    if (init_nvs() != ESP_OK) {
        ESP_LOGE(TAG, "NVS initialization failed, halting");
        return;
    }
    
    // Print system info
    /* esp_chip_revision() gibt es in ESP-IDF 6.1 nicht mehr - dafuer
     * esp_chip_info(). */
    esp_chip_info_t chip_info;
    esp_chip_info(&chip_info);
    ESP_LOGI(TAG, "Chip: %d Kerne, Revision %d", chip_info.cores, chip_info.revision);
    ESP_LOGI(TAG, "Free heap: %u bytes", esp_get_free_heap_size());
    ESP_LOGI(TAG, "Minimum free heap (ever): %u bytes", esp_get_minimum_free_heap_size());
    
    // Create main application task
    BaseType_t ret = xTaskCreate(
        app_task,              // Task function
        "${PROJECT_NAME}_app", // Task name
        APP_TASK_STACK_SIZE,   // Stack size (bytes, NICHT Woerter!)
        NULL,                  // Task parameter
        APP_TASK_PRIORITY,     // Task priority
        NULL                   // Task handle
    );
    
    if (ret != pdPASS) {
        ESP_LOGE(TAG, "Failed to create application task");
    }
}
