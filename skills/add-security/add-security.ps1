#!/usr/bin/env powershell
# /add-security - Security Features Setup

param(
    [switch]$EnableSecureBoot = $false,
    [switch]$EnableNVSEncryption = $false,
    [switch]$GenerateKeys = $false,
    [switch]$ShowStatus = $false
)

$ErrorActionPreference = "Stop"

function Test-ProjectValid {
    if (-not (Test-Path "CMakeLists.txt")) {
        throw "Not a valid ESP project (missing CMakeLists.txt)"
    }
}

function Create-SecurityHeaders {
    Write-Host "Creating security configuration headers..." -ForegroundColor Cyan
    
    $securityConfig = @"
#ifndef SECURITY_CONFIG_H
#define SECURITY_CONFIG_H

// Secure Boot Settings
#define SECURE_BOOT_ENABLED 1
#define SECURE_BOOT_VERSION 2

// NVS Encryption
#define NVS_ENCRYPTION_ENABLED 1

// TLS Settings
#define TLS_MINIMUM_VERSION TLS_VERSION_1_3
#define TLS_CERTIFICATE_BUNDLE 1

// WiFi Security
#define WPA3_ENABLED 1
#define WPA2_ENABLED 1

// Disable Debug Features in Production
#define NDEBUG 1
#define UART_DOWNLOAD_DISABLED 1

#endif
"@
    
    if (-not (Test-Path "include")) {
        New-Item -Path "include" -ItemType Directory | Out-Null
    }
    
    Set-Content "include/security_config.h" $securityConfig -Encoding ASCII
    Write-Host "  ✓ Created include/security_config.h" -ForegroundColor Green
}

function Create-SecurityGuide {
    Write-Host "Creating security implementation guide..." -ForegroundColor Cyan
    
    $guide = @"
# Security Implementation Guide

## Secure Boot V2 Setup

1. Generate signing key:
   espsecure.py generate_signing_key secure_boot.key

2. Burn key hash to eFuse:
   espefuse.py burn_key SEC_SECURE_BOOT_KEY0 secure_boot.key

3. Enable Secure Boot:
   idf.py menuconfig
   → Security Features
     → [*] Enable Secure Boot V2
     → [*] Verify app signature

4. Build and flash:
   idf.py build flashfs flash

## NVS Encryption

1. Enable in menuconfig:
   → Security Features
     → [*] Enable NVS Encryption

2. Use in code:
   nvs_sec_cfg_t cfg;
   esp_err_t ret = nvs_sec_cfg_init(&cfg);
   nvs_flash_secure_init_partition("nvs", &cfg);

## TLS Configuration

Root CA for HTTPS:
extern const uint8_t rootca_pem_start[] 
    asm("_binary_rootca_pem_start");

## ⚠️ IMPORTANT WARNINGS

❌ DO NOT commit keys to Git
❌ DO NOT skip signature verification
❌ DO NOT reuse keys across projects
❌ DO NOT disable secure boot for production

✅ DO keep keys in secure location
✅ DO enable all security features for production
✅ DO test on multiple devices
✅ DO keep firmware versions tracked
"@
    
    Set-Content "SECURITY_GUIDE.md" $guide -Encoding ASCII
    Write-Host "  ✓ Created SECURITY_GUIDE.md" -ForegroundColor Green
}

