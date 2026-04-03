# ESP32 Project Template 🚀

Ein reproduzierbares **ESP-IDF native** Template für ESP32-Projekte mit automatisiertem Projekt-Generator und intelligenten Build/Upload-Skills.

> **Status:** Design-Phase ✅ | Phase 1 Implementation in progress...

---

## 🎯 Was ist das?

**Das Problem:** Jedes neue ESP32-Projekt braucht...
- CMakeLists.txt, sdkconfig, Verzeichnisstruktur
- Board-spezifische Konfiguration
- Build & Upload Automation
- Git-Setup

**Die Lösung:** Dieses Template! ✨

```powershell
# Einmal im Template-Verzeichnis:
.\new-project.ps1 -ProjectName "MyDevice" -Board "C3"

# → Neuer Projekt-Ordner mit allem, was du brauchst!
```

---

## 🌟 Kernfeatures

✅ **ESP-IDF Native** (nicht Arduino/PlatformIO)
- Offizielle Espressif Framework
- Volle Hardware-Kontrolle
- Security Built-in (NVS, Secure Boot, TLS)
- Production-grade

✅ **5 Board-Varianten**
- ESP32 (Dual-Core)
- ESP32-S2 (Single-Core)
- ESP32-S3 (Dual-Core + USB)
- ESP32-C3 (RISC-V Single-Core)
- ESP32-C6 (Dual-Core + Thread)

✅ **Intelligente Skills & Automation**
- `/build-project` – Kompiliert Firmware
- `/upload` – Smart Router (First time? → Initial / Iterativ)
- `/upload-firmware` – App-only Flash (~3sec)
- `/initial-upload` – Vollständiger Flash (~20sec)
- `/commit` – Git mit AI-generierter Message

✅ **Component Management**
- `idf_component.yml` für Dependencies
- Espressif Component Registry Support
- Zukünftig: `/add-library` Auto-Integration

---

## 📋 Quick Start

### 1. Template klonen
```bash
git clone https://github.com/softrider70/esp32-template.git
cd esp32-template
```

### 2. Neues Projekt erstellen
```powershell
.\new-project.ps1
```

**Interaktiv:**
```
Projektname: MyDevice
Board (1=ESP32, 2=S2, 3=S3, 4=C3, 5=C6): 3
```

**Oder mit Parametern:**
```powershell
.\new-project.ps1 -ProjectName "MyDevice" -Board "C3"
```

### 3. Im generierten Projekt arbeiten
```powershell
cd C:\Users\...\MyDevice

# Code bearbeiten
code src/main.c

# Kompilieren
/build-project

# Flashen (Smart)
/upload        # → "First time?" [j/n]

# Committen
/commit        # → AI-Message + "Push?" [j/n]
```

---

## 🛠️ Workflow

### Erstes Mal (Initial-Setup)
```
1. Projekt generieren: .\new-project.ps1
   ↓ Git init + initial commit
2. /build-project
   ↓ Kompiliert Firmware
3. /upload
   ↓ Fragt: "First time flash?"
   ↓ ja → /initial-upload (Bootloader + Partition + App)
4. /commit
   ↓ Git staggt + AI generiert Message
   ↓ "Push zu GitHub?"
```

### Iteratives Entwickeln (Danach)
```
1. Code ändern (src/main.c)
2. /build-project
3. /upload
   ↓ nein → /upload-firmware (nur App, ~3sec)
4. /commit
   ↓ Repeat
```

---

## 📦 Supportierte Boards

| Board | Cores | RAM | Architektur | Config |
|-------|-------|-----|-------------|--------|
| **ESP32** | 2 | 520KB + PSRAM | Xtensa | Standard |
| **S2** | 1 | 320KB | Xtensa | Single-Core ⚠️ |
| **S3** | 2 | 512KB + PSRAM | Xtensa | USB Support |
| **C3** | 1 | 400KB | RISC-V | Single-Core ⚠️ |
| **C6** | 2 | 512KB + PSRAM | RISC-V | Thread-Support |

⚠️ Single-Core Boards: `CONFIG_FREERTOS_NO_AFFINITY=y` ist gesetzt

---

## 📚 Dateistruktur (generiertes Projekt)

```
projekt-name/
├── plan.md                    ← Kopie aus Template
├── PROJECT.md                 ← Projektspezifische Docs
├── CHANGES.md                 ← Änderungslog
├── README.md                  ← Diese Datei
│
├── src/
│   └── main.c                 ← Dein Code
├── include/
│   └── config.h               ← Konfiguration
│
├── CMakeLists.txt             ← Build-Config (nutzt ${PROJECT_NAME})
├── idf_component.yml          ← Dependencies
├── sdkconfig.defaults         ← ESP-IDF Config (Board-spezifisch)
│
├── .github/
│   ├── agents/                ← Copilot Agenten
│   ├── skills/
│   │   ├── build-project/
│   │   ├── upload/
│   │   ├── upload-firmware/
│   │   ├── initial-upload/
│   │   └── commit/
│   ├── copilot-instructions.md
│   └── TEMPLATE_HELP.md
│
└── .git/                      ← Git Repository (frisch initialisiert)
```

---

## 🔧 Skills im Detail

### `/build-project`
Kompiliert die Firmware via `idf.py build`.

```
Input: (keine)
Output: 
  ✓ Build-Log
  ✓ Binary: build/${PROJECT_NAME}.bin
  ✓ Größe & Speicherauslastung
Error-Handling: 
  → Hinweis auf idf.py menuconfig bei Fehlern
```

