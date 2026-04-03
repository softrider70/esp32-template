# /add-library - Component Registry Integration

## Beschreibung

Ermöglicht einfache Integration von ESP-IDF Komponenten aus dem [IDF Component Registry](https://components.espressif.com) oder GitHub. Verwaltet Abhängigkeiten automatisch.

## Funktionalität

Fügt CLI für einfache Komponenten-Installation:
- Komponenten-Katalog durchsuchen
- Abhängigkeiten automatisch auflösen
- idf_component.yml aktualisieren
- Komponenten-Verifikation
- Konflikterkennung

## Installation

```bash
/add-library
```

## Verwendung

```bash
# Komponente installieren
/add-library mqtt        → Fügt MQTT-Komponente hinzu

/add-library wifi --version 1.5.0

/add-library filesystem:littlefs

# Dependecies auflösen
/add-library --resolve

# Verfügbare Komponenten auflisten
/add-library --list
```

## Beliebte Komponenten

```
mqtt              Mosquitto MQTT Client
wifi              WiFi Management Stack
ble               Bluetooth Low Energy
json              cJSON/JSON Parser
http              HTTP Client Library
filesystem        SPIFFS/LittleFS Manager
led_strip         WS2812B/RGB LED Control
button            Button Input Handler
display           LCD/OLED Display Driver
sd_card           microSD Card Interface
```

## Abhängigkeits-Beispiel

```yaml
idf_component.yml:
dependencies:
  mqtt:
    version: ">=1.0.0"
    git: "https://github.com/espressif/esp-mqtt.git"
  json:
    version: "1.2.0"
    registry: "esp-idf"
```

## CLI-Optionen

```
/add-library COMPONENT_NAME
  --version VERSION      Spezifische Version (default: latest)
  --git URL             Git Repository
  --resolve             Alle Dependencies auflösen
  --list                Verfügbare Komponenten zeigen
  --search PATTERN      Nach Komponenten suchen
  --remove COMPONENT    Komponente entfernen
  --update              Auf neueste Version updaten
```

## Features

✅ Automatische Versionskontrolle
✅ Konflikterkennung
✅ Lokale Komponenten-Unterstützung
✅ Git-basierte Komponenten
✅ Abhängigkeits-Baum-Visualisierung
✅ Offline-Katalog-Modus

## Sicherheit

⚠️ **Beachte**:
- Verifiziere Komponenten-Quellen
- Überprüfe idf_component.yml nach Installation
- Nutze spezifische Versionsnummern (kein "latest")
- Teste Komponenten vor Produktions-Einsatz

## Architektur

```
add-library.ps1 queries:
├── ESP-IDF Registry API
│   └── components.espressif.com
├── GitHub API
│   └── Komponenten-Repos
└── Local Manifest
    └── idf_component.yml (aktualisieren)
```

## Beispiel: MQTT hinzufügen

```bash
/add-library mqtt
# +dependency in idf_component.yml
# +include mqtt headers automatisch
# +example code snippet
```

## Weitere Ressourcen

- [Component Registry](https://components.espressif.com)
- [idf_component.yml Format](https://docs.espressif.com/projects/esp-idf/en/latest/esp32/api-guides/component_manager.html)
- package_manager.md → Best Practices
