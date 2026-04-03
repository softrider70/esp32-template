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
   - Vorbereitet für `idf.py component` System
   - Kann externe Komponenten (aus `idf_component_registry`) laden
3. `src/main.c` als board-agnostisches ESP-IDF Einsteiger-Gerüst (app_main)
   - FreeRTOS Task Beispiel
   - NVS Initialization
   - Logging via ESP_LOG
   - Graceful Error Handling
4. `include/config.h` mit Platzhaltern für Pins, WLAN und `BOARD_TYPE`
   - FreeRTOS Task Stack-Größen (Task-Defaults)
   - NVS-Keys für Secrets Management
   - UART/GPIO Pin-Definitionen (Board-agnostisch, Standard-Pins)
5. `idf_component.yml` – Komponenten-Deklaration (initial leer)
   - Ermöglicht externe Libraries via Espressif Component Registry
   - Versionskontrolle für Dependencies
   - Automatisches Download beim `idf.py build`
6. `sdkconfig.defaults` (Board-agnostisch, Basis)
   - Logging Level
   - Core Frequency (80/160/240 MHz)
   - Partition Table Setting
7. Fünf Board-spezifische `sdkconfig.defaults.<BOARD>` Varianten:
   - `sdkconfig.defaults.esp32` – Standard Dual-Core
   - `sdkconfig.defaults.esp32s2` – Single-Core, `CONFIG_FREERTOS_NO_AFFINITY=y`
   - `sdkconfig.defaults.esp32s3` – Dual-Core, PSRAM
   - `sdkconfig.defaults.esp32c3` – Single-Core RISC-V, GPIO-Mapping
   - `sdkconfig.defaults.esp32c6` – Dual-Core, Thread-Support
8. `CMakeLists.txt` (src/) für main.c Komponente
9. `PROJECT.md.template` – Platzhalter für Projektname, Board, Power-Profil, FreeRTOS-Hinweise
10. `README.md` – Generator-Workflow, ESP-IDF Setup-Anleitung, **Component Management Guide**
11. `.github/agents/` – Lean-Workspace-Agent, Spezial-Agenten, copilot-instructions.md
12. `.github/skills/build-project/` – Build-Skill
    - `SKILL.md` – Copilot Chat Instruction
    - `build-project.ps1` – Script: `idf.py build`, Error-Handling
13. `.github/skills/upload/` – Meta Upload-Skill
    - `SKILL.md` – Copilot Chat Instruction
    - `upload.ps1` – Script: Prüft Projekt-Status, ruft `/upload-firmware` oder `/initial-upload` auf
14. `.github/skills/upload-firmware/` – Firmware Update-Skill
    - `SKILL.md` – Copilot Chat Instruction
    - `upload-firmware.ps1` – Script: `esptool.py write_flash 0x10000`, NUR App
15. `.github/skills/initial-upload/` – Initial Installation-Skill
    - `SKILL.md` – Copilot Chat Instruction
    - `initial-upload.ps1` – Script: `esptool.py write_flash` mit Bootloader + Partition + App
16. `SECURITY.md` – NVS-Setup, TLS/mTLS, Secure Boot Guide
17. `BUILD_GUIDE.md` – Manuelle `idf.py build`, `esptool.py` Upload, Troubleshooting, **Component Registry Integration**

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
5. Upload-Skills Setup:
   - **`/upload`** (Meta-Skill) – Intelligente Auswahl durch Frage:
     - Fragt User: "Is this the FIRST flash on this device? [j/n]"
     - Ja (erstes Mal) → Ruft `/initial-upload` auf (Bootloader + Partition + App)
     - Nein (Iteration) → Ruft `/upload-firmware` auf (nur App)
     - Optional Override: `/upload --full` erzwingt `/initial-upload`
   - **`/upload-firmware`** – Nur Firmware Update:
     - `esptool.py write_flash 0x10000 build/esp32-template.bin`
     - Schnell, für Development/Iterations
   - **`/initial-upload`** – Vollständiger Flash:
     - `esptool.py write_flash 0x0 bootloader.bin 0x8000 partition_table.bin 0x10000 app.bin`
     - Für erste Installation oder Recovery

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
7. `config.h` ist Standard-Template (keine Board-spezifischen Conditionals)
8. `idf_component.yml` existiert und ist initial leer (oder mit Kommentaren)
9. `.github/agents/` und `.github/copilot-instructions.md` sind im Zielprojekt vorhanden.
10. `.github/skills/build-project/`, `.github/skills/upload/`, `.github/skills/upload-firmware/`, `.github/skills/initial-upload/` sind vorhanden.
11. `idf.py build` läuft ohne Fehler (oder mit Hinweis "IDF nicht installiert" [OK])
12. **Skill-Test**: `/upload` fragt User und wählt korrekten Sub-Skill:
    - "First flash? [j] → /initial-upload wird aufgerufen"
    - "First flash? [n] → /upload-firmware wird aufgerufen"
