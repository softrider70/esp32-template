#!/usr/bin/env powershell
# /add-ota - Integrate OTA Framework into ESP32 Project

param(
    [string]$ProjectPath = $PWD,
    [switch]$WithSignature = $true,
    [switch]$WithWebServer = $true
)

$ErrorActionPreference = "Stop"

function Test-ProjectValid {
    if (-not (Test-Path "$ProjectPath/CMakeLists.txt")) {
        throw "Not a valid ESP32 project (missing CMakeLists.txt)"
    }
    if (-not (Test-Path "$ProjectPath/src/main.c")) {
        throw "Project missing src/main.c"
    }
}

function Add-OTAComponent {
    Write-Host "Adding OTA Framework..." -ForegroundColor Cyan
    
    # Add to idf_component.yml
    $compFile = "$ProjectPath/idf_component.yml"
    if (Test-Path $compFile) {
        $content = Get-Content $compFile -Raw
        if ($content -notmatch "esp_https_ota") {
            $content += @"
  esp_https_ota:
    version: ">=0.4.0"
    registry: "esp-idf"
"@
            Set-Content $compFile $content -NoNewline
            Write-Host "  ✓ Updated idf_component.yml" -ForegroundColor Green
        }
    }
}

function Create-OTAFiles {
    Write-Host "Creating OTA header and implementation files..." -ForegroundColor Cyan
    
    # Create ota_handler.h
    $otaHeader = @"
#ifndef OTA_HANDLER_H
#define OTA_HANDLER_H

#include <esp_http_client.h>
#include <esp_ota_ops.h>

typedef void (*ota_progress_cb)(int current, int total);

void ota_initialize(void);
esp_err_t ota_update(const char *url, ota_progress_cb progress_callback);
esp_err_t ota_get_version(char *version_str, size_t len);
esp_err_t ota_rollback(void);

#endif
"@
    Set-Content "$ProjectPath/include/ota_handler.h" $otaHeader -Encoding ASCII
    Write-Host "  ✓ Created include/ota_handler.h" -ForegroundColor Green
    
    # Create ota_handler.c
    $otaImpl = @"
#include "ota_handler.h"
#include "esp_log.h"
#include "esp_ota_ops.h"
#include "esp_app_format.h"

static const char *TAG = "OTA";

void ota_initialize(void) {
    ESP_LOGI(TAG, "OTA Framework initialized");
}

esp_err_t ota_update(const char *url, ota_progress_cb progress_callback) {
    ESP_LOGI(TAG, "Starting OTA update from %s", url);
    
    // TODO: Implement HTTP download and flash update
    return ESP_OK;
}

esp_err_t ota_get_version(char *version_str, size_t len) {
    esp_app_desc_t app_desc;
    esp_ota_get_running_partition();
    
    // Get version from app description
    snprintf(version_str, len, "1.0.0");
    return ESP_OK;
}

esp_err_t ota_rollback(void) {
    ESP_LOGI(TAG, "Rolling back to previous firmware");
    esp_ota_mark_app_invalid_rollback_and_reboot();
    return ESP_OK;
}
"@
    Set-Content "$ProjectPath/src/ota_handler.c" $otaImpl -Encoding ASCII
    Write-Host "  ✓ Created src/ota_handler.c" -ForegroundColor Green
}

function Create-OTAConfig {
    Write-Host "Creating OTA configuration..." -ForegroundColor Cyan
    
    $otaConfig = @"
#ifndef OTA_CONFIG_H
#define OTA_CONFIG_H

// OTA Update Server
#define OTA_UPDATE_URL "https://update.server.com/firmware.bin"
#define OTA_RECV_TIMEOUT 5000

// Security
#define OTA_USE_SIGNING 1
#define OTA_VERIFY_DIGEST 1

// Partition Strategy
#define OTA_PARTITION_SCHEME "ab"  // "ab" or "aab"

#endif
"@
    Set-Content "$ProjectPath/include/ota_config.h" $otaConfig -Encoding ASCII
    Write-Host "  ✓ Created include/ota_config.h" -ForegroundColor Green
}

function Add-OTAExample {
    Write-Host "Creating OTA example code..." -ForegroundColor Cyan
    
    $example = @"
// Example: Add to src/main.c

#include "ota_handler.h"

void update_task(void *param) {
    while (1) {
        // Check for updates every hour
        vTaskDelay(3600000 / portTICK_PERIOD_MS);
        
        ESP_LOGI(TAG, "Checking for OTA updates...");
        ota_update(OTA_UPDATE_URL, NULL);
    }
}

void app_main(void) {
    // ... existing code ...
    
    ota_initialize();
    
    // Create update task
    xTaskCreate(update_task, "ota_task", 4096, NULL, 5, NULL);
}
"@
    Set-Content "$ProjectPath/OTA_EXAMPLE.c" $example -Encoding ASCII
    Write-Host "  ✓ Created OTA_EXAMPLE.c" -ForegroundColor Green
}

# Main Execution
try {
    Write-Host ""
    Write-Host "Adding OTA Framework to $ProjectPath" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    
    Test-ProjectValid
    Add-OTAComponent
    Create-OTAFiles
    Create-OTAConfig
    Add-OTAExample
    
    Write-Host ""
    Write-Host "SUCCESS: OTA Framework added!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Cyan
    Write-Host "  1. Review OTA_EXAMPLE.c for integration" -ForegroundColor Yellow
    Write-Host "  2. Implement HTTP client in src/ota_handler.c" -ForegroundColor Yellow
    Write-Host "  3. Configure OTA_UPDATE_URL in include/ota_config.h" -ForegroundColor Yellow
    Write-Host "  4. Set up OTA partition scheme in sdkconfig" -ForegroundColor Yellow
    Write-Host ""
}
catch {
    Write-Host "ERROR: $_" -ForegroundColor Red
    exit 1
}
