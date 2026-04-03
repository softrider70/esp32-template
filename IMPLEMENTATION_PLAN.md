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
1. `plan.md` – Kopiere Template-Plan ins Projekt (Quelle wird spezifiziert oder ist bereits vorhanden)
   - Dieses Dokument (IMPLEMENTATION_PLAN.md) oder eine spezialisierte `esp32-template-plan.md` wird als `plan.md` ins Projekt kopiert
   - Enthält technische Referenz für das Template
   - Wird nicht vom Generator modifiziert
2. `CMakeLists.txt` (Top-Level) – ESP-IDF Build-Konfiguration mit Komponenten-Struktur
   - Nutzt `PROJECT_NAME` Variable für Binary-Naming: `build/${PROJECT_NAME}.bin`
   - Generator setzt `PROJECT_NAME` beim Kopieren
3. `src/main.c` als board-agnostisches ESP-IDF Einsteiger-Gerüst (app_main)
   - FreeRTOS Task Beispiel
   - NVS Initialization
   - Logging via ESP_LOG
   - Graceful Error Handling
4. `include/config.h` mit Platzhaltern für Pins, WLAN und `BOARD_TYPE`
   - FreeRTOS Task Stack-Größen (Task-Defaults)
   - NVS-Keys für Secrets Management
   - UART/GPIO Pin-Definitionen (Board-agnostisch, Standard-Pins)
5. `idf_component.yml` – Dependency Management (initial leer, ermöglicht zukünftige Library-Integration)
   - Format: ESP-IDF Component Registry kompatibel
   - Skalierung: Kann später via `/add-library` Skill erweitert werden
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
9. `README.md` – Generator-Workflow, ESP-IDF Setup-Anleitung
10. `.github/agents/` – Lean-Workspace-Agent, Spezial-Agenten, copilot-instructions.md
11. `.github/skills/build-project/` – Build-Skill
    - `SKILL.md` – Copilot Chat Instruction
    - `build-project.ps1` – Script: `idf.py build`, generiert `build/${PROJECT_NAME}.bin`, Error-Handling
12. `.github/skills/upload/` – Upload Meta-Skill (Smart Router)
    - `SKILL.md` – Copilot Chat Instruction
    - `upload.ps1` – Script: Fragt \"First time flash? [j/n]\"
      * ja → ruft `/initial-upload` auf (Bootloader + Partition + App, ~20sec)
      * nein → ruft `/upload-firmware` auf (nur App, ~3sec)
13. `.github/skills/upload-firmware/` – Upload-Firmware-Skill (App-Only)
    - `SKILL.md` – Copilot Chat Instruction
    - `upload-firmware.ps1` – Script: `esptool.py write_flash 0x10000 build/${PROJECT_NAME}.bin`, Error-Analyse
14. `.github/skills/initial-upload/` – Upload-Initial-Skill (Full Flash)
    - `SKILL.md` – Copilot Chat Instruction
    - `initial-upload.ps1` – Script: `esptool.py write_flash 0x0 build/bootloader.bin 0x8000 build/partition-table.bin 0x10000 build/${PROJECT_NAME}.bin`, nur 1x nötig
15. `.github/skills/commit/` – Commit-Skill mit intelligenter Message-Generierung
    - `SKILL.md` – Copilot Chat Instruction
    - `commit.ps1` – Script: `git add .`, `git diff --cached --stat`, gibt Kontext an Copilot
      * Copilot generiert aussagekräftige Message basierend auf tatsächlichen Änderungen
      * User bestätigt oder editiert Vorschlag
      * `git commit -m "<approved-message>"` ausführen
      * Bietet Push-Option an: "Zu GitHub pushen? [j/n]" → Bei ja: `git push origin master`, Bei nein: Lokal gespeichert
16. `SECURITY.md` – NVS-Setup, TLS/mTLS, Secure Boot Guide
17. `BUILD_GUIDE.md` – Manuelle `idf.py build`, `esptool.py` Upload, Troubleshooting

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
   - Neues Git lokales Repository: `git init`, `git config user.name/email` (optional)
   - Initial-Commit via `/commit` Skill (automatisch `git add .` im Skill, User wird nach Nachricht gefragt mit Vorschlag "Initial commit: <ProjectName> template fork")
   - Output: Neue Projekt-Ordner ist initialisiert und bereit für `/build-project`