13. `/upload-firmware` Kommando: `esptool.py write_flash 0x10000 build/esp32-template.bin`
14. `/initial-upload` Kommando: `esptool.py write_flash 0x0 bootloader.bin 0x8000 partition_table.bin 0x10000 app.bin`
15. Testlauf S2: Validierung dass `CONFIG_FREERTOS_NO_AFFINITY=y` in `sdkconfig.defaults.esp32s2` vorhanden ist.
16. `/upload --full` Override-Flag funktioniert (erzwingt `/initial-upload`)
17. **Component Registry Test**: `idf_component.yml` kann manuell editiert werden, `idf.py build` lädt Dependencies
18. Negativtests: ungültiger Projektname, ungültiges Board, existierender Zielordner.

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
- Persistiert: Build-Artefakte in `build/` für Upload-Skills

### upload Meta-Skill (Smart Router)
- Auslösung: `/upload` im Copilot Chat
- Logik:
  1. Fragt User: "Is this the FIRST flash on this device? [j/n]"
  2. JA (first time) → ruft `/initial-upload` auf (Bootloader + Partition + App)
  3. NEIN (iteration) → ruft `/upload-firmware` auf (nur App)
  4. Optional Override: `/upload --full` erzwingt `/initial-upload`
- Output: Welcher Upload wird verwendet + Einleitung zur nächsten Skill

### upload-firmware Skill (App-Only)
- Auslösung: `/upload-firmware` im Copilot Chat (oder via `/upload`)
- Funktion:
  1. Fragt nach COM-Port: "Welcher COM-Port? (z.B. COM3)"
  2. Führt aus: `esptool.py --port COMx --baud 921600 write_flash 0x10000 build/esp32-template.bin`
  3. (Schnell: nur App ~500KB, ~2-5 Sekunden)
- Error-Analyse: COM-Port nicht verfügbar? Build-Artefakt fehlt?
- Recovery: Bei Fehler → Vorschlag `/build-project`

### initial-upload Skill (Vollständig)
- Auslösung: `/initial-upload` im Copilot Chat (oder via `/upload`)
- Funktion:
  1. Fragt nach COM-Port
  2. Führt aus: `esptool.py --port COMx write_flash 0x0 bootloader.bin 0x8000 partition_table.bin 0x10000 build/esp32-template.bin`
  3. (Länger: alle Komponenten, ~10-20 Sekunden)
- Use Cases: Erste Installation, Partition-Änderung, Recovery
- Error-Analyse: Bootloader/Partition fehlt? COM-Port? Dann `/build-project` anbieten
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
2. Upload-Skills: `/upload` (intelligente Auswahl), `/upload-firmware` (nur App), `/initial-upload` (vollständig)
3. Component Management: `idf_component.yml` für externe Libraries (Espressif Component Registry)
4. Keine automatische Ruecksynchronisierung von Projekt-`CHANGES.md` ins Template.
5. Keine statische Tool-Deaktivierung — Tool-Policies nicht via Hooks umsetzbar in VS Code Copilot Chat.
6. Secure Boot/Flash Encryption sind optional – werden via `idf.py menuconfig` aktiviert
7. TLS-Zertifikate müssen selbst bereitgestellt werden (nicht auto-generated)
8. Upload-Kommando ist identisch für alle Boards (0x10000)
9. Bootloader + Partition werden NICHT bei jedem Upload geflasht (nur einmalig initial)
10. ESP-IDF muss lokal installiert sein (IDF_PATH Umgebungsvariable)
11. esttool.py muss installiert sein (über `pip install esptool`)
12. Build/Upload-Skills sind lokale Automation – kein CI/CD, kein Cloud-Build
13. Component Registry Download benötigt Internet-Verbindung
14. Custom/Private Components können via Git-URL in `idf_component.yml` definiert werden
## Future Extensions (Phase 4+)

Diese Punkte sind NICHT in Phase 1-3 geplant, aber sind später möglich:

1. **`/add-library` Skill** – Automatisierte Component-Integration
   - User: `/add-library dht_sensor`
   - Skill: Fügt zu `idf_component.yml` ein, führt `idf.py build` aus
   - Spart manuelles YAML-Editing

2. **CI/CD Integration** – GitHub Actions / GitLab CI
   - Auto-Build bei Push
   - Artifact-Generierung
   - (aktuell: Scope-Constraint in Phase 1)

3. **Custom Component Generator**
   - Scaffold für neue Components
   - `/create-component my_sensor` → generiert Grundgerüst

4. **OTA (Over-The-Air) Updates**
   - Firmware-Updates via WiFi
   - Partition-Management für A/B Updates
   - (aktuell: Scope-Constraint)