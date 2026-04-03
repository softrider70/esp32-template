# Phase 4: Advanced Features Skills

**Status:** 🚀 Ready to Deploy

Sechs modulare Add-on Skills für erweiterte Features. Jeder Skill kann unabhängig zu bestehenden Projekten hinzugefügt werden.

## 📋 Skills Übersicht

| Skill | Command | Zweck | Komplexität |
|-------|---------|--------|------------|
| **OTA Framework** | `/add-ota` | Over-the-air Updates | Medium |
| **WebUI Generator** | `/add-webui` | Web-Interface Templates | Medium |
| **Component Registry** | `/add-library` | Component Management | Low |
| **Security Features** | `/add-security` | Secure Boot, NVS, TLS | High |
| **Multi-board CI/CD** | `/setup-ci` | GitHub Actions Pipeline | Medium |
| **Performance Profiling** | `/add-profiling` | Memory/Timing Analysis | Low |

---

## 1. 📡 OTA Framework (`/add-ota`)

**Beschreibung:** Over-the-air Firmware-Updates  
**Dateien:** `skills/add-ota/`

### Features
- ✅ HTTP/HTTPS Download Integration
- ✅ Partition Management (ab-Scheme)
- ✅ Firmware Verification (SHA256)
- ✅ Rollback Mechanism
- ✅ Progress Callbacks

### Verwendung
```bash
/add-ota
# oder mit Optionen:
/add-ota --with-signature --with-webserver
```

### Generiert
- `include/ota_handler.h` - OTA API
- `src/ota_handler.c` - Implementierung
- `include/ota_config.h` - Konfiguration
- `OTA_EXAMPLE.c` - Integrations-Beispiel

### Abhängigkeiten
- `esp_https_ota` Component
- `mbedTLS` für Signatur-Verifikation

### Nächste Schritte
1. Implementiere HTTP-Client in `ota_handler.c`
2. Konfiguriere Update-Server in `ota_config.h`
3. Nutze OTA-Beispielcode

---

## 2. 🎨 WebUI Generator (`/add-webui`)

**Beschreibung:** Responsive Web-Interface für ESP32  
**Dateien:** `skills/add-webui/`

### Features
- ✅ Responsive HTML/CSS/JS UI
- ✅ REST API Client
- ✅ WebSocket Support (optional)
- ✅ Dark/Light Theme Toggle
- ✅ Real-time Status Updates
- ✅ Mobile-freundlich

### Verwendung
```bash
/add-webui
# oder:
/add-webui --with-websocket --with-authentication
```

### Generiert
- `webui/html/index.html` - Main Interface
- `webui/css/style.css` - Styling
- `webui/js/api.js` - REST Client
- `webui/js/app.js` - Application Logic
- `webui/server/webui_server.c` - HTTP Server

### Struktur
```
webui/
├── html/         (Templates)
├── js/           (Frontend Code)
├── css/          (Styling)
└── server/       (Backend Code)
```

### API Endpoints
```
GET  /api/status      → Device Status (JSON)
POST /api/config      → Update Settings
POST /api/restart     → Reboot Device
WS   /ws              → WebSocket (optional)
```

### Nächste Schritte
1. Integriere `webui_server.c` in CMakeLists.txt
2. Implementiere API-Handler für deine Geräte-Spezifiken
3. Starte WebUI da auf `http://esp32.local:80`

---

## 3. 📦 Component Registry (`/add-library`)

**Beschreibung:** Smart Component Management  
**Dateien:** `skills/add-library/`

### Features
- ✅ ESP-IDF Registry Integration
- ✅ GitHub Repository Support
- ✅ Automatische Dependency Auflösung
- ✅ Version Management
- ✅ Konflikt-Erkennung

### Verwendung
```bash
# Komponente installieren
/add-library mqtt
/add-library json --version 2.0.0

# Verfügbare Komponenten auflisten
/add-library --list

# Abhängigkeiten prüfen
/add-library --resolve
```

