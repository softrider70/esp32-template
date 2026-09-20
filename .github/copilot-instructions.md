# Copilot-Instruktionen – ESP32-Vorlage (template)

**Dieses Projekt ist die Vorlage** fuer neue ESP32-Projekte: ESP-IDF,
Projekt-Generator und mehrere `sdkconfig.defaults` fuer verschiedene Chips
(ESP32, S2, S3, C3, C6).

- Doku im Projekt: `README.md`, `BUILD_GUIDE.md` (Bauen und Hochladen von Hand),
  `SECURITY.md` (NVS-Verschluesselung, Secure Boot, TLS), `include/config.h`.
- **Sprache ist Deutsch** - Antworten, Kommentare und Doku.
- Kurze Saetze, Fachwoerter erklaeren, keine Vermutungen: pruefen statt raten.
- Bauen und flashen: ESP-IDF (6.1) aktivieren, PATH aufraeumen, dann
  `idf.py -p COMx flash`.

## Hinweis zu den alten Skill-Dateien

Unter `.github/agents/<name>/SKILL.md` liegt noch eine Reihe alter Anleitungen
(`build-project`, `upload`, `initial-upload`, `commit`, ...). Diese Befehle
haben **nie funktioniert**: VS Code sucht Anleitungen dieser Art in
`.github/skills/<name>/`, und die Kopfzeilen der alten Dateien passen nicht
(`title:` statt `name:`/`description:`). Wenn so etwas gebraucht wird, bitte
neu am richtigen Ort anlegen - nicht die alten Dateien weiterverwenden.
