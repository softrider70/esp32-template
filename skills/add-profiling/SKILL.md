# /add-profiling - Performance Profiling Tools

## Beschreibung

Integriert Profiling und Performance-Analyse Tools für Memory-Optimierung, Timing-Analyse und Bottleneck-Erkennung. Ideal für Memory-limitierte IoT-Geräte.

## Funktionalität

Fügt hinzu:
- Heap Memory Tracker/Analyzer
- Stack Overflow Detection
- Performance Timer Makros
- CPU Load Monitoring
- Power Consumption Estimation
- Heap Fragmentation Analysis
- Call Stack Unwinding

## Installation

```bash
/add-profiling
```

## Tools & Features

### 1. Heap Memory Profiling
```c
#include "heap_profiler.h"

void app_main(void) {
    heap_profiler_init();
    
    // Malloc/Free werden automatisch tracked
    
    heap_profiler_dump_stats();
    // Output: Total: 45KB, Used: 32KB, Free: 13KB, Frag: 8%
}
```

### 2. Stack Monitoring
```c
#include "stack_monitor.h"

void task(void *param) {
    stack_monitor_init();
    
    while (1) {
        if (stack_monitor_check() < STACK_WARN_THRESHOLD) {
            ESP_LOGW(TAG, "Stack low: %d bytes", stack_remaining());
        }
        vTaskDelay(1000 / portTICK_PERIOD_MS);
    }
}
```

### 3. Performance Timing
```c
#include "perf_timer.h"

void sensor_read(void) {
    PERF_TIMER_START(sensor_read);
    
    // ... sensor logic ...
    
    PERF_TIMER_STOP(sensor_read);
    // Output: sensor_read took 23.4ms
}
```

### 4. Real-time Monitoring
```bash
# UART-basiertes Live-Monitoring
python3 heap_monitor.py /dev/ttyUSB0

# Output:
# ┌──────────────────────────────────┐
# │ Heap: 32/204KB (15.7%)           │
# │ Stack: 15/16KB (93.8%) ⚠️        │
# │ CPU: 42.3%  WiFi: 8.5%           │
# │ Largest Free: 64KB  Frag: 8%     │
# └──────────────────────────────────┘
```

## Architektur

```
profiling/
├── heap_profiler.c
│   └── malloc/free Wrapper
├── stack_monitor.c
│   └── Task Stack Tracking
├── perf_timer.c
│   └── Timing Makros
├── power_estimator.c
│   └── Energy Calculation
└── monitor/
    ├── heap_monitor.py (Python Client)
    └── live_dashboard.html
```

## Performance Metriken

```c
// Automatisch erfasst:
- Total Heap Size
- Used/Free Memory
- Peak Memory Usage
- Allocation Count
- Free Count
- Fragmentation %
- Stack High Water Mark
- Task Memory Usage
- Interrupt Latency
- Task Switch Time
```

## CLI-Optionen

```bash
/add-profiling
  --enable-heap-track    Memory Tracking aktivieren
  --enable-stack-check   Stack Overflow Detection
  --enable-perf-timer    Performance Timing
  --enable-power-est     Power Consumption Estimate
  --monitor-uart         UART Live Monitoring
  --generate-report      PDF Report generieren
```

## Typische Memory Verteilung

```
┌────────────────────────────────┐
│ RAM Layout (ESP32, 520KB SRAM) │
├────────────────────────────────┤
│ Internal RAM      │  352KB      │
├────────────────────────────────┤
│ RTC RAM           │  64KB       │
├────────────────────────────────┤
│ PSRAM (optional)  │  4-16MB     │
├────────────────────────────────┤
│ Typical Usage                  │
│ - Firmware Code:  200-300KB    │
│ - Heap (dynamic): 50-150KB     │
│ - Stack (tasks):  10-20KB      │
│ - RTC Memory:     4KB (NVS)    │
└────────────────────────────────┘
```

## Optimization-Beispiel

```c
// VORHER: 45KB Heap Usage
void inefficient(void) {
    char buffer[2048];  // Stack Verschwendung!
    // ... processing ...
}

// NACHHER: 5KB Heap Usage
void optimized(void) {
    // Statischer Buffer (Flash)
    static const char data[] = {...};
    // ... processing ...
}
```

## Profiling Workflow

```bash
# 1. Baseline sammeln
./profile.sh --baseline

# 2. Code ändern
# ... your changes ...

# 3. Vergleich
./profile.sh --compare

# Output:
# Memory Δ: -2.3KB ✅
# Stack Δ:   +0.5KB ⚠️
# Speed Δ:  -12.4% ✅
```

## Power Estimation

```
Basierend auf:
- CPU Frequency
- Task Utilization
- WiFi TX/RX Power
- Peripheral Power Draw

Beispiel Output:
├── Idle:        4.2mA
├── WiFi RX:     45mA
├── WiFi TX:     150mA
├── BLE:         8-20mA
├── Sensor:      2-5mA
└── Total Avg:   ~25mA @ 5V
```

## Best Practices

1. **Memory Konservierung**
   - Stack für temporäre Daten (<1KB)
   - Heap für große Buffers (>1KB)
   - Statische Data im Flash (PROGMEM)
   - PSRAM für >1KB Allocations

2. **Performance**
   - Perf Timer auf kritische Sections
   - Stack Profiling in Prod
   - Monitoring Dashboard nutzen

3. **Production**
   - Memory Limits definieren
   - Alerts bei >80% Utilization
   - Regelmäßige Heap Dumps
   - Memory Leaks Testen

## Weitere Ressourcen

- [ESP-IDF Memory Management](https://docs.espressif.com/projects/esp-idf/en/latest/esp32/api-reference/system/mem_alloc.html)
- memory_guide.md → Memory Optimization Guide
- examples/profiling/ → Demo Sketches
- tuning.md → Performance Tuning Tips
