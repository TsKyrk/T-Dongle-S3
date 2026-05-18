# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Firmware, examples, and board definitions for the **LilyGo T-Dongle-S3** family — compact ESP32-S3 development boards in three variants:

| Variant | Display | Features |
|---|---|---|
| **T-Dongle-S3** | ST7735 TFT 160×80 (SPI) | SD card, APA102 LED, Qwiic I2C |
| **T-Dongle-S3-Dual** | None | Wireless/sensor-focused |
| **T-Dongle-S3-Plus** | ST7735 TFT 160×80 (SPI) | Adds IR transmitter |

Hardware: ESP32-S3 @ 240 MHz, 16 MB SPI flash (W25Q128JVPIQ), no PSRAM, native USB 2.0.

## Build System

**PlatformIO** with Arduino framework. There is no CMake or Makefile.

```bash
pio run -t build          # Build current src_dir
pio run -t upload         # Flash to connected device
pio run -e T-Dongle-S3-Dual -t build   # Build a specific variant
pio run -t clean
```

There is no test suite — examples are manually tested on hardware via Serial monitor at 115200 baud.

### Switching the active project

`platformio.ini` has two settings to change when switching what to build:

```ini
default_envs = T-Dongle-S3          ; or T-Dongle-S3-Dual / T-Dongle-S3-Plus
src_dir = myproject/wifi_display    ; point to any example or project dir
```

### WiFi credentials

WiFi SSID/password are injected via environment variables at build time (not hardcoded):

```ini
build_flags =
    -D WIFI_SSID=\"${sysenv.WIFI_SSID}\"
    -D WIFI_PASSWORD=\"${sysenv.WIFI_PASSWORD}\"
```

Set `WIFI_SSID` and `WIFI_PASSWORD` in your shell (or `.env`) before building projects that use WiFi.

### Version-sensitive examples

- **Microphone** and **USB HID** examples require ESP32 Arduino core 3.3.0+ and must be built via Arduino IDE — PlatformIO does not support them at the pinned version.
- USB HID also requires setting **Tools → USB Mode → USB-OTG (TinyUSB)** in Arduino IDE before compiling.

### Flashing factory firmware directly

```bash
esptool.exe --chip esp32s3 --baud 921600 --before default_reset --after hard_reset \
  write_flash -z --flash_mode dio --flash_freq 80m --flash_size 16MB 0x0 firmware/<file>.bin
```

## Architecture

### One `src_dir` at a time

PlatformIO compiles exactly one directory as the sketch source. Each `examples/<name>/` folder is self-contained (its own `.ino` + any helper headers like `esp_lcd_st7735.h`). Switching examples means changing `src_dir` in `platformio.ini`.

### Board definitions

Custom board JSON files live in `boards/` and are referenced by `platformio.ini` (`board = dongles3`). Each JSON sets a variant-specific macro (`ARDUINO_DONGLES3`, `ARDUINO_DONGLES3_DUAL`, `ARDUINO_DONGLES3_PLUS`) — use these for conditional compilation across variants.

### Key pin mappings (T-Dongle-S3 base)

```
LCD SPI:   MOSI=3, CLK=5, CS=4, DC=2, RST=1, BCKL=38
SD_MMC:    D0=14, D1=17, D2=21, D3=18, CLK=12, CMD=16
APA102 LED: DI=40, CI=39
BOOT:      GPIO 0
```

### Display stack

The LCD uses the **esp-lcd HAL** (`esp_lcd_panel_io_spi`, `esp_lcd_new_panel_st7735`), not TFT_eSPI directly. LVGL v9.x sits on top and requires:
- A flush callback wiring LVGL draw buffers to `esp_lcd_panel_draw_bitmap`
- A timer-based tick (`lv_tick_inc`) and periodic task (`lv_task_handler`)
- Custom fonts declared with `LV_FONT_DECLARE()` before use (e.g., `lv_font_maplemomo_14`)

### LED

APA102 is SPI-based (not NeoPixel/WS2812). FastLED setup:
```cpp
FastLED.addLeds<APA102, LED_DI_PIN, LED_CI_PIN, BGR>(leds, 1);
```
Color order is **BGR** (not RGB).

### Active project: `examples/wifi_display`

Currently set as `src_dir`. It implements:
- UDP broadcast discovery: device listens on port 4210, responds `"TDONGLE@<IP>"` to `"DISCOVER_TDONGLE"`
- HTTP server accepts `/msg=<url-encoded-text>` and renders it on the LCD
- `Preferences` library persists last message across reboots
- `scan_network.py` — Python helper to find device IP on the local network
- `fake_display.py` — GUI mockup simulating the 5×13 character display for offline testing

## Key Constraints

- **No PSRAM**: Memory is tight. Large LVGL framebuffers or image assets need careful allocation.
- **LCD pin coupling**: The ST7735 driver (`esp_lcd_st7735.h`) tightly couples SPI bus config; changing pins requires updating both `#define` constants and the panel config struct.
- **USB mode affects many examples**: `ARDUINO_USB_MODE=1` (CDC) is set in the base env build flags. USB HID examples need it off and TinyUSB enabled instead.
- **Temporary sketches**: Name them `temp_*.ino` — do not commit temporary test code under other names.

## Reference Files

- [platformio.ini](platformio.ini) — active environment and src_dir
- [examples/factory_screen/factory_screen.ino](examples/factory_screen/factory_screen.ino) — canonical hardware init pattern
- [boards/dongles3.json](boards/dongles3.json) — board definition reference
- [Reverse_Engineering.md](Reverse_Engineering.md) — flash memory layout, firmware binary format, esptool details