### Populäre Komponenten
```
mqtt           MQTT Client (mosquitto)
json           JSON Parser (cJSON)
littlefs       LittleFS FileSystem
http_client    HTTP Client Library
ble_mesh       Bluetooth Mesh Stack
sdmmc          SD Card Interface
lvgl           Graphics Library
```

### Sicherheit
⚠️ Nur mit gültigen Versionsnummern
⚠️ Verifiziere Component-Quelle
⚠️ Test vor Produktion

### Nächste Schritte
1. Durchsuche verfügbare Komponenten: `/add-library --list`
2. Installiere benötigte: `/add-library mqtt`
3. Resolve Dependencies: `/add-library --resolve`
4. Build: `idf.py build`

---

## 4. 🔐 Security Features (`/add-security`)

**Beschreibung:** Production Security Setup  
**Dateien:** `skills/add-security/`

### Features
- ✅ Secure Boot V2 (Signatur-Verifikation)
- ✅ NVS Partition Encryption
- ✅ TLS/SSL Certificate Management
- ✅ Hardware Security Module (eFuse)
- ✅ WPA3 WiFi Support

### Sicherheits-Layer
```
┌─────────────────────────────┐
│ Boot     → Secure Boot V2   │
│ Storage  → NVS Encryption   │
│ Network  → TLS 1.3          │
│ OTA      → Signature Verify │
│ Hardware → eFuse Lock       │
└─────────────────────────────┘
```

### Verwendung
```bash
/add-security
# oder:
/add-security --enable-secure-boot --generate-keys
```

### Generiert
- `include/security_config.h` - Config Macros
- `keys/` Directory - Key Storage
- `SECURITY_GUIDE.md` - Detaillierte Anleitung
- `SECURITY_EXAMPLE.c` - Integrations-Code

### ⚠️ KRITISCH: Secure Boot ist IRREVERSIBEL!

```bash
# Key generieren
espsecure.py generate_signing_key secure_boot.key

# Key zu eFuse brennen (nur 1x!)
espefuse.py burn_key SEC_SECURE_BOOT_KEY0 secure_boot.key

# In menuconfig aktivieren
idf.py menuconfig
# → Security Features
#   ├── [*] Enable Secure Boot V2
#   └── [*] Verify app signature before boot
```

### Best Practices
✅ Entwickle nachher ohne Secure Boot
✅ Teste lokal mit enablem SB
✅ Keys **niemals in Git!**
✅ Separate Keys für Dev vs. Prod
✅ Backups vor Aktivierung

### Nächste Schritte (ORDERED!)
1. **LESEN:** SECURITY_GUIDE.md (nicht überspringen!)
2. **AM BESTEN:** Review auf mehreren Geräten testen
3. **DANN:** Keys generieren
4. **FINALLY:** In menuconfig aktivieren
5. **BACKUP:** Private Keys verschlüsselt speichern

---

## 5. 🔄 Multi-board CI/CD (`/setup-ci`)

**Beschreibung:** GitHub Actions Automation  
**Dateien:** `skills/setup-ci/`

### Features
- ✅ Automatische Matrix Builds (5 Boards)
- ✅ Unit/Integration Tests
- ✅ Static Code Analysis
- ✅ Automated Releases
- ✅ Firmware Size Tracking
- ✅ Status Badges für README

### Workflows
```
.github/workflows/
├── build.yml      (Matrix: 5 Boards × 2 IDF Versions)
├── test.yml       (Unit Tests)
├── analysis.yml   (Code Quality)
├── release.yml    (Automated Releases)
└── schedule.yml   (Nightly Builds, optional)
```

### Build Matrix
```yaml
Boards:           [esp32, esp32s2, esp32s3, esp32c3, esp32c6]
IDF Versions:     [v5.0, v5.1]
Duration:         ~4 minutes / run
Cost:             Free (GitHub Free Tier)
```

### Verwendung
```bash
/setup-ci
# oder:
/setup-ci --with-test --with-analysis --with-release
```

