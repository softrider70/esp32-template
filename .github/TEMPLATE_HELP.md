# ESP32 Template - Anleitung

## 🎯 Was ist dieses Template?

Ein reproduzierbares **ESP-IDF native** ESP32-Template mit automatisiertem Projekt-Generator.

---

## 📋 Schnellstart

### 1. Neues Projekt erstellen
```powershell
.\new-project.ps1
```

**Interaktiv:**
- Projektname eingeben (z.B. "MyDeviceController")
- Board auswählen (ESP32 / S2 / S3 / C3 / C6)

**oder mit Parametern:**
```powershell
.\new-project.ps1 -ProjectName "MyDevice" -Board "C3"
```

**Ergebnis:**
- Neuer Ordner: `C:\Users\win4g\Downloads\GitHub\VS-Projekte\MyDevice\`
- Alle Grunddateien kopiert und konfiguriert
- Git Repository initialisiert
- Bereit zum Entwickeln!

---

## 🛠️ Im generierten Projekt arbeiten

### Build
```
/build-project
```
→ Führt `idf.py build` aus, kompiliert Firmware

### Upload (Smart)
```
/upload
```
→ Fragt: "Is this the FIRST flash? [j/n]"
- **Ja:** Vollständiger Flash (Bootloader + Partition + App) - nur beim ersten Mal!
- **Nein:** Nur App flashen (schnell, ~2-5 Sekunden)

### Direct Upload
```
/upload-firmware     # Nur App flashen
/upload --full       # Erzwingt vollständigen Flash
/initial-upload      # Für erste Installation oder Recovery
```

---

## 📦 Libraries hinzufügen (Components)

### Via Component Registry (Espressif)
Bearbeite `idf_component.yml`:
```yaml
dependencies:
  espressif/button: "^2.4.0"
  espressif/dht: "^1.0.0"
```

`idf.py build` lädt Dependencies automatisch.

---

## 📚 Dateistruktur

```
projekt-ordner/
├── plan.md                    ← Kopie aus Template  
├── PROJECT.md                 ← Projektspezifische Docs
├── CHANGES.md                 ← Änderungslog
├── src/
│   └── main.c                 ← Dein Code hier
├── include/
│   ├── config.h               ← Konfiguration
├── CMakeLists.txt             ← Build-Config
├── idf_component.yml          ← Dependencies
├── sdkconfig.defaults         ← ESP-IDF Config (Board-spezifisch)
├── .github/
│   ├── agents/                ← Copilot Agenten
│   ├── skills/
│   │   ├── build-project/
│   │   ├── upload/
│   │   ├── upload-firmware/
│   │   └── initial-upload/
│   └── copilot-instructions.md
└── .git                       ← Git Repository
```

---

## 🔧 Board-spezifische Konfiguration

### Unterstützte Boards

| Board | Cores | RAM | Config |
|-------|-------|-----|--------|
| ESP32 | 2 | 520KB + PSRAM | Standard |
| S2 | **1** | 320KB | Single-Core |
| S3 | 2 | 512KB + PSRAM | Dual USB |
| C3 | **1** | 400KB | RISC-V |
| C6 | 2 | 512KB + PSRAM | Neuest |

**Single-Core (S2, C3):** 
- `CONFIG_FREERTOS_NO_AFFINITY=y` ist bereits gesetzt in `sdkconfig.defaults`
- Keine Task-Pinning nötig!

---

## 🔐 Security & Best Practices

### NVS für Secrets
**NICHT:** Passwörter in config.h hardcoden
**RICHTIG:** NVS (Non-Volatile Storage) nutzen für WLAN-Credentials

Beispiel in `main.c`:
```c
// NVS Read
nvs_handle_t nvs_handle;
nvs_open("storage", NVS_READONLY, &nvs_handle);
char ssid[32];
nvs_get_str(nvs_handle, "ssid", ssid, sizeof(ssid));
```

### Secure Boot / Flash Encryption (Optional)
In `sdkconfig.defaults` (aktuell kommentiert):
```
# CONFIG_SECURE_BOOT=y
# CONFIG_SECURE_FLASH_ENC=y
```
Aktivieren via: `idf.py menuconfig` (production-only!)

---

## 🐛 Troubleshooting

### Build-Fehler
```
/build-project
→ Fehler?
→ Versuche: idf.py menuconfig (für Board-Konfiguration)
```

### Upload-Fehler
```
/upload-firmware
→ "Failed to connect"
→ Prüfe: Ist das Board angesteckt? Richtige COM-Port?
→ Versuche: /build-project erneut
```

### IDF nicht installiert?
```powershell
# Windows:
python -m venv ~/esp
~/esp/Scripts/activate
pip install esp-idf esptool

# oder:
Download: https://docs.espressif.com/projects/esp-idf/en/latest/esp32/
```

---

## 📖 Weitere Dokumentation

- **BUILD_GUIDE.md** – Manuelle Build/Upload Befehle
- **SECURITY.md** – Security Features & Best Practices
- **PROJECT.md** – Projektspezifische Infos
- **plan.md** – Original Template Plan

---

## 💡 Tipps

1. **Iteratives Entwickeln:** `/upload-firmware` ist schnell (nur App)
2. **Neuer Sensor?** `idf_component.yml` ergänzen → `idf.py build`
3. **Mehrere Boards?** Template selbst nicht ändern, Projects sind unabhängig
4. **Backup!** In `CHANGES.md` wichtige Änderungen dokumentieren

---

## ❓ Fragen?

- Frage mich: "Was ist dieses Template?" oder "Wie baue ich ein neues Projekt?"
- Schau in IMPLEMENTATION_PLAN.md für technische Details
- Nutze die Skills: `/build-project`, `/upload`, etc.

**Happy Coding! 🚀**
