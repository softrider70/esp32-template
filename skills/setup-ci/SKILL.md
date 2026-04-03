# /setup-ci - Multi-board CI/CD Pipeline

## Beschreibung

Erstellt automatische GitHub Actions CI/CD Pipeline für alle 5 ESP32 Varianten. Kompiliert, testet und validiert Firmware auf jedem Push.

## Funktionalität

Erzeugt GitHub Actions Workflows für:
- Automatische Kompilierung (alle 5 Boards)
- Firmware-Größe-Tracking
- Unit-Tests
- Static Code Analysis
- Build-Artefakte speichern
- Release-Prozess

## Installation

```bash
/setup-ci
```

## GitHub Actions Workflows

### 1. Build Pipeline
```yaml
.github/workflows/build.yml
  - Trigger: push, pull_request
  - Matrix: 5 ESP32-Varianten
  - Artefakte: .bin, .elf, .map
  - Report: Build Log + Größe
```

### 2. Test Pipeline
```yaml
.github/workflows/test.yml
  - Unit Tests (CMocka)
  - Integration Tests
  - Coverage Report
  - Failing Test Detection
```

### 3. Analysis Pipeline
```yaml
.github/workflows/analysis.yml
  - clang-format (Codestyle)
  - cppcheck (Static Analysis)
  - Security Scan
  - Dependencies Check
```

### 4. Release Pipeline
```yaml
.github/workflows/release.yml
  - Build All Variants
  - Create Release Notes
  - Upload Binaries
  - Generate Checksums
```

## Matrix Build Beispiel

```yaml
matrix:
  board: [esp32, esp32s2, esp32s3, esp32c3, esp32c6]
  idf-version: ["v4.4", "v5.0"]

steps:
  - uses: actions/setup-python@v4
  - run: idf.py build -DTARGET=${{ matrix.board }}
```

## Features

✅ Automatische Builds auf allen Boards
✅ Firmware-Größenvergleich (Regressions)
✅ Parallele Matrix Builds (schnell)
✅ Artifact Storage (30 Tage)
✅ Release Automation
✅ Email Notifications bei Fehler
✅ Build Status Badges

## Struktur

```
.github/workflows/
├── build.yml              (Haupt Build Pipeline)
├── test.yml               (Unit/Integration Tests)
├── analysis.yml           (Code Quality)
├── release.yml            (Release Automation)
└── schedule-nightly.yml   (Nightly Builds)

.github/
├── dependabot.yml         (Auto Dependency Updates)
└── CODEOWNERS             (Auto Review Assignment)
```

## Automatische Prüfungen

Bei jedem Push:
```
✅ Kompiliert auf allen 5 Boards
✅ Firmware-Größe < Limits
✅ Keine Compiler Warnings
✅ Code-Style OK (clang-format)
✅ Static Analysis OK
✅ Tests Passing
✅ Security Scan OK
```

## Build-Matrix Beispiel Output

```
┌─────────────────────────────────────────────┐
│ Build Results                               │
├─────────────────────────────────────────────┤
│ ESP32:    ✅ 650KB  (main, 0.8s)            │
│ ESP32-S2: ✅ 580KB  (single-core, 0.7s)    │
│ ESP32-S3: ✅ 680KB  (dual-core, 0.8s)      │
│ ESP32-C3: ✅ 600KB  (RISC-V, 0.7s)         │
│ ESP32-C6: ✅ 620KB  (RISC-V, 0.8s)         │
├─────────────────────────────────────────────┤
│ Total Time: ~3.5s  |  Status: ✅ PASSED    │
└─────────────────────────────────────────────┘
```

## Badge für README

```markdown
[![Build Status](github.com/username/repo/actions/workflows/build.yml/badge.svg)](github.com/username/repo/actions)
[![Tests](github.com/username/repo/actions/workflows/test.yml/badge.svg)](github.com/username/repo/actions)
[![Code Analysis](github.com/username/repo/actions/workflows/analysis.yml/badge.svg)](github.com/username/repo/actions)
```

## Abhängigkeiten

- GitHub Actions (kostenlos)
- IDF Docker Container
- Python 3.9+
- CMake 3.16+

## Konfiguration

```yaml
# .github/workflows/build.yml
env:
  IDF_VERSION: v5.0
  TARGET_BOARDS: "esp32 esp32s2 esp32s3 esp32c3 esp32c6"
  FIRMWARE_SIZE_LIMIT_KB: 800  # Warning Limit
  WARNINGS_AS_ERRORS: true
```

## Kostenlos auf GitHub

| Feature | GitHub Free | GitHub Pro |
|---------|------------|-----------|
| Actions Min/Month | 2000 | ∞ |
| Storage | 500MB | ∞ |
| Concurrent Jobs | 20 | ∞ |
| Cost | $0 | $4-21/mo |

## Weitere Ressourcen

- [GitHub Actions Docs](https://docs.github.com/en/actions)
- [ESP-IDF CI/CD Guide](https://docs.espressif.com/projects/esp-idf/en/latest/esp32/api-guides/tools/idf-docker-image.html)
- ci_guide.md → Best Practices
- workflow_templates/ → Vorgefertigte Workflows
