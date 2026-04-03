# Plan: ESP32 Template Automation

Status: Ready for implementation
Version: 1.0

## Ziel
Ein reproduzierbares **ESP-IDF native** ESP32-Template mit interaktivem Projekt-Generator. Neue Projekte werden unter `C:\Users\win4g\Downloads\GitHub\VS-Projekte\<Projektname>` erzeugt, mit frischem Git-Repo, Board-spezifischer Konfiguration und separater Projektdokumentation.

**Framework-Wahl: ESP-IDF native (Espressif IoT Development Framework)**
- Offizielle Espressif Framework (nicht PlatformIO)
- Volle Kontrolle über Build (CMake) und Hardware (sdkconfig)
- Security Built-in (Secure Boot, NVS, TLS)
- Production-grade Reliability
- Optimal für Auto-Code-Generation

## Kernprinzipien
1. `plan.md` ist die Basis im Template und wird als Kopie ins Zielprojekt uebernommen.
2. Projektspezifisches Wissen liegt in `PROJECT.md` und `CHANGES.md`, nicht in `plan.md`.
3. Board-Auswahl ist standardmaessig interaktiv per Menue.
4. Fokus bleibt nur auf ESP32-Varianten.

## Umsetzungsphasen

### Phase 1: Template-Basisdateien
1. `plan.md` aus `.windsurf/plans/esp32-template-plan-258012.md` nach `template/plan.md` kopieren.
2. `CMakeLists.txt` (Top-Level) – ESP-IDF Build-Konfiguration mit Komponenten-Struktur
3. `src/main.c` als board-agnostisches ESP-IDF Einsteiger-Gerüst (app_main)
   - FreeRTOS Task Beispiel
   - NVS Initialization
   - Logging via ESP_LOG
   - Graceful Error Handling
4. `include/config.h` mit Platzhaltern für Pins, WLAN und `BOARD_TYPE`
   - FreeRTOS Task Stack-Größen (Task-Defaults)
   - NVS-Keys für Secrets Management
   - UART/GPIO Pin-Definitionen (Board-agnostisch, Standard-Pins)
5. `sdkconfig.defaults` (Board-agnostisch, Basis)
   - Logging Level
   - Core Frequency (80/160/240 MHz)
   - Partition Table Setting
6. Fünf Board-spezifische `sdkconfig.defaults.<BOARD>` Varianten:
   - `sdkconfig.defaults.esp32` – Standard Dual-Core
   - `sdkconfig.defaults.esp32s2` – Single-Core, `CONFIG_FREERTOS_NO_AFFINITY=y`
   - `sdkconfig.defaults.esp32s3` – Dual-Core, PSRAM
   - `sdkconfig.defaults.esp32c3` – Single-Core RISC-V, GPIO-Mapping
   - `sdkconfig.defaults.esp32c6` – Dual-Core, Thread-Support
7. `CMakeLists.txt` (src/) für main.c Komponente
8. `PROJECT.md.template` – Platzhalter für Projektname, Board, Power-Profil, FreeRTOS-Hinweise
9. `README.md` – Generator-Workflow, ESP-IDF Setup-Anleitung
10. `.github/agents/` – Lean-Workspace-Agent, Spezial-Agenten, copilot-instructions.md
11. `.github/skills/build-project/` – Build-Skill
    - `SKILL.md` – Copilot Chat Instruction
    - `build-project.ps1` – Script: `idf.py build`, Error-Handling
12. `.github/skills/upload-firmware/` – Upload-Skill
    - `SKILL.md` – Copilot Chat Instruction
    - `upload-firmware.ps1` – Script: Detect board, `esptool.py write_flash`, Error-Analyse, Retry-Build
13. `SECURITY.md` – NVS-Setup, TLS/mTLS, Secure Boot Guide
14. `BUILD_GUIDE.md` – Manuelle `idf.py build`, `esptool.py` Upload, Troubleshooting

### Phase 2: Generator-Script
1. `new-project.ps1` in der Template-Root erstellen.
2. Eingaben:
   - Projektname (Pflicht)
   - Board (Menueauswahl 1-5; optional per Parameter)
3. Ablauf:
   - Template nach `C:\Users\win4g\Downloads\GitHub\VS-Projekte\<Projektname>` kopieren
   - `.github/agents/`, `.github/skills/` unveraendert mitkopieren
   - uebernommenes `.git` entfernen
   - `PROJECT.md.template` zu `PROJECT.md` rendern (Projektname, Board, Power-Profil)
   - `CHANGES.md` leer anlegen
   - Wähle richtige `sdkconfig.defaults.<BOARD>` Datei, kopiere zu `sdkconfig.defaults`
   - Entferne andere `sdkconfig.defaults.*` Varianten (nicht mehr nötig)
   - `config.h` bleibt unverändert (Board-agnostisch)
   - Neues Git initialisieren, `git add .`, Initial-Commit