function Create-SecurityKeyDirectory {
    Write-Host "Creating keys directory structure..." -ForegroundColor Cyan
    
    if (-not (Test-Path "keys")) {
        New-Item -Path "keys" -ItemType Directory | Out-Null
        Write-Host "  ✓ Created keys/ directory" -ForegroundColor Green
    }
    
    $keyreadme = @"
# Security Keys

⚠️ **IMPORTANT**: This directory contains sensitive cryptographic material!

## Files
- `secure_boot.key` - Private key for Secure Boot V2 (DO NOT SHARE!)
- `secure_boot.key.pub` - Public key (can be shared)
- `rootca.pem` - Root CA certificate for HTTPS
- `device.key.pem` - Device private key
- `device.crt.pem` - Device certificate

## Security Practices
1. Never commit private keys to Git
2. Use .gitignore to exclude *.key files
3. Store keys in encrypted format when at rest
4. Rotate keys periodically
5. Use different keys for development vs. production

## Key Generation
\`\`\`bash
# Secure Boot Key
espsecure.py generate_signing_key secure_boot.key

# Root CA (for HTTPS)
openssl req -new -x509 -days 3650 -nodes -out rootca.pem -keyout rootca-key.pem

# Device Certificate
openssl req -new -key device.key.pem -out device.csr
openssl x509 -req -in device.csr -CA rootca.pem -CAkey rootca-key.pem -CAcreateserial -out device.crt.pem -days 3650
\`\`\`
"@
    
    Set-Content "keys/README.md" $keyreadme -Encoding ASCII
    Write-Host "  ✓ Created keys/README.md" -ForegroundColor Green
}

function Create-SecurityExample {
    Write-Host "Creating security implementation example..." -ForegroundColor Cyan
    
    $example = @"
// Security Implementation Example

#include "security_config.h"
#include "nvs_flash.h"
#include "esp_tls.h"

void setup_security(void) {
    // Initialize NVS with encryption
    nvs_sec_cfg_t cfg;
    esp_err_t ret = nvs_sec_cfg_init(&cfg);
    if (ret == ESP_ERR_NVS_KEYS_NOT_INIT) {
        // Generate new encryption keys
        ret = nvs_flash_secure_init();
    }
    
    // Setup TLS configuration
    esp_tls_cfg_t tls_cfg = {
        .crt_bundle_attach = esp_crt_bundle_attach,
        .skip_cert_common_name_check = false,
    };
    
    ESP_LOGI(TAG, "Security features initialized");
}

// Store secure data in NVS
void store_secret(const char *key, const char *value) {
    nvs_handle_t handle;
    nvs_open("storage", NVS_READWRITE, &handle);
    nvs_set_str(handle, key, value);
    nvs_commit(handle);
    nvs_close(handle);
}

// Retrieve secure data from NVS
void retrieve_secret(const char *key, char *value, size_t len) {
    nvs_handle_t handle;
    nvs_open("storage", NVS_READONLY, &handle);
    nvs_get_str(handle, key, value, &len);
    nvs_close(handle);
}
"@
    
    Set-Content "SECURITY_EXAMPLE.c" $example -Encoding ASCII
    Write-Host "  ✓ Created SECURITY_EXAMPLE.c" -ForegroundColor Green
}

# Main Execution
try {
    Write-Host ""
    Write-Host "Security Features Setup for ESP32" -ForegroundColor Cyan
    Write-Host "====================================" -ForegroundColor Cyan
    Write-Host ""
    
    Test-ProjectValid
    
    if ($ShowStatus) {
        Write-Host "Project Security Status:" -ForegroundColor Cyan
        Write-Host "  ✓ Security headers ready: $(Test-Path 'include/security_config.h')" -ForegroundColor Green
        Write-Host "  ✓ Keys directory: $(Test-Path 'keys')" -ForegroundColor Green
        Write-Host "  ✓ Examples: $(Test-Path 'SECURITY_EXAMPLE.c')" -ForegroundColor Green
        exit 0
    }
    
    Write-Host "Adding security infrastructure..." -ForegroundColor Cyan
    
    Create-SecurityHeaders
    Create-SecurityGuide
    Create-SecurityKeyDirectory
    Create-SecurityExample
    
    Write-Host ""
    Write-Host "SUCCESS: Security features added!" -ForegroundColor Green
    Write-Host ""
    Write-Host "⚠️  Next steps (READ CAREFULLY):" -ForegroundColor Yellow
    Write-Host "  1. Review SECURITY_GUIDE.md" -ForegroundColor White
    Write-Host "  2. Generate keys: espsecure.py generate_signing_key keys/secure_boot.key" -ForegroundColor White
    Write-Host "  3. Configure in menuconfig: idf.py menuconfig" -ForegroundColor White
    Write-Host "  4. Integrate SECURITY_EXAMPLE.c into your code" -ForegroundColor White
    Write-Host "  5. ADD keys/*.key to .gitignore (IMPORTANT!)" -ForegroundColor Red
    Write-Host ""
    Write-Host "⚠️  REMINDER: Secure Boot is IRREVERSIBLE!" -ForegroundColor Red
    Write-Host ""
}
catch {
    Write-Host "ERROR: $_" -ForegroundColor Red
    exit 1
}