### Generiert
- `.github/workflows/build.yml` - Build Pipeline
- `.github/workflows/test.yml` - Test Suite
- `.github/workflows/analysis.yml` - Code Quality
- `.github/workflows/release.yml` - Release Automation
- `.github/CODEOWNERS` - Auto Code Review Assignment
- `.github/dependabot.yml` - Dependency Updates
- `CI_CD_GUIDE.md` - Documentation

### Status Badges
```markdown
[![Build](github.com/YOUR_ORG/YOUR_REPO/actions/workflows/build.yml/badge.svg)](...)
[![Tests](github.com/YOUR_ORG/YOUR_REPO/actions/workflows/test.yml/badge.svg)](...)
[![Analysis](github.com/YOUR_ORG/YOUR_REPO/actions/workflows/analysis.yml/badge.svg)](...)
```

### Release via Tag
```bash
git tag v1.0.0 -m "Release 1.0.0"
git push origin v1.0.0
# → GitHub Action creates release + uploads binaries
```

### Nächste Schritte
1. Commit Workflows: `git add .github/ && git commit -m 'ci: Add GitHub Actions'`
2. Push: `git push origin main`
3. Watch: github.com/YOUR_ORG/YOUR_REPO/actions
4. Tag Release: `git tag v1.0.0 && git push origin v1.0.0`

---

## 6. 📊 Performance Profiling (`/add-profiling`)

**Beschreibung:** Memory & Timing Analysis  
**Dateien:** `skills/add-profiling/`

### Features
- ✅ Real-time Heap Monitoring
- ✅ Stack Overflow Detection
- ✅ Performance Timing Macros
- ✅ Fragmentation Analysis
- ✅ Task Memory Tracking
- ✅ Live UART Dashboard

### Tools
```c
heap_profiler    // Speicher-Tracking
stack_monitor    // Stack-Überwachung
perf_timer       // Performance Macros
power_estimator  // Energie-Schätzung
```

### Verwendung
```bash
/add-profiling
# oder:
/add-profiling --enable-heap-track --enable-stack-check
```

### Generiert
- `include/heap_profiler.h` - Heap API
- `include/stack_monitor.h` - Stack API
- `include/perf_timer.h` - Timing Macros
- `src/heap_profiler.c` - Implementierung
- `src/stack_monitor.c` - Stack Tracking
- `tools/heap_monitor.py` - Live Monitor
- `PROFILING_GUIDE.md` - Dokumentation

### Heap Profiling Beispiel
```c
#include "heap_profiler.h"

void app_main(void) {
    heap_profiler_init();
    
    // Dein Code...
    
    heap_profiler_dump_stats();
    // Output:
    // Total: 204.8KB  Used: 98.3KB (48%)
    // Free: 106.5KB  Largest: 65.5KB  Frag: 8%
}
```

### Real-time Monitoring
```bash
python3 tools/heap_monitor.py /dev/ttyUSB0

# Output:
# ┌─────────────────────────────────┐
# │ Heap: 98.3/204.8KB (48%)        │
# │ Stack: 15.2/16KB (95%) ⚠️       │
# │ Largest Block: 65.5KB           │
# │ Fragmentation: 8%               │
# └─────────────────────────────────┘
```

### Memory Optimization Tips
✅ Stack: Temp-Daten (<512B)
✅ Heap: Große Buffers (>1KB)
✅ Flash: Konstanten (PROGMEM)
✅ PSRAM: Große Arrays (>64KB)

### Typische Speicher-Verteilung (ESP32)
```
Internal RAM:    352 KB total
├── System/WiFi:  150-200 KB (reserviert)
└── App Heap:     50-200 KB (verfügbar) ← hier!

PSRAM (optional): 2-16 MB extra
```

### Nächste Schritte
1. Include Headers in `main.c`
2. Call `heap_profiler_init()`
3. Nutze PERF_TIMER_START/STOP Makros
4. Review PROFILING_GUIDE.md