4. Build-Skill Setup:
   - `build-project.ps1` ist im Template vorhanden
   - User/Copilot ruft `/build-project` auf → Script führt `idf.py build` aus
   - Bei Fehler: Outputs zeigen, vorschlagen zu `idf.py menuconfig` (für Board-Konfiguration)
5. Upload-Skill Setup:
   - `upload-firmware.ps1` ist im Template vorhanden
   - User/Copilot ruft `/upload-firmware` auf
   - Script fragt nach COM-Port (z.B. COM3)
   - Führt aus: `esptool.py --port COMx --baud 921600 write_flash 0x10000 build/esp32-template.bin`
   - Error-Analyse: COM-Port nicht gefunden? esttool nicht installiert?
   - Bei Fehler: Retry-Option: "Neuen Build versuchen? [j/n]" → `/build-project` aufrufen

### Phase 3: Robustheit
1. Projektname validieren (nicht leer, keine ungueltigen Zeichen).
2. Abbruch, wenn Zielordner bereits existiert.
3. Board-Auswahl validieren.
4. Fehlerausgabe fuer Copy-/Git-Fehler mit sauberem Abbruch.

## Board-Mapping (ESP-IDF native)

| Input | IDF_TARGET | Board-ID | Config Key | Cores | RAM | Single-Core Config |
|------|------------|----------|------------|-------|-----|----|
| ESP32 | esp32 | esp32dev | `CONFIG_IDF_TARGET_ESP32=y` | 2 | 520KB SRAM + PSRAM | – |
| S2 | esp32s2 | esp32-s2-devkitm-1 | `CONFIG_IDF_TARGET_ESP32S2=y` | 1 | 320KB SRAM | `CONFIG_FREERTOS_NO_AFFINITY=y` |
| S3 | esp32s3 | esp32-s3-devkitc-1 | `CONFIG_IDF_TARGET_ESP32S3=y` | 2 | 512KB SRAM + PSRAM | – |
| C3 | esp32c3 | esp32-c3-devkitm-1 | `CONFIG_IDF_TARGET_ESP32C3=y` | 1 | 400KB SRAM | `CONFIG_FREERTOS_NO_AFFINITY=y` |
| C6 | esp32c6 | esp32-c6-devkitc-1 | `CONFIG_IDF_TARGET_ESP32C6=y` | 2 | 512KB SRAM + PSRAM | – |

**Upload: Alle Boards verwenden gleichen esttool.py Befehl:**
```powershell
esptool.py --port COMx --baud 921600 write_flash 0x10000 build/esp32-template.bin
```

## Board-Spezifische Fallstricke

- **S2 & C3 Single-Core**: `CONFIG_FREERTOS_NO_AFFINITY=y` erforderlich (in sdkconfig.defaults)
- **S2 RAM klein**: Code auf ESP32 kann zu OOM führen → Compiler-Optimierungen in sdkconfig
- **C3 RISC-V Architektur**: Pin-Mapping gleich, aber andere Toolchain-Version möglich
- **C6 Thread-Support**: Neuestes Board mit nativen Thread-Features
- **Upload immer gleich**: `esttool.py 0x10000` für alle Boards (keine Board-Unterschiede bei Upload)

Hinweis: Alle genannten Varianten unterstützen FreeRTOS. Unterschiede liegen in Core-Anzahl (S2 & C3 = 1), RAM-Größe, und neuen Features (C6).

## Verifikation
1. Script ohne Parameter starten: Menü erscheint und nimmt gültige Auswahl an.
2. Testlauf `C3`: Zielordner entsteht, `.git` ist frisch initialisiert.
3. `PROJECT.md` enthält korrektes Board (ESP-IDF C3) und Basisprofil.
4. `CHANGES.md` ist vorhanden und leer.
5. `sdkconfig.defaults` existiert (Kopie von `sdkconfig.defaults.esp32c3`)
6. `sdkconfig.defaults.*` (andere Varianten) sind **gelöscht**
7. `config.h` ist Standard-Template (keine Board-spezifischen Conditionals nötig für Upload)
8. `.github/agents/` und `.github/copilot-instructions.md` sind im Zielprojekt vorhanden.
9. `.github/skills/build-project/` und `.github/skills/upload-firmware/` sind im Zielprojekt vorhanden.
10. `idf.py build` läuft ohne Fehler (oder mit Hinweis "IDF nicht installiert" [OK])
11. `upload-firmware.ps1` Kommando ist: `esptool.py --port COMx --baud 921600 write_flash 0x10000 build/esp32-template.bin`
12. Testlauf S2: Validierung dass `CONFIG_FREERTOS_NO_AFFINITY=y` in `sdkconfig.defaults.esp32s2` vorhanden ist.
13. Testlauf S3 vs ESP32: Upload-Kommando ist **identisch** (beide 0x10000)
14. Negativtests: ungültiger Projektname, ungültiges Board, existierender Zielordner.