4. Build-Skill Setup:
   - `build-project.ps1` ist im Template vorhanden
   - User/Copilot ruft `/build-project` auf → Script führt `idf.py build` aus
   - Bei Fehler: Outputs zeigen, vorschlagen zu `idf.py menuconfig` (für Board-Konfiguration)
5. Upload-Skill Setup (Smart Router):
   - **Meta-Skill `/upload`**: User/Copilot ruft `/upload` auf
     * Script fragt: "First time flash (bootloader + partition)? [j/n]"
     * ja → ruft `/initial-upload` Skill auf (Bootloader 0x0 + Partition 0x8000 + App 0x10000, ~20sec)
     * nein → ruft `/upload-firmware` Skill auf (nur App 0x10000, ~3sec, schnell iterativ)
   - **Skill `/upload-firmware`** (App-Only, iterativ):
     * Script fragt nach COM-Port (z.B. COM3)
     * Führt aus: `esptool.py --port COMx --baud 921600 write_flash 0x10000 build/${PROJECT_NAME}.bin`
     * Error-Analyse: COM-Port, Timeout, File not found
   - **Skill `/initial-upload`** (Full Flash, einmalig):
     * Script fragt nach COM-Port
     * Führt aus: `esptool.py --port COMx --baud 921600 write_flash 0x0 build/bootloader.bin 0x8000 build/partition-table.bin 0x10000 build/${PROJECT_NAME}.bin`
     * Error-Handling: Board-Reset, ggf. BOOT/EN Pin halten
6. Commit-Skill Setup:
   - `commit.ps1` ist im Template vorhanden
   - User/Copilot ruft `/commit` auf
   - Script führt aus: `git add .`, dann `git diff --cached --stat` + `git status` um Änderungen anzuzeigen
   - **Wichtig:** Script gibt den Kontext (git diff / geänderte Dateien) an den Copilot aus
   - **Copilot generiert automatisch aussagekräftige Commit-Message** basierend auf den tatsächlichen Änderungen aus Git
     - Beispiel: Bei main.c Änderung: "refactor: simplify task loop in main.c"
     - Beispiel: Bei CMakeLists + config.h: "feat: add I2C driver support with new config options"
   - Copilot präsentiert Vorschlag: "Commit-Nachricht: '<generated-message>' - OK? [j/n]"
   - User bestätigt oder editiert
   - Script führt aus: `git commit -m "<approved-message>"`
   - Output zeigt: Commit-Hash, changed files, Committer
   - Bietet an: "Zu GitHub pushen? [j/n]" → Bei ja: `git push --all`, Bei nein: Lokale Änderungen gespeichert

### Phase 3: Robustheit & Verifikation

#### 3.1 Robustheit
1. Projektname validieren (nicht leer, keine ungueltigen Zeichen).
2. Abbruch, wenn Zielordner bereits existiert.
3. Board-Auswahl validieren.
4. Fehlerausgabe fuer Copy-/Git-Fehler mit sauberem Abbruch.

#### 3.2 Verifikation (Test-Checklist)
1. Script ohne Parameter starten: Menü erscheint und nimmt gültige Auswahl an.
2. Testlauf `C3`: Zielordner entsteht, `.git` ist frisch initialisiert.
3. `PROJECT.md` enthält korrektes Board (ESP-IDF C3) und Basisprofil.
4. `CHANGES.md` ist vorhanden und leer.
5. `sdkconfig.defaults` existiert (Kopie von `sdkconfig.defaults.esp32c3`)
6. `sdkconfig.defaults.*` (andere Varianten) sind **gelöscht**
7. `config.h` ist Standard-Template (keine Board-spezifischen Conditionals nötig für Upload).
8. `.github/agents/` und `.github/copilot-instructions.md` sind im Zielprojekt vorhanden.
9. `.github/skills/build-project/`, `.github/skills/upload/`, `.github/skills/upload-firmware/`, `.github/skills/initial-upload/`, `.github/skills/commit/` sind im Zielprojekt vorhanden.
10. `idf.py build` läuft ohne kritische Fehler (oder mit Hinweis "IDF nicht installiert" [akzeptabel]).
11. `/upload` fragt "First time flash?" und routet korrekt zu `/initial-upload` oder `/upload-firmware`.
12. Binary-Name ist `build/${PROJECT_NAME}.bin` (z.B. `build/MyDevice.bin`).
13. Testlauf S2: Validieren dass `CONFIG_FREERTOS_NO_AFFINITY=y` in `sdkconfig.defaults.*` vorhanden ist.
14. Testlauf S3 vs ESP32: Upload-Kommando ist **identisch** (beide 0x10000, nur App).
15. `/commit` generiert intelligente Message basierend auf `git diff --cached`.
16. Negativtests: ungültiger Projektname, ungültiges Board, existierender Zielordner → Error-Handling prüfen.