---

## 📚 Wie man Skills nutzt

### Scenario 1: Einfaches Projekt
```bash
# Neue Projekt erstellen (Core Features)
./new-project.ps1 -ProjectName sensor-hub -Board 3

# Später: WebUI brauchst du
/add-webui

# Noch später: OTA hinzufügen
/add-ota
```

### Scenario 2: Sicheres Projekt
```bash
# Projekt erstellen
./new-project.ps1 -ProjectName secure-device -Board 1

# Security setup
/add-security

# Später: Monitoring
/add-profiling
```

### Scenario 3: Professionelles Projekt
```bash
# Projekt erstellen
./new-project.ps1 -ProjectName enterprise-iot -Board 5

# All features
/add-webui
/add-ota
/add-security
/add-library mqtt
/setup-ci
/add-profiling
```

---

## 🔧 Skill Installation im Projekt

Alle Skills sind vorbereitet in `skills/` Directory:

```
template/
├── skills/
│   ├── add-ota/
│   │   ├── SKILL.md
│   │   └── add-ota.ps1
│   ├── add-webui/
│   │   ├── SKILL.md
│   │   └── add-webui.ps1
│   ├── add-library/
│   │   ├── SKILL.md
│   │   └── add-library.ps1
│   ├── add-security/
│   │   ├── SKILL.md
│   │   └── add-security.ps1
│   ├── setup-ci/
│   │   ├── SKILL.md
│   │   └── setup-ci.ps1
│   └── add-profiling/
│       ├── SKILL.md
│       └── add-profiling.ps1
```

Jeder Ordner enthält:
- **SKILL.md** - Detaillierte Dokumentation
- **[name].ps1** - PowerShell Implementierung

---

## 📈 Komplexität & Abhängigkeiten

```
Einfach (Low)         Medium          Komplex (High)
    ↓                    ↓                   ↓
add-library        add-webui, OTA      add-security
add-profiling      setup-ci            (Irreversibel!)
```

### Empfehlung für Anfänger
1. Start mit Core (Phase 1-3) ✅
2. Dann `/add-library` (einfach)
3. Dann `/add-profiling` (nützlich)
4. Dann `/add-webui` (cool)
5. Dann `/setup-ci` (professionell)
6. Zuletzt `/add-security` (production-ready)

---

## ✨ Production Readiness Checklist

Vor Produktionsstart:
- [ ] Phase 1-3 Template funktioniert
- [ ] Alle Tests bestehen (Phase 3)
- [ ] Security Features aktiviert (`/add-security`)
- [ ] OTA Framework integriert (`/add-ota`)
- [ ] CI/CD Pipeline läuft (`/setup-ci`)
- [ ] Performance optimiert (`/add-profiling`)
- [ ] WebUI deployed (`/add-webui`, optional)
- [ ] Component Dependencies korrekt (`/add-library`)

---

## 📞 Support & Dokumentation

Jeder Skill hat:
- ✅ Detaillierte SKILL.md
- ✅ Example Code
- ✅ Best Practices Guide
- ✅ Error Handling
- ✅ Integration Instructions

Weitere Ressourcen:
- `PHASE3_REPORT.md` - Phase 3 Summary
- `IMPLEMENTATION_PLAN.md` - Master Plan
- `SECURITY.md` - Security Best Practices
- `BUILD_GUIDE.md` - Build Instructions

---

## 🚀 Zusammenfassung

**Phase 4 bietet 6 modulare Skills:**
- **OTA** - Sichere Firmware-Updates
- **WebUI** - Responsive Web-Interface
- **Library** - Smart Component Management
- **Security** - Production-grade Sicherheit
- **CI/CD** - Automated Multi-board Builds
- **Profiling** - Performance Optimization

→ **Alle Skills sind ready-to-deploy** ✅
→ **Wähle was du brauchst**
→ **Nutze wenn du brauchst**
→ **Kombiniere für deine Anforderungen**

Happy Coding! 🎯
