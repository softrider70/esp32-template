# Build & Upload Guide for ${PROJECT_NAME}

This guide covers manual building and uploading procedures using ESP-IDF command-line tools.

## Table of Contents
1. [Prerequisites](#prerequisites)
2. [Building](#building)
3. [Uploading Firmware](#uploading-firmware)
4. [Debugging & Monitoring](#debugging--monitoring)
5. [Troubleshooting](#troubleshooting)

---

## Prerequisites

### Install ESP-IDF
```bash
git clone --recursive https://github.com/espressif/esp-idf.git
cd esp-idf
./install.bat  # Windows
# or
./install.sh   # Linux/macOS
```

### Activate ESP-IDF Environment
```bash
# Windows
C:\path\to\esp-idf\export.bat

# Linux/macOS
source ~/esp-idf/export.sh
```

### Identify Your Board
- **ESP32** (dual-core)
- **ESP32-S2** (single-core)
- **ESP32-S3** (dual-core, USB)
- **ESP32-C3** (single-core, RISC-V)
- **ESP32-C6** (dual-core, RISC-V, Thread)

---

## Building

### Set Target Board
```bash
idf.py set-target esp32      # Default: ESP32
idf.py set-target esp32s3    # For ESP32-S3
idf.py set-target esp32c3    # For ESP32-C3
```

### Configure Project (Optional)
Opens menuconfig interface for advanced settings:
```bash
idf.py menuconfig
```

### Build Project
```bash
# Standard build
idf.py build

# Specify board defaults
idf.py build -DSDKCONFIG_DEFAULTS="sdkconfig.defaults.esp32s3"

# Clean and rebuild
idf.py fullclean
idf.py build
```

### Build Output
```
build/
├── bootloader/
│   └── bootloader.bin          (0x0, second-stage bootloader)
├── partition_table/
│   └── partition-table.bin     (0x8000, partition layout)
├── esp32-template.bin          (0x10000, application firmware)
└── esp32-template.elf          (debugging symbols)
```

---

## Uploading Firmware

### Identify Serial Port
```bash
# Windows (PowerShell)
Get-WmiObject Win32_SerialPort | Select-Object Name, Description

# Linux
ls /dev/ttyUSB*

# macOS
ls /dev/cu.usbserial*
```

### First-Time Upload (Full Flash)
Required on first device setup to write bootloader and partition table:

```bash
idf.py -p COM3 flash
# or explicitly
esptool.py -p COM3 --baud 921600 \
    write_flash 0x0 build/bootloader/bootloader.bin \
                0x8000 build/partition_table/partition-table.bin \
                0x10000 build/esp32-template.bin
```

**Duration**: ~20 seconds

### Subsequent Uploads (App-Only)
Much faster for iterative development:

```bash
idf.py -p COM3 upload
# or
esptool.py -p COM3 --baud 921600 \
    write_flash 0x10000 build/esp32-template.bin
```

**Duration**: ~3 seconds

### Custom Baud Rates
```bash
# Ultra-fast (high-quality USB cables)
idf.py -p COM3 -b 1152000 flash

# Slower (for long/noisy cables)
idf.py -p COM3 -b 115200 flash
```

### Erase Flash
```bash
# Erase entire flash memory
esptool.py -p COM3 erase_flash

# Erase specific partition
esptool.py -p COM3 erase_region 0x10000 0x2F0000
```

---

## Debugging & Monitoring

### Monitor Serial Output
```bash
idf.py -p COM3 monitor

# With automatic board reset on disconnect
idf.py -p COM3 monitor -b 115200
```

### Monitor Options
```
Ctrl+] — Exit monitor
Ctrl+T, Ctrl+A — Reset board
Ctrl+T, Ctrl+R — Reset to ROM bootloader
```

### Build + Flash + Monitor (One Command)
```bash
idf.py -p COM3 build flash monitor
```

### GDB Debugging
1. Start OpenOCD server:
   ```bash
   openocd -f board/esp32-wrover-kit-3.3.cfg
   ```

2. In another terminal, start GDB:
   ```bash
   xtensa-esp32-elf-gdb build/esp32-template.elf
   (gdb) target remote:3333
   (gdb) continue
   ```

---

## Troubleshooting

### Serial Port Issues

**Problem**: Device not detected
```bash
# Check connected devices
esptool.py version

# Try automatic port detection
idf.py build flash monitor
```

**Solution**: 
- Install CH340 or CP2102 drivers (common for ESP32 boards)
- Try different USB cable or port
- Reset board manually during upload

### Upload Errors

**Error**: `No module named 'esptool'`
```bash
pip install esptool
```

**Error**: `Failed to connect to ESP32`
- Hold **BOOT** button while plugging in USB
- Or hold **BOOT** and press **RESET** during upload
- Some boards auto-reset; others need manual reset

### Baud Rate Issues

**Problem**: Garbled serial output
```bash
# Monitor at different baud rates
idf.py -p COM3 monitor -b 115200  # Default
idf.py -p COM3 monitor -b 9600    # Slower
```

**Solution**: 
- Check `CONFIG_ESP_CONSOLE_UART_BAUDRATE` in `sdkconfig`
- Ensure cable is short and high-quality
- Try lower baud rate (slower but more reliable)

### Flash Size Issues

**Problem**: `Not enough space for app`
```bash
# Check partition table
esptool.py -p COM3 read_flash_status

# View partition layout
idf.py partition-table
```

**Solution**:
- Reduce application size (optimize code)
- Increase app partition in `partitions.csv`
- Use compression for resources

### Board Specific Issues

#### ESP32-S2/S3 USB Issues
```bash
# If using USB instead of UART for upload
idf.py -p /dev/ttyACM0 -b 921600 flash
```

#### ESP32-C3/C6 Download Mode
- Some boards require holding specific buttons
- Check board-specific documentation for boot procedure

---

## Advanced Features

### Partition Management
```bash
# Add custom partitions to partitions.csv
idf.py partition-table

# Generate OTA partition (optional)
# See SECURITY.md for OTA firmware updates
```

### Firmware Signing
```bash
# Sign firmware with Secure Boot keys
idf.py secure-pad-and-sign-keyblock -k secure_boot_signing_key.pem
```

### Analyze Binary Size
```bash
idf.py size
idf.py size-components
idf.py size-files
```

---

## Copilot Skills

Instead of manual commands, use automation:

```
/build-project          — Compile and generate binary
/upload                 — Smart router (asks first time vs. repeated)
/upload-firmware        — Fast app-only upload (~3 sec)
/initial-upload         — Full bootloader + partition + app (~20 sec)
/monitor                — Watch serial output
```

---

## Support & Resources
- [ESP-IDF Programming Guide](https://docs.espressif.com/projects/esp-idf/en/latest/esp32/)
- [esptool.py Documentation](https://github.com/espressif/esptool)
- [OpenOCD Debugging](https://docs.espressif.com/projects/esp-idf/en/latest/esp32/api-guides/tools/openocd.html)

---

**Last Updated**: 2026-04-03  
**Template Version**: 0.1.0