## Board-Mapping (ESP-IDF native)

| Input | IDF_TARGET | Board-ID | Config Key | Cores | RAM | Single-Core Config |
|------|------------|----------|------------|-------|-----|----|
| ESP32 | esp32 | esp32dev | `CONFIG_IDF_TARGET_ESP32=y` | 2 | 520KB SRAM + PSRAM | – |
| S2 | esp32s2 | esp32-s2-devkitm-1 | `CONFIG_IDF_TARGET_ESP32S2=y` | 1 | 320KB SRAM | `CONFIG_FREERTOS_NO_AFFINITY=y` |
| S3 | esp32s3 | esp32-s3-devkitc-1 | `CONFIG_IDF_TARGET_ESP32S3=y` | 2 | 512KB SRAM + PSRAM | – |
| C3 | esp32c3 | esp32-c3-devkitm-1 | `CONFIG_IDF_TARGET_ESP32C3=y` | 1 | 400KB SRAM | `CONFIG_FREERTOS_NO_AFFINITY=y` |
| C6 | esp32c6 | esp32-c6-devkitc-1 | `CONFIG_IDF_TARGET_ESP32C6=y` | 2 | 512KB SRAM + PSRAM | – |

**Upload: Alle Boards verwenden gleichen esttool.py Befehl (App-Only):**
```powershell
esptool.py --port COMx --baud 921600 write_flash 0x10000 build/${PROJECT_NAME}.bin
```

