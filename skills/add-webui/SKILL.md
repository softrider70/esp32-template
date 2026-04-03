# /add-webui - Web UI Generator

## Beschreibung

Generiert ein komplettes Web-Interface für dein ESP32-Projekt mit responsivem HTML/CSS/JavaScript. Ermöglicht Konfiguration und Monitoring via Browser.

## Funktionalität

Fügt hinzu:
- Eingebauter HTTP Server
- Responsive WebUI (HTML/CSS/JS)
- RESTful API-Endpoints
- WebSocket für Echtzeit-Updates
- SPIFFS/LittleFS für Datei-Storage
- JSON Config-Interface
- Dark/Light Mode

## Installation

```bash
/add-webui
```

## Verwendung

```c
#include "webui_server.h"

void app_main(void) {
    webui_init();
    
    // Server startet auf http://esp32.local:80
    // Steuerdaten via REST API verfügbar
}
```

## Features

✅ Responsive Design (mobil-freundlich)
✅ Echtzeit WebSocket-Updates
✅ RESTful API für Konfiguration
✅ Sortierbare/filterbare Datenansichten
✅ Live-Graphen für Sensor-Daten
✅ OTA-Update-Interface
✅ Dark/Light Theme Toggle

## Struktur

```
webui/
├── html/
│   ├── index.html
│   ├── settings.html
│   └── dashboard.html
├── js/
│   ├── app.js (Main App)
│   ├── api.js (REST Client)
│   └── ws.js (WebSocket Handler)
├── css/
│   ├── style.css
│   └── responsive.css
├── server.c (HTTP Server)
└── server.h
```

## API-Endpoints

```
GET    /api/status      → JSON Device Status
POST   /api/config      → Update Configuration
GET    /api/logs        → Live Logs
WS     /ws              → WebSocket (Echtzeit)
POST   /api/restart     → Gerät neustarten
```

## Abhängigkeiten

- esp_http_server
- SPIFFS/LittleFS
- JSON API Library

## Performance

- Minimale Firmware-Größe (<200KB code)
- Komprimierte Ressourcen (gzip)
- Effizientes WebSocket-Streaming
- PSRAM für große Dateitransfers

## Sicherheit

⚠️ **Beachte**:
- Implementiere Basic-Auth/Token-Auth
- HTTPS für Produktions-Einsatz
- CORS-Validierung
- Input-Sanitization

## Customization

Ändere Farben/Logo in `webui/css/style.css`:
```css
:root {
    --primary-color: #007bff;
    --secondary-color: #6c757d;
}
```

## Weitere Ressourcen

- [esp_http_server Doku](https://docs.espressif.com/projects/esp-idf/en/latest/esp32/api-reference/protocols/esp_http_server.html)
- examples/webui/ → Demo-Projekt
- design_guide.md → UI/UX Richtlinien
