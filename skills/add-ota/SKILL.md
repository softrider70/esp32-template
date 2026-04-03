# /add-ota - OTA Framework Integration

## Beschreibung

Integriert ein produziertes Over-the-Air (OTA) Update-Framework in dein ESP32-Projekt. Ermöglicht sichere Firmware-Updates via HTTP/HTTPS ohne Serielle Verbindung.

## Funktionalität

Fügt hinzu:
- OTA-Komponente basierend auf ESP-IDF OTA Service
- HTTP/HTTPS Update-Server Integration
- Partition-Management (boot, ota_0, ota_1)
- Update-Verifikation (SHA256/Signatur)
- Rollback-Mechanismus bei Fehler
- Progress-Callback für Status-Anzeige

## Installation

```bash
/add-ota
```

## Verwendung

```c
#include "ota_handler.h"

void app_main(void) {
    ota_initialize();
    
    // WiFi verbinden...
    
    // Update initiieren
    ota_update("https://update.server.com/firmware.bin");
}
```

## Features

✅ Sichere HTTPS-Kommunikation
✅ Validierung der Firmware
✅ Rollback bei Fehler
✅ Verschlüsselte Partition-Updates
✅ Progress-Tracking
✅ Verschiedene Update-Strategien (Full, Delta)

## Abhängigkeiten

- ESP-IDF OTA Service Component
- mbedTLS für Signatur-Verifikation
- HTTP Server (Optional)

## Konfiguration

Editiere `include/ota_config.h`:
```c
#define OTA_UPDATE_URL "https://update.server.com"
#define OTA_RECV_TIMEOUT 5000
#define OTA_USE_SIGNING 1
```

## Sicherheit

⚠️ **WICHTIG**: 
- Nutze HTTPS für Updates
- Implementiere Firmware-Signatur-Verifikation
- Versionsprüfung vor Update
- Rate-Limiting für Update-Anfragen

## Architektur

```
main.c
├── ota_handler.c (OTA-Logic)
├── ota_handler.h (API)
└── ota_config.h (Konfiguration)

idf_component.yml
└── esp-idf/components/esp_https_ota (Dependency)
```

## Weitere Ressourcen

- [ESP-IDF OTA Doku](https://docs.espressif.com/projects/esp-idf/en/latest/esp32/api-reference/system/ota.html)
- SECURITY.md → OTA-Sicherheitsrichtlinien
- examples/ → Referenz-Implementierung
