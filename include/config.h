#ifndef CONFIG_H
#define CONFIG_H

#include "sdkconfig.h"
#include "esp_log.h"

// ============================================================================
// GPIO Pin Configuration
// ============================================================================
// Adjust these pins based on your hardware
#define GPIO_LED        2   // LED pin (change as needed)
#define GPIO_BUTTON     0   // Button pin (change as needed)

// ============================================================================
// FreeRTOS Configuration
// ============================================================================
// Frueher standen hier CONFIG_APP_*-Werte \"from sdkconfig\" - die gibt es in
// diesem Projekt aber nicht (kein Kconfig-Eintrag), das ergab einen
// Compilerfehler (\"CONFIG_APP_STACK_SIZE undeclared\").
// ACHTUNG: Stackgroessen sind BYTES, nicht Woerter.
#define APP_TASK_STACK_SIZE  4096   // Task stack size (bytes)
#define APP_TASK_PRIORITY    5      // Task priority (0-24, higher = more important)
#define APP_TASK_CORE        1      // Core affinity (0, 1, or tskNO_AFFINITY)

// ============================================================================
// NVS Configuration
// ============================================================================
#define NVS_NAMESPACE "${PROJECT_NAME}"
#define NVS_STORE_NAME "config"

// ============================================================================
// Application Defaults
// ============================================================================
// APP_VERSION_MAJOR / APP_VERSION_MINOR werden von tools/increment_build.py
// gelesen; die Build-Nummer kommt aus .build_number und landet in
// include/version.h (APP_VERSION_STRING, BUILD_NUMBER, BUILD_TIMESTAMP).
// Bei Aenderung von MAJOR oder MINOR faengt die Build-Nummer wieder bei 0 an.
#define APP_VERSION_MAJOR   0
#define APP_VERSION_MINOR   1
#define APP_VERSION "0.1.0"
#define APP_LOGLEVEL ESP_LOG_INFO  // esp_log_level_t aus esp_log.h

// ============================================================================
// Security Configuration (optional)
// ============================================================================
// TLS: Configure your certificates here
// #define USE_TLS_CERTIFICATE 1
// #define TLS_CERT_FILE "certificates/ca-cert.pem"

// ============================================================================
// Logging Configuration
// ============================================================================
// #define LOG_LOCAL_LEVEL ESP_LOG_DEBUG

#endif // CONFIG_H
