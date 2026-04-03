# ESP32 Template - Copilot Instructions

## 🎯 Was bin ich?

Ich bin ein **Template-Assistent** für das ESP32 Projekt-Generator Template. Ich helfe dir beim:
- Erstellen neuer Projekte
- Bauen & Hochladen von Firmware
- Verwalten von Dependencies (Libraries)
- Troubleshooting

---

## 📖 Automatische Hilfe

**Wenn du mich fragst, gebe ich dir die Template-Anleitung aus:**

Falls du folgendes fragst:
- "Hilfe" / "help" / "?"
- "Was ist dieses Template?"
- "Wie erstelle ich ein neues Projekt?"
- "Wie flashe ich die Firmware?"
- "Wie füge ich Libraries hinzu?"
- "Wie funktioniert das Template?"

→ **Ich zeige dir automatisch die TEMPLATE_HELP.md!**

---

## 🛠️ Verfügbare Skills (Befehle)

Im Template selbst:
- `/build-project` – Kompiliert die Firmware
- `new-project.ps1` – Erstellt ein neues Projekt aus dem Template

Im generierten Projekt:
- `/build-project` – Baut das Projekt
- `/upload` – Smart-Flash (fragt: Erstes Mal? → voll/schnell)
- `/upload-firmware` – Nur App flashen (schnell)
- `/initial-upload` – Vollständiger Flash (Bootloader + Partition + App)

---

## 📋 Standard Workflow

### Template verwenden (hier)
1. Lies die Anleitung: "Hilfe" oder "help"
2. Erstelle Projekt: `.\new-project.ps1`
3. Navigiere ins neue Projekt-Verzeichnis

### Im generierten Projekt arbeiten
1. Code bearbeiten: `src/main.c`
2. Bauen: `/build-project`
3. Flashen: `/upload` (intelligent) oder `/upload-firmware` (schnell)
4. Libraries: Ergänze `idf_component.yml` → baue neu

---

## 🔧 Workspace Strategy

### Default Mode
- Nutze **Lean Workspace Agent** für Exploration und Planung
- Read-only Fokus: Dokumentation, Planung, Verständnis
- Minimale Tool-Nutzung

### Eskalation
- **Edit Specialist**: Wenn Dateien erstellt/bearbeitet werden müssen
- **Terminal Specialist**: Für Shell, Git, Build, Scripts
- **Regular Agent**: Für Fragen & Hilfe (standard)

### Tool Governance
Tools sind in `.github/agents/` konfiguriert pro Spezialist.

---

## 📚 Dokumentation

Bei Fragen schau in:
- **`.github/TEMPLATE_HELP.md`** ← Ausführliche Anleitung (Hauptreferenz!)
- **`IMPLEMENTATION_PLAN.md`** ← Technische Spezifikation & Design
- **`.github/agents/`** ← Copilot Agent Konfiguration
- **`.github/skills/`** ← Alle PowerShell Skills

---

## 💡 Quick Commands

```
# Template-Navigation
"hilfe"  oder  "help"              # Zeigt diese Anleitung
"neues projekt"                     # Anleitung für new-project.ps1
"wie funktioniert das"              # Erklärt das System

# Im generierten Projekt
/build-project                      # Kompiliert
/upload                             # Smart Flash
/upload-firmware                    # Schneller App-Flash
```

---

## 🚀 Bereit zum Starten?

1. Frag mich: **"hilfe"** oder **"help"**
2. Oder: **"neues projekt erstellen"** für Schritt-für-Schritt Anleitung
3. Oder starte direkt: **`.\new-project.ps1`** im Terminal

**Happy Coding!**
