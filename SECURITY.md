# Security Guide for ${PROJECT_NAME}

This guide covers security best practices for ESP32 applications, including NVS encryption, Secure Boot, TLS/SSL, and flash encryption.

## Table of Contents
1. [NVS (Non-Volatile Storage) Encryption](#nvs-encryption)
2. [Secure Boot](#secure-boot)
3. [Flash Encryption](#flash-encryption)
4. [TLS/SSL Communication](#tlsssl-communication)
5. [Production Checklist](#production-checklist)

---

## NVS Encryption

**Use Case**: Store sensitive configuration, credentials, or API keys safely in NVS.

### Configuration
1. Update `sdkconfig.defaults`:
   ```
   CONFIG_NVS_ENCRYPTION_KEY_SIZE=24
   CONFIG_NVS_ENCRYPTION_ENABLED=y
   ```

2. Generate encryption key (one-time setup on first boot):
   ```c
   #include "nvs_flash.h"
   #include "nvs_sec.h"
   
   nvs_sec_config_t cfg = {};
   nvs_flash_generate_keys(&cfg);
   nvs_flash_secure_init(&cfg);
   ```

3. Store sensitive data:
   ```c
   nvs_handle_t handle;
   nvs_open("${PROJECT_NAME}", NVS_READWRITE, &handle);
   
   // Write encrypted string
   nvs_set_str(handle, "api_key", "your_secret_key");
   nvs_commit(handle);
   ```

### Reference
- [ESP-IDF NVS Documentation](https://docs.espressif.com/projects/esp-idf/en/latest/esp32/api-reference/storage/nvs_flash.html)

---

## Secure Boot

**Purpose**: Verify firmware integrity and authenticity on every boot.

### Prerequisites
- Secure Boot requires Secure Bootloader
- Only available on ESP32, ESP32-S2, ESP32-S3, ESP32-C3, ESP32-C6
- **One-time setup**: After enabling, you cannot disable without device hardmod

### Enable Secure Boot V2
1. **Generate keys** (one-time):
   ```bash
   idf.py secure-pad-and-sign-keyblock -k secure_boot_signing_key.pem
   ```

2. **Configure SDK**:
   ```ini
   # In sdkconfig.defaults
   CONFIG_SECURE_BOOT_V2_ENABLED=y
   CONFIG_SECURE_BOOT_V2_PREFERRED=y
   ```

3. **Build and flash**:
   ```bash
   idf.py build
   idf.py secure-flash-bootloader
   ```

### ⚠️ Important
- **Back up your signing key!** Loss = device becomes unrecoverable
- Keep key file in secure location (not in repository)
- Each device needs its own secure boot to be enabled only once

### Reference
- [Secure Boot Documentation](https://docs.espressif.com/projects/esp-idf/en/latest/esp32/security/secure-boot-v2.html)

---

## Flash Encryption

**Purpose**: Encrypt firmware and data at rest on flash memory.

### Enable Flash Encryption
1. **Configure SDK**:
   ```ini
   CONFIG_SECURE_FLASH_ENC_ENABLED=y
   CONFIG_SECURE_FLASH_ENC_MODE=DEVELOPMENT  # Use RELEASE for production
   ```

2. **First Boot Requirement**:
   On first boot, the device will generate encryption keys automatically (DEVELOPMENT mode).

3. **Production Setup** (RELEASE mode):
   - Keys are never generated automatically
   - You must pre-generate keys using `esptool.py`:
     ```bash
     esptool.py --port COM3 burn_key_digest secure_boot_key.bin
     ```

### Release Mode vs Development Mode
| Mode | Auto-generate Keys | Secure | Use Case |
|------|------------------|--------|----------|
| DEVELOPMENT | ✅ Yes | ⚠️ Low | Testing & Development |
| RELEASE | ❌ No | ✅ High | Production |

### Reference
- [Flash Encryption Documentation](https://docs.espressif.com/projects/esp-idf/en/latest/esp32/security/flash-encryption.html)

---

## TLS/SSL Communication

**Purpose**: Secure communication with cloud services or APIs.

### Using ESP-TLS (Recommended)
```c
#include "esp_tls.h"

const char *DEFAULT_SERVER_URL = "https://api.example.com";

static void https_request_task(void *pvParameters)
{
    esp_tls_cfg_t cfg = {
        .cacert_buf = (const unsigned char *)server_root_cert_pem_start,
        .cacert_bytes = server_root_cert_pem_end - server_root_cert_pem_start,
    };

    esp_tls_t *tls = esp_tls_conn_new_sync(DEFAULT_SERVER_URL, NULL, &cfg);
    
    if (!tls) {
        ESP_LOGE(TAG, "Failed to establish TLS connection");
        return;
    }

    const char *REQUEST = "GET / HTTP/1.1\r\nHost: api.example.com\r\n\r\n";
    if (esp_tls_conn_write(tls, (const char *)REQUEST, strlen(REQUEST)) <= 0) {
        ESP_LOGE(TAG, "Failed to write data");
    }

    esp_tls_conn_delete(tls);
    vTaskDelete(NULL);
}
```

### Certificate Management
1. **Obtain root CA certificate** (from your API provider)
2. **Convert to `.pem` format** if needed
3. **Include in your firmware**:
   - Store in `src/certs/` directory
   - Add to `CMakeLists.txt` with `embed_files`

### Reference
- [ESP-TLS Documentation](https://docs.espressif.com/projects/esp-idf/en/latest/esp32/api-reference/protocols/esp_tls.html)

---

## Secure Coding Practices

### 1. Input Validation
```c
// Always validate external input
if (strlen(user_input) > MAX_INPUT_SIZE) {
    ESP_LOGE(TAG, "Input exceeded maximum size");
    return ESP_ERR_INVALID_ARG;
}
```

### 2. Memory Security
```c
// Clear sensitive data before freeing
void secure_free(char *ptr, size_t size)
{
    if (ptr) {
        memset(ptr, 0, size);  // Zero out memory
        free(ptr);
    }
}
```

### 3. Error Handling
```c
// Log errors but don't expose sensitive info
if (esp_err != ESP_OK) {
    ESP_LOGE(TAG, "Operation failed: %s", esp_err_to_name(esp_err));
    // Don't log: password, API key, token, etc.
}
```

### 4. Disable Debug Mode in Production
```c
// In sdkconfig.defaults for production:
CONFIG_LOG_MAXIMUM_LEVEL=2  // Only ERRORS + WARNINGS
CONFIG_ESP_SYSTEM_EVENT_QUEUE_SIZE=16
```

---

## Production Checklist

Before deploying to production:

- [ ] **NVS Encryption**: Enable if storing secrets
  - [ ] Run `nvs_flash_generate_keys()` on first boot
  - [ ] Test reading/writing encrypted values

- [ ] **Secure Boot V2**: Enable for firmware integrity
  - [ ] Generate and back up signing keys
  - [ ] Securely distribute keys (not in firmware)
  - [ ] Test on development device first

- [ ] **Flash Encryption**: Enable for data-at-rest protection
  - [ ] Use RELEASE mode (not DEVELOPMENT)
  - [ ] Pre-generate keys in secure environment
  - [ ] Never lose the key file!

- [ ] **TLS/SSL**: Verify HTTPS connections
  - [ ] Test with valid and invalid certificates
  - [ ] Validate certificate chain
  - [ ] Test with root CA updates

- [ ] **Logging**: Disable debug logs
  - [ ] Set `CONFIG_LOG_MAXIMUM_LEVEL=2` (errors only)
  - [ ] Verify no sensitive data in logs

- [ ] **Firmware Updates**: Plan for OTA (Over-The-Air)
  - [ ] Sign firmware with Secure Boot keys
  - [ ] Use secure update protocol (HTTPS)
  - [ ] Test rollback scenarios

- [ ] **Testing**: Run security validation
  - [ ] Attempt invalid firmware flashing
  - [ ] Try reading protected NVS entries
  - [ ] Verify TLS rejects untrusted certificates

---

## Support & Resources
- [ESP-IDF Security Documentation](https://docs.espressif.com/projects/esp-idf/en/latest/esp32/security/index.html)
- [Espressif Security Advisory](https://www.espressif.com/en/support/download/security-advisories)
- [OWASP IoT Security](https://owasp.org/www-project-iot-security/)

---

**Last Updated**: 2026-04-03  
**Template Version**: 0.1.0