## Security & Best Practices

### Hardcoded vs. Secrets
- **NICHT**: WLAN-Passwörter in config.h hardcoden
- **JA**: NVS (Non-Volatile Storage) Template bereitstellen für Secrets
- `main.c` Beispiel: NVS Read/Write zur Credential-Verwaltung via `nvs_*` API

### Secure Boot / Flash Encryption
- `sdkconfig.defaults` enthält kommentierte Optionen:
  - `# CONFIG_SECURE_BOOT=y` (optional, production-only)
  - `# CONFIG_SECURE_FLASH_ENC=y` (optional, production-only)
- Aktivierung via `idf.py menuconfig` und `idf.py secure_signing_key`
- Warnung: Aktivierung führt zu One-Time-Setup
- Dokumentation in `SECURITY.md`

### TLS/mTLS Support (Native ESP-IDF)
- `mbedtls` + `esp_tls` are native in ESP-IDF
- Zertifikat-Storage nutzt NVS Partition
- `main.c` enthält Kommentar-Beispiel für TLS Client

## Build & Upload Automation (Skills-basiert)

### build-project Skill
- Auslösung: `/build-project` im Copilot Chat
- Funktion: Führt `idf.py build` im Projekt-Verzeichnis aus
- Output: Build-Log, Erfolg/Fehler, Dateigröße Firmware
- Error-Handling: Bei Fehler → Hinweis auf `idf.py menuconfig`
- Persistiert: Build-Artefakte in `build/` für Upload-Skill

### upload-firmware Skill
- Auslösung: `/upload-firmware` im Copilot Chat
- Funktion:
  1. Fragt nach COM-Port: "Welcher COM-Port? (z.B. COM3)"
  2. Führt aus: `esptool.py --port COMx --baud 921600 write_flash 0x10000 build/esp32-template.bin`
  3. (APP-only Flash: kompakt und schnell)
- Error-Analyse:
  - `Failed to connect`: COM-Port nicht verfügbar oder Board antwortet nicht
  - `File not found`: Build-Artefakt fehlt → `/build-project` aufrufen
  - `Timeout`: Board reagiert nicht, USB-Kabel prüfen oder Netzwerk-Probleme?
  - Bei Fehler: Vorschlag "/build-project" aufzurufen
- Recovery: Bei wiederholtem Fehler → Lnkt zu `BUILD_GUIDE.md` Troubleshooting

## Power Management Profile (ESP-IDF native)

- **Balanced (default)**: Normal Operation, `esp_pm_configure()` mit 80/160/240 MHz (Board-abhängig)
- **Power-Save**: Light Sleep (auto), Core-Gating, ~50mA
- **Deep-Sleep**: `esp_sleep_enable_timer_wakeup()`, nur RTC aktiv, ~11µA
- In `main.c` Template: Commented-out Beispiele für alle 3 Profile
- Konfiguration via `sdkconfig`: `CONFIG_PM_ENABLE=y` + `CONFIG_PM_DFS_INIT_AUTO=y`
- Board-Unterschiede: C6 native Thread-Support für besseres PM

## Scope-Grenzen
1. Keine RPI/STM32-Unterstuetzung in dieser Version.
2. Lokales Build/Upload via Skills: `/build-project` und `/upload-firmware` (in generierten Projekten verfügbar)
3. Keine automatische Ruecksynchronisierung von Projekt-`CHANGES.md` ins Template.
4. Keine statische Tool-Deaktivierung — Tool-Policies nicht via Hooks umsetzbar in VS Code Copilot Chat.
5. Secure Boot/Flash Encryption sind optional – werden via `idf.py menuconfig` aktiviert
6. TLS-Zertifikate müssen selbst bereitgestellt werden (nicht auto-generated)
7. Upload: NUR APP-Binarys (0x10000) – Bootloader/Partition einmalig initial
8. Upload-Kommando ist identisch für alle Boards (0x10000)
9. ESP-IDF muss lokal installiert sein (IDF_PATH Umgebungsvariable)
10. esttool.py muss installiert sein (über `pip install esptool`)
11. Build/Upload-Skills sind lokale Automation – kein CI/CD, kein Cloud-Build
