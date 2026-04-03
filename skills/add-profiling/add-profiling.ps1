#!/usr/bin/env powershell
# /add-profiling - Performance Profiling Tools Integration

param(
    [switch]$EnableHeapTrack = $true,
    [switch]$EnableStackCheck = $true,
    [switch]$EnablePerfTimer = $true,
    [switch]$EnablePowerEst = $true
)

$ErrorActionPreference = "Stop"

function Test-ProjectValid {
    if (-not (Test-Path "CMakeLists.txt")) {
        throw "Not a valid ESP project (missing CMakeLists.txt)"
    }
}

function Create-ProfilerHeaders {
    Write-Host "Creating profiler header files..." -ForegroundColor Cyan
    
    if (-not (Test-Path "include")) {
        New-Item -Path "include" -ItemType Directory | Out-Null
    }
    
    # Heap Profiler
    $heapProfiler = @"
#ifndef HEAP_PROFILER_H
#define HEAP_PROFILER_H

#include <stdint.h>
#include <esp_heap_caps.h>

typedef struct {
    uint32_t total_heap;
    uint32_t free_heap;
    uint32_t allocated;
    uint32_t max_alloc_block;
    uint8_t fragmentation;
} heap_stats_t;

void heap_profiler_init(void);
heap_stats_t heap_profiler_get_stats(void);
void heap_profiler_dump_stats(void);
void heap_profiler_log_allocation(const char *tag, size_t size);

#endif
"@
    Set-Content "include/heap_profiler.h" $heapProfiler -Encoding ASCII
    Write-Host "  ✓ Created include/heap_profiler.h" -ForegroundColor Green
    
    # Stack Monitor
    $stackMonitor = @"
#ifndef STACK_MONITOR_H
#define STACK_MONITOR_H

#include <freertos/FreeRTOS.h>
#include <freertos/task.h>

#define STACK_WARN_THRESHOLD 512  // bytes

void stack_monitor_init(void);
uint32_t stack_get_free(void);
uint32_t stack_get_high_water_mark(void);
bool stack_monitor_check(void);

#endif
"@
    Set-Content "include/stack_monitor.h" $stackMonitor -Encoding ASCII
    Write-Host "  ✓ Created include/stack_monitor.h" -ForegroundColor Green
    
    # Performance Timer
    $perfTimer = @"
#ifndef PERF_TIMER_H
#define PERF_TIMER_H

#include <stdint.h>
#include <esp_timer.h>

#define PERF_TIMER_START(name) \
    int64_t perf_timer_start_##name = esp_timer_get_time()

#define PERF_TIMER_STOP(name) \
    do { \
        int64_t elapsed = esp_timer_get_time() - perf_timer_start_##name; \
        ESP_LOGI("PERF", #name " took %.2f ms", elapsed / 1000.0); \
    } while(0)

void perf_timer_init(void);

#endif
"@
    Set-Content "include/perf_timer.h" $perfTimer -Encoding ASCII
    Write-Host "  ✓ Created include/perf_timer.h" -ForegroundColor Green
}

function Create-ProfilerComponents {
    Write-Host "Creating profiler implementation files..." -ForegroundColor Cyan
    
    if (-not (Test-Path "src")) {
        New-Item -Path "src" -ItemType Directory | Out-Null
    }
    
    # Heap Profiler Implementation
    $heapImpl = @"
#include "heap_profiler.h"
#include "esp_log.h"

static const char *TAG = "HEAP_PROFILER";

void heap_profiler_init(void) {
    ESP_LOGI(TAG, "Heap profiler initialized");
}

heap_stats_t heap_profiler_get_stats(void) {
    heap_stats_t stats;
    
    stats.total_heap = heap_caps_get_total_size(MALLOC_CAP_DEFAULT);
    stats.free_heap = heap_caps_get_free_size(MALLOC_CAP_DEFAULT);
    stats.allocated = stats.total_heap - stats.free_heap;
    stats.max_alloc_block = heap_caps_get_largest_free_block(MALLOC_CAP_DEFAULT);
    
    if (stats.total_heap > 0) {
        stats.fragmentation = (100 * (stats.max_alloc_block - (stats.free_heap / 4))) / stats.total_heap;
    }
    
    return stats;
}

void heap_profiler_dump_stats(void) {
    heap_stats_t stats = heap_profiler_get_stats();
    
    ESP_LOGI(TAG, "Heap Statistics:");
    ESP_LOGI(TAG, "  Total: %lu bytes", stats.total_heap);
    ESP_LOGI(TAG, "  Used:  %lu bytes (%.1f%%)", stats.allocated, 
             (100.0 * stats.allocated) / stats.total_heap);
    ESP_LOGI(TAG, "  Free:  %lu bytes", stats.free_heap);
    ESP_LOGI(TAG, "  Largest Block: %lu bytes", stats.max_alloc_block);
    ESP_LOGI(TAG, "  Fragmentation: %u%%", stats.fragmentation);
}

void heap_profiler_log_allocation(const char *tag, size_t size) {
    ESP_LOGI(TAG, "%s allocated %u bytes", tag, size);
}
"@
    Set-Content "src/heap_profiler.c" $heapImpl -Encoding ASCII
    Write-Host "  ✓ Created src/heap_profiler.c" -ForegroundColor Green
    
    # Stack Monitor Implementation
    $stackImpl = @"
#include "stack_monitor.h"
#include "esp_log.h"

static const char *TAG = "STACK_MON";
static TaskHandle_t current_task;

void stack_monitor_init(void) {
    current_task = xTaskGetCurrentTaskHandle();
    ESP_LOGI(TAG, "Stack monitor initialized");
}

uint32_t stack_get_free(void) {
    return uxTaskGetStackHighWaterMark(current_task) * sizeof(StackType_t);
}

uint32_t stack_get_high_water_mark(void) {
    return uxTaskGetStackHighWaterMark(NULL) * sizeof(StackType_t);
}

bool stack_monitor_check(void) {
    uint32_t free = stack_get_free();
    
    if (free < STACK_WARN_THRESHOLD) {
        ESP_LOGW(TAG, "Low stack: %lu bytes", free);
        return false;
    }
    
    return true;
}
"@
    Set-Content "src/stack_monitor.c" $stackImpl -Encoding ASCII
    Write-Host "  ✓ Created src/stack_monitor.c" -ForegroundColor Green
}

function Create-ProfilerScripts {
    Write-Host "Creating profiler utility scripts..." -ForegroundColor Cyan
    
    $monitorPy = @"
#!/usr/bin/env python3
"""
Real-time Heap Monitor for ESP32
Reads profiling data via UART serial connection
"""

import serial
import sys
import argparse
from datetime import datetime

class HeapMonitor:
    def __init__(self, port, baudrate=115200):
        self.ser = serial.Serial(port, baudrate, timeout=1)
        
    def read_stats(self):
        """Parse heap statistics from UART"""
        try:
            line = self.ser.readline().decode('utf-8', errors='ignore').strip()
            if 'HEAP' in line:
                print(f"[{datetime.now().strftime('%H:%M:%S')}] {line}")
        except Exception as e:
            print(f"Error: {e}")
    
    def run(self):
        """Run continuous monitoring"""
        print("Heap Monitor started. Press Ctrl+C to exit.")
        try:
            while True:
                self.read_stats()
        except KeyboardInterrupt:
            print("\nMonitor stopped")
        finally:
            self.ser.close()

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Heap Monitor for ESP32')
    parser.add_argument('port', help='Serial port (e.g., /dev/ttyUSB0)')
    parser.add_argument('--baud', type=int, default=115200, help='Baud rate')
    
    args = parser.parse_args()
    
    monitor = HeapMonitor(args.port, args.baud)
    monitor.run()
"@
    
    Set-Content "tools/heap_monitor.py" $monitorPy -Encoding ASCII
    Write-Host "  ✓ Created tools/heap_monitor.py" -ForegroundColor Green
}

function Create-ProfilerGuide {
    Write-Host "Creating profiler documentation..." -ForegroundColor Cyan
    
    $guide = @"
# Performance Profiling Guide

## Heap Profiling

\`\`\`c
#include "heap_profiler.h"

void app_main(void) {
    heap_profiler_init();
    
    // Your code...
    
    heap_profiler_dump_stats();
    // Output:
    // - Total: 204800 bytes
    // - Used: 98304 bytes (48.0%)
    // - Free: 106496 bytes
    // - Largest Block: 65536 bytes
}
\`\`\`

## Stack Monitor

\`\`\`c
#include "stack_monitor.h"

void task_example(void *param) {
    stack_monitor_init();
    
    while (1) {
        if (!stack_monitor_check()) {
            ESP_LOGW(TAG, "Stack critical!");
        }
        vTaskDelay(1000 / portTICK_PERIOD_MS);
    }
}
\`\`\`

## Performance Timing

\`\`\`c
#include "perf_timer.h"

void compute_intensive(void) {
    PERF_TIMER_START(compute);
    
    // Your computation...
    for (int i = 0; i < 1000000; i++) {
        // work
    }
    
    PERF_TIMER_STOP(compute);
    // Output: compute took 234.56 ms
}
\`\`\`

## Real-time Monitoring

\`\`\`bash
python3 tools/heap_monitor.py /dev/ttyUSB0
\`\`\`

## Memory Optimization Tips

1. **Use stack for small temporaries** (<512 bytes)
2. **Use heap for large buffers** (>1KB)
3. **Store constants in Flash** (PROGMEM)
4. **Use PSRAM for large allocations** (>64KB)
5. **Monitor fragmentation** (<20% ideal)

## Typical Memory Layout (ESP32)

- Total Internal RAM: 352 KB
- Used by System/WiFi/BLE: 150-200 KB
- Available for App: 50-200 KB
- PSRAM (extra): 2-16 MB (optional)

## Profiling Checklist

- [ ] Heap usage < 80% at peak
- [ ] Stack high water mark > 1 KB
- [ ] No memory leaks on long runs
- [ ] Fragmentation < 15%
- [ ] Performance within budgets
"@
    
    Set-Content "PROFILING_GUIDE.md" $guide -Encoding ASCII
    Write-Host "  ✓ Created PROFILING_GUIDE.md" -ForegroundColor Green
}

# Main Execution
try {
    Write-Host ""
    Write-Host "Performance Profiling Tools Setup" -ForegroundColor Cyan
    Write-Host "==================================" -ForegroundColor Cyan
    Write-Host ""
    
    Test-ProjectValid
    Create-ProfilerHeaders
    Create-ProfilerComponents
    Create-ProfilerScripts
    Create-ProfilerGuide
    
    Write-Host ""
    Write-Host "SUCCESS: Profiling tools added!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Features enabled:" -ForegroundColor Cyan
    Write-Host "  ✓ Heap profiler" -ForegroundColor Green
    Write-Host "  ✓ Stack monitor" -ForegroundColor Green
    Write-Host "  ✓ Performance timers" -ForegroundColor Green
    Write-Host "  ✓ Real-time monitoring" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Cyan
    Write-Host "  1. Include headers in src/main.c:" -ForegroundColor Yellow
    Write-Host "     #include \"heap_profiler.h\"" -ForegroundColor Gray
    Write-Host "     #include \"stack_monitor.h\"" -ForegroundColor Gray
    Write-Host "  2. Call heap_profiler_init() in app_main()" -ForegroundColor Yellow
    Write-Host "  3. Add profiler sources to CMakeLists.txt" -ForegroundColor Yellow
    Write-Host "  4. Review PROFILING_GUIDE.md for usage" -ForegroundColor Yellow
    Write-Host ""
}
catch {
    Write-Host "ERROR: $_" -ForegroundColor Red
    exit 1
}
