# Plan: ESP32 Template Automation

Status: Ready for implementation
Version: 1.0

## Ziel
Ein reproduzierbares ESP32-Template mit interaktivem Projekt-Generator. Neue Projekte werden unter `C:\Users\win4g\Downloads\GitHub\VS-Projekte\<Projektname>` erzeugt, mit frischem Git-Repo, Board-spezifischer Konfiguration und separater Projektdokumentation.

## Kernprinzipien
1. `plan.md` ist die Basis im Template und wird als Kopie ins Zielprojekt uebernommen.
2. Projektspezifisches Wissen liegt in `PROJECT.md` und `CHANGES.md`, nicht in `plan.md`.
3. Board-Auswahl ist standardmaessig interaktiv per Menue.
4. Fokus bleibt nur auf ESP32-Varianten.

## Umsetzungsphasen

### Phase 1: Template-Basisdateien
1. `plan.md` aus `.windsurf/plans/esp32-template-plan-258012.md` nach `template/plan.md` kopieren.
2. `src/main.cpp` als board-agnostisches Arduino-Grundgeruest anlegen.
3. `include/config.h` mit Platzhaltern fuer Pins, WLAN und `BOARD_TYPE` anlegen.
4. `platformio.ini` mit Environments fuer `esp32`, `esp32-s2`, `esp32-s3`, `esp32-c3`, `esp32-c6` anlegen.
5. `PROJECT.md.template` mit Platzhaltern fuer Projektname, Board, Power-Profil und FreeRTOS-Hinweise anlegen.
6. `README.md` auf den Generator-Workflow ausrichten.
7. `.github/` mit Lean-Workspace-Agent, Spezial-Agenten, Hook und `copilot-instructions.md` als festen Teil des Templates anlegen.

### Phase 2: Generator-Script
1. `new-project.ps1` in der Template-Root erstellen.
2. Eingaben:
   - Projektname (Pflicht)
   - Board (Menueauswahl 1-5; optional per Parameter)
3. Ablauf:
   - Template nach `C:\Users\win4g\Downloads\GitHub\VS-Projekte\<Projektname>` kopieren
   - `.github/` unveraendert mitkopieren, damit Agenten, Hooks und Copilot-Instructions im neuen Projekt direkt verfuegbar sind
   - uebernommenes `.git` entfernen
   - `PROJECT.md.template` zu `PROJECT.md` rendern
   - `CHANGES.md` leer anlegen
   - `platformio.ini` auf das gewaehlte Environment setzen
   - neues Git initialisieren, `git add .`, Initial-Commit erzeugen

### Phase 3: Robustheit
1. Projektname validieren (nicht leer, keine ungueltigen Zeichen).
2. Abbruch, wenn Zielordner bereits existiert.
3. Board-Auswahl validieren.
4. Fehlerausgabe fuer Copy-/Git-Fehler mit sauberem Abbruch.

## Board-Mapping (fachlich)

| Input | PlatformIO env | Board-ID |
|------|-----------------|----------|
| ESP32 | esp32 | esp32dev |
| S2 | esp32-s2 | esp32-s2-devkitm-1 |
| S3 | esp32-s3 | esp32-s3-devkitc-1 |
| C3 | esp32-c3 | esp32-c3-devkitm-1 |
| C6 | esp32-c6 | esp32-c6-devkitc-1 |

Hinweis: Alle genannten Varianten unterstuetzen FreeRTOS. Unterschiede liegen vor allem in Core-Anzahl, Funk-Features und Leistungsaufnahme.

## Verifikation
1. Script ohne Parameter starten: Menue erscheint und nimmt gueltige Auswahl an.
2. Testlauf `C3`: Zielordner entsteht, `.git` ist frisch initialisiert, Initial-Commit vorhanden.
3. `PROJECT.md` enthaelt korrektes Board und Basisprofil.
4. `CHANGES.md` ist vorhanden.
5. `platformio.ini` verweist auf das gewaehlte Environment.
6. `.github/agents/`, `.github/hooks/` und `.github/copilot-instructions.md` sind im Zielprojekt vorhanden.
7. Negativtests: ungueltiger Projektname, ungueltiges Board, existierender Zielordner.

## Scope-Grenzen
1. Keine RPI/STM32-Unterstuetzung in dieser Version.
2. Kein CI/CD und kein automatischer Firmware-Upload.
3. Keine automatische Ruecksynchronisierung von Projekt-`CHANGES.md` ins Template.

## Scope-Grenzen (Teil 2)
4. Keine statische Tool-Deaktivierung ueber Hooks — nicht umsetzbar in VS Code Copilot Chat.
