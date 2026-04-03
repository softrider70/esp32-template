# /add-security - Security Features Setup

## Beschreibung

Rüstet dein ESP32-Projekt mit Sicherheitsfeatures aus: Secure Boot, NVS-Verschlüsselung, TLS/SSL-Zertifikate und HAC (Hardware-based Attestation).

## Funktionalität

Fügt hinzu:
- Secure Boot V2 (Signatur-Verifikation)
- NVS Partition Encryption
- TLS/SSL Zertifikat-Management
- Hardware Security Module Integration
- WPA3 WiFi Security
- Secure OTA mit Signaturen

## Installation

```bash
/add-security
```

## Features

### 1. Secure Boot V2
```bash
# Private Key generieren
espsecure.py generate_signing_key secure_boot.key

# Bootloader signieren
espsecure.py sign secure_boot secure_boot.key bootloader.bin
```

### 2. NVS Encryption
```c
#include "nvs_flash.h"

// Keys automatisch in eFuse gespeichert
nvs_sec_cfg_t cfg;
esp_err_t ret = nvs_sec_cfg_init(&cfg);
nvs_flash_secure_init_partition("nvs", &cfg);
```

### 3. TLS Zertifikate
```c
#include "esp_tls.h"

// Root CA für HTTPS
extern const uint8_t rootca_pem_start[] 
    asm("_binary_rootca_pem_start");
extern const uint8_t rootca_pem_end[] 
    asm("_binary_rootca_pem_end");
```

### 4. Hardware Security
```c
// Private Keys in eFuse
esp_secure_cert_uart_disabled_in_efuse();
esp_secure_boot_verify_signature(__builtin_frame_address(0), (char *)esp_app_get_elf_sha256_str());
```

## Architektur

```
security/
├── keys/
│   ├── secure_boot.key (Private)
│   ├── rootca.pem
│   └── cert.pem
├── nvs_crypto.c
├── tls_config.h
└── security_utils.c
```

## Konfiguration

Editiere `menuconfig` Einträge:
```bash
idf.py menuconfig
# → Security Features
#   ├── [x] Enable Secure Boot V2
#   ├── [x] Enable NVS Encryption
#   ├── [x] Disable UART Download Mode
#   └── [x] Hardware Attestation
```

## Sicherheits-Layers

| Layer | Komponente | Status |
|-------|------------|--------|
| Boot | Secure Boot V2 | ✅ |
| Storage | NVS Encryption | ✅ |
| Network | TLS 1.3 | ✅ |
| OTA | Signature Verify | ✅ |
| Hardware | eFuse Lock | ✅ |

## CLI-Optionen

```bash
/add-security
  --enable-secure-boot    Secure Boot V2 aktivieren
  --enable-nvsenc         NVS Encryption aktivieren
  --generate-keys         Neue Keys generieren
  --verify-signature      Signatur prüfen
  --lock-efuse            eFuse endgültig sperren
  --show-status           Sicherheits-Status zeigen
```

## ⚠️ WICHTIGE WARNUNG

**ACHTUNG**: Secure Boot ist IRREVERSIBEL!
- Nach Aktivierung können nur signierte Bootloader geflasht werden
- Verlorene Keys = Device permanent gemessen
- Immer Backups machen!

## Best Practices

1. **Development Phase**
   - Entwickle ohne Secure Boot
   - Teste mit enablem Secure Boot lokal
   - Mehrere Geräte für Testing

2. **Production**
   - Keys sicher lagern (nicht in Git!)
   - Keys signieren
   - CI/CD Pipeline für Signing
   - Secure Release Process

3. **Key Management**
   ```bash
   # Keys verschlüsselt speichern
   openssl enc -aes-256-cbc -in secure_boot.key \
       -out secure_boot.key.enc
   
   # Nur Build-Server hat Zugriff
   # Keys niemals in Repository!
   ```

## Compliance

Unterstützt:
- ✅ IoT Security Foundation Standards
- ✅ OWASP Top 10 Mitigations
- ✅ NIST Cybersecurity Framework
- ✅ EU Critical Infrastructure Directives

## Weitere Ressourcen

- [Espressif Security Guide](https://docs.espressif.com/projects/esp-idf/en/latest/esp32/security/)
- [Secure Boot V2](https://docs.espressif.com/projects/esp-idf/en/latest/esp32/security/secure-boot-v2.html)
- SECURITY.md → Detaillierte Sicherheits-Richtlinien
- keys/README.md → Key-Management Guide