**Initial-Upload (nur 1x beim Start):**
```powershell
esptool.py --port COMx --baud 921600 write_flash 0x0 build/bootloader.bin 0x8000 build/partition-table.bin 0x10000 build/${PROJECT_NAME}.bin
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
12. Binary-Name ist `build/${PROJECT_NAME}.bin` (z.B. `build/MyDevice.bin`).
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
- Output: Build-Log, Erfolg/Fehler, Dateigröße Firmware (`build/${PROJECT_NAME}.bin`)
- Error-Handling: Bei Fehler → Hinweis auf `idf.py menuconfig`
- Persistiert: Build-Artefakte in `build/` für Upload-Skills

### upload Skill (Meta-Router)
- Auslösung: `/upload` im Copilot Chat
- Funktion:
  1. Fragt: "Is this the FIRST flash (bootloader + partition)? [j/n]"
  2. ja → ruft `/initial-upload` auf
  3. nein → ruft `/upload-firmware` auf
- Recovery: User kann wechseln zwischen initial und app-only je nachdem

### upload-firmware Skill
- Auslösung: `/upload-firmware` im Copilot Chat
- Funktion (App-Only, schnell für Iteration):
  1. Fragt nach COM-Port: "Welcher COM-Port? (z.B. COM3)"
  2. Führt aus: `esptool.py --port COMx --baud 921600 write_flash 0x10000 build/${PROJECT_NAME}.bin`
- Error-Analyse:
  - `Failed to connect`: COM-Port nicht verfügbar oder Board antwortet nicht
  - `File not found`: Build-Artefakt fehlt → `/build-project` aufrufen
  - `Timeout`: Board reagiert nicht, USB-Kabel prüfen
- Recovery: Bei wiederholtem Fehler → Link zu `BUILD_GUIDE.md` Troubleshooting

### initial-upload Skill
- Auslösung: `/initial-upload` im Copilot Chat oder automatisch via `/upload` → ja
- Funktion (Full Flash, nur 1x am Anfang):
  1. Fragt nach COM-Port
  2. Führt aus: `esptool.py --port COMx --baud 921600 write_flash 0x0 build/bootloader.bin 0x8000 build/partition-table.bin 0x10000 build/${PROJECT_NAME}.bin`
  3. Warnung: "Dies ist ein one-time setup. Danach: `/build-project` → `/upload-firmware`"
- Error-Handling: Bei Upload-Fehler → Bootloader-Neustart-Anleitung, ggf. BOOT/EN Pin halten

## Phase 4+: Future Extensions (Backlog)

Folgende Features sind intentional **nicht** in Phase 1-3 enthalten, können aber später hinzugefügt werden:

### Phase 4a: Library Management (`/add-library` Skill)
- `add-library.ps1` – Interaktive Library-Selection aus Espressif Component Registry
- Modifiziert `idf_component.yml` automatisch
- `idf.py build` löst Dependencies auf

### Phase 4b: CI/CD Integration
- GitHub Actions workflow für `.github/workflows/build.yml`
- Auto-Build auf Push
- Artifacts: Firmware-Binaries pro Board-Variante

### Phase 4c: OTA (Over-The-Air) Updates
- OTA Partition-Support in `sdkconfig.defaults`
- OTA-Skill im Template
- NVS-basierte Rollback-Mechanik

### Phase 4d: Multi-Board Build Automation
- `/build-all-boards` Skill – Build für alle 5 Boards parallel
- Output: `build/ep32.*`, `build/esp32s2.*`, ... der Binaries

### Phase 4e: WebUI für Device Management
- `esp-idf` native littlefs/SPIFFS integrieren
- REST API in `main.c` Template
- Einfache HTML Dashboard für Konfiguration

- **Balanced (default)**: Normal Operation, `esp_pm_configure()` mit 80/160/240 MHz (Board-abhängig)
- **Power-Save**: Light Sleep (auto), Core-Gating, ~50mA
- **Deep-Sleep**: `esp_sleep_enable_timer_wakeup()`, nur RTC aktiv, ~11µA
- In `main.c` Template: Commented-out Beispiele für alle 3 Profile
- Konfiguration via `sdkconfig`: `CONFIG_PM_ENABLE=y` + `CONFIG_PM_DFS_INIT_AUTO=y`
- Board-Unterschiede: C6 native Thread-Support für besseres PM

## Scope-Grenzen (Phase 1-3)
1. Keine RPI/STM32-Unterstuetzung in dieser Version.
2. Lokales Build/Upload via Skills: `/build-project`, `/upload` (Meta), `/upload-firmware`, `/initial-upload` (in generierten Projekten verfügbar)
3. Keine automatische Ruecksynchronisierung von Projekt-`CHANGES.md` ins Template.
4. Keine statische Tool-Deaktivierung — Tool-Policies nicht via Hooks umsetzbar in VS Code Copilot Chat.
5. Secure Boot/Flash Encryption sind optional – werden via `idf.py menuconfig` aktiviert
6. TLS-Zertifikate müssen selbst bereitgestellt werden (nicht auto-generated)
7. Upload: App-Only (0x10000) iterativ, Initial-Upload (0x0 + 0x8000 + 0x10000) nur 1x
8. Upload-Kommando ist identisch für alle Boards (App-Offset 0x10000)
9. Component Management (`idf_component.yml`) ist initial leer, wird in Phase 4 erweitert
10. idf_component.yml-Manipulation nur manuell möglich (Phase 4 `/add-library` Skill geplant)
11. ESP-IDF muss lokal installiert sein (IDF_PATH Umgebungsvariable)
12. esttool.py muss installiert sein (über `pip install esptool`)
13. Build/Upload-Skills sind lokale Automation – kein CI/CD, kein Cloud-Build (Phase 4 geplant)
14. Multi-Board-Build nicht automatisiert (Phase 4 `/build-all-boards` Skill geplant)
15. OTA-Updates nicht unterstützt (Phase 4 geplant)

## Power Management Profile (ESP-IDF native)

- **Balanced (default)**: Normal Operation, `esp_pm_configure()` mit 80/160/240 MHz (Board-abhängig)
- **Power-Save**: Light Sleep (auto), Core-Gating, ~50mA
- **Deep-Sleep**: `esp_sleep_enable_timer_wakeup()`, nur RTC aktiv, ~11µA
- In `main.c` Template: Commented-out Beispiele für alle 3 Profile
- Konfiguration via `sdkconfig`: `CONFIG_PM_ENABLE=y` + `CONFIG_PM_DFS_INIT_AUTO=y`
- Board-Unterschiede: C6 native Thread-Support für besseres PM

## Component Management (idf_component.yml)

**Phase 1 (Initial):**
- `idf_component.yml` ist vorhanden aber **leer**
- Ermöglicht zukünftige Library-Integration

**Phase 4 (`/add-library` Skill geplant):**
- Automatische YAML-Modifikation
- Espressif Component Registry Integration
- Beispiel: `/add-library button` → fügt `espressif/button: ^2.4.0` zu idf_component.yml hinzu
