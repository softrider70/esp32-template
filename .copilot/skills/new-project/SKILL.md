---
name: new-project
description: Erstellt ein neues ESP32-Projekt aus dem Template mit interaktiver Konfiguration
user-invocable: true
---

# /new-project - Neues ESP32 Projekt erstellen

**Beschreibung:** Generiert ein neues ESP32-Projekt mit automatischer Konfiguration und Variablen-Substitution.

## Verwendung

Einfach eingeben:
```
/new-project
```

Das Skill wird dich Schritt-für-Schritt durch die Konfiguration leiten.

## Interaktive Schritte

1. **Projektname?** (z.B. `sensor-hub`, `iot-device`)
   - Validierung: 3-50 Zeichen, lowercase, alphanumeric + Hyphens
   - Keine Großbuchstaben, keine Sonderzeichen
   
2. **Welches Board?**
   ```
   1 = ESP32 (dual-core, 520KB SRAM + PSRAM)
   2 = ESP32-S2 (single-core, 320KB SRAM)
   3 = ESP32-S3 (dual-core, 512KB SRAM + PSRAM)
   4 = ESP32-C3 (RISC-V, 400KB SRAM)
   5 = ESP32-C6 (RISC-V, 512KB SRAM + PSRAM)
   ```

3. **Zielverzeichnis?** (Default: aktuelles Verzeichnis)

4. **Git-Repository initialisieren?** (y/n, Default: ja)

## Features

✅ Vollständige Projektstruktur-Generierung  
✅ Board-spezifische Konfiguration  
✅ Automatische Variable-Substitution (`${PROJECT_NAME}`)  
✅ Git-Integration (optional)  
✅ Umfangreiche Eingabe-Validierung  
✅ Detaillierte Fehlermeldungen  

## Beispiele

**Minimales Projekt:**
```
/new-project
→ my-app
→ 1 (ESP32)
→ (Enter für aktuelles Verz.)
→ y (Git init)
```

**Mit Custom Verzeichnis:**
```
/new-project
→ wireless-gateway
→ 3 (ESP32-S3)
→ /home/projects/esp32/
→ y
```

## Was wird generiert?

```
my-app/
├── src/
│   ├── main.c
│   └── CMakeLists.txt
├── include/
│   └── config.h
├── CMakeLists.txt
├── idf_component.yml
├── sdkconfig (board-spezifisch automatisch gewählt)
│   ├── sdkconfig.defaults
│   ├── sdkconfig.defaults.esp32
│   └── ... (5 Varianten)
├── .vscode/
│   ├── settings.json
│   ├── launch.json
│   └── extensions.json
└── .git/ (wenn aktiviert)
```

## Fehlerbehandlung

| Fehler | Ursache | Lösung |
|--------|--------|--------|
| "Template nicht gefunden" | Template-Datei nicht im Pfad | Stelle sicher, dass das Skript aus dem Template-Dir läuft |
| "Projektname ungültig" | Ungültige Zeichen oder Länge | Nutze nur a-z, 0-9, Hyphens; 3-50 Zeichen |
| "Verzeichnis existiert" | Folder mit Namen gibt's schon | Nutze `-Force` zum Überschreiben |
| "Git nicht installiert" | Git nicht im PATH | Git optional; Projekt funktioniert auch ohne |

## Optionale Parameter

Wenn du Automatisierung brauchst:
```bash
./new-project.ps1 -ProjectName my-app -Board 1 -NoConfirm -SkipGit
```

Aber normalerweise: **Einfach `/new-project` im Chat eingeben** 😊

## Nächste Schritte nach Generierung

```bash
# 1. Ins Verzeichnis wechseln
cd my-app

# 2. Dependencies auflösen
idf.py build

# 3. Auf Device flashen
idf.py flash monitor

# 4. Bei Bedarf Features hinzufügen
/add-webui
/add-ota
/add-security
```

## Siehe auch

- [BUILD_GUIDE.md](BUILD_GUIDE.md) - Detaillierte Build-Anleitung
- [PHASE3_REPORT.md](PHASE3_REPORT.md) - Test-Ergebnisse
- `/upload` - Firmware flashen
- `/build-project` - Projekt bauen