### `/upload` (Smart Router)
Fragt ob Erstes Mal → routet intelligent.

```
Frage: "Is this the FIRST flash (bootloader + partition)? [j/n]"
  ja  → /initial-upload (Bootloader 0x0 + Partition 0x8000 + App 0x10000, ~20sec)
  nein → /upload-firmware (nur App 0x10000, ~3sec)
```

### `/upload-firmware` (App-Only)
Schneller App-Flash für Iteration.

```
Freagt: COM-Port?
Flasht: 0x10000 build/${PROJECT_NAME}.bin
Speed: ~3 Sekunden
```

### `/initial-upload` (Full Flash)
Vollständiger Flash beim ersten Mal.

```
Flasht: 
  0x0      → Bootloader
  0x8000   → Partition Table
  0x10000  → App
Time: ~20 Sekunden
Warnung: "One-time only! Danach /upload-firmware nutzen"
```

### `/commit` (Git mit AI)
Git Add + AI-generierte Message.

```
Action:
  1. git add .
  2. git diff --cached --stat (zeige Änderungen)
  3. Copilot generiert aussagekräftige Message
  4. User bestätigt oder editiert
  5. git commit -m "<message>"
  6. Frage: "Push zu GitHub?"
     ja  → git push --all
     nein → Lokal gespeichert
```

---

## 🔧 Konfiguration

### Board wechseln?
Im Projekt: `sdkconfig.defaults` ist Board-spezifisch!
```bash
# Für neues Board:
cp sdkconfig.defaults.esp32c3 sdkconfig.defaults
rm -rf build/
/build-project
```

### Libraries hinzufügen?
Bearbeite `idf_component.yml`:
```yaml
dependencies:
  espressif/button: "^2.4.0"
  espressif/dht: "^1.0.0"
```
Dann: `/build-project` → Dependencies werden automatisch gelöst

### Secrets Management?
Nutze NVS (Non-Volatile Storage), nicht hardcoded:
```c
// In main.c:
nvs_handle_t handle;
nvs_open("storage", NVS_READONLY, &handle);
char password[32];
nvs_get_str(handle, "wifi_pwd", password, sizeof(password));
```

---

## 🐛 Troubleshooting

### `idf.py build` fehlgeschlagen?
```
→ /build-project
→ Fehler anschauen
→ idf.py menuconfig (für Board-Config)
→ /build-project erneut
```

### `upload-firmware` verbindet nicht?
```
1. COM-Port überprüfen (Device Manager)
2. Board angesteckt? USB-Kabel OK?
3. Bootloader-Problem? → /initial-upload versuchen
4. ESP-IDF neuinstallieren?
```

### IDF nicht installiert?
```bash
# Windows:
pip install esp-idf esptool
idf install
```

---

## 📖 Weitere Dokumentation

- **[IMPLEMENTATION_PLAN.md](IMPLEMENTATION_PLAN.md)** – Technische Spezifikation
- **[plan.md](plan.md)** – Original Template Plan (kopiert ins Projekt)
- **[.github/TEMPLATE_HELP.md](.github/TEMPLATE_HELP.md)** – Detaillierte Hilfe
- **[SECURITY.md](SECURITY.md)** – NVS, Secure Boot, TLS Setup (Phase 1)
- **[BUILD_GUIDE.md](BUILD_GUIDE.md)** – Manuelle Build/Upload-Befehle (Phase 1)

---

## 🚀 Phase 1 Status

**Momentan:** Design-Phase ✅

**Pending Phase 1 Files:**
- [ ] src/main.c – FreeRTOS Boilerplate
- [ ] include/config.h – Pin & Task Config
- [ ] CMakeLists.txt (Top-Level + src/)
- [ ] idf_component.yml – Component Registry
- [ ] sdkconfig.defaults (+ 5 Board-Varianten)
- [ ] PROJECT.md.template
- [ ] SECURITY.md
- [ ] BUILD_GUIDE.md
- [ ] .github/agents/* (Copilot Config)
- [ ] .github/skills/** (4 Skills: build, upload-router, firmware, initial, commit)

**Pending Phase 2:**
- [ ] new-project.ps1 – Generator Script

**Pending Phase 3:**
- [ ] Robustheit & Error-Handling
- [ ] Test-Verifikation (16-Point Checklist)

---

## 🎯 Zukunft (Phase 4+)

- **Phase 4a:** `/add-library` Skill (Auto-YAML-Injection)
- **Phase 4b:** CI/CD GitHub Actions (Auto-Build)
- **Phase 4c:** OTA (Over-The-Air) Updates
- **Phase 4d:** `/build-all-boards` (Multi-Board Parallel)
- **Phase 4e:** WebUI Dashboard (littlefs + REST API)

---

## 📄 Lizenz

MIT – Frei verwendbar für private & kommerzielle Projekte

---

## 🤝 Kontakt

**Maintainer:** softrider70  
**GitHub Issues:** [esp32-template/issues](https://github.com/softrider70/esp32-template/issues)

---

## 💡 Quick Reference

```powershell
# Template-Ordner
.\new-project.ps1                 # Neues Projekt erstellen

# Im Projekt
/build-project                    # Kompilieren
/upload                           # Smart Flash
/upload-firmware                  # App-only (schnell)
/initial-upload                   # Full Flash (1x)
/commit                          # Git + AI-Message
```

---

**Bereit zum Starten?** Klone das Template und führe `new-project.ps1` aus! 🚀
