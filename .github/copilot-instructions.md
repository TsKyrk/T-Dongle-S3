# T-Dongle-S3 AI Agent Instructions

This repository contains firmware, examples, and board definitions for the LilyGo T-Dongle-S3 family of compact ESP32-S3 development boards. Agents should understand this is an embedded systems project targeting three board variants with different capabilities.

## Project Architecture

**Three Board Variants:**
- **T-Dongle-S3**: Base model with SPI-based ST7735 LCD (160×80), SD card, LED support
- **T-Dongle-S3-Dual**: Variant without display, optimized for different use cases
- **T-Dongle-S3-Plus**: Enhanced variant with IR transmitter capabilities

**Key Directories:**
- `examples/`: 15+ Arduino sketches (.ino) for different subsystems (LCD, SD card, USB HID, WiFi, etc.)
- `lib/`: Dependencies including FastLED (LED control) and LVGL9 (GUI framework)
- `boards/`: PlatformIO board definition JSONs for each variant
- `firmware/`: Pre-built factory firmware binaries for flashing
- `docs/`: Hardware-specific documentation and quick-start guides
- `schematic/`: Board layout and electrical schematics

**Primary Build System:** PlatformIO with Arduino framework targeting ESP32-S3

## Critical Build & Deployment Patterns

**Project Configuration (`platformio.ini`):**
- Default environment: `T-Dongle-S3` (change via `default_envs` setting)
- Key pattern: `src_dir` points to one example folder at a time
- Different examples may require different ESP32-IDF versions (see microphone comments)
- Board variants use custom board definitions (e.g., `board = dongles3`)

**Common Development Workflow:**
1. Select example in `platformio.ini`: `src_dir = examples/factory_screen`
2. Build: `pio run -t build` or upload: `pio run -t upload`
3. For factory firmware binary: Use esptool directly with 921600 baud rate
4. Use Arduino IDE for some specialized examples (microphone with IDF 3.3.0+)

**Important Constraints:**
- Many examples define platform-specific macros (e.g., `BOOT_PIN`, `LED_*_PIN`)
- LCD examples tightly couple SPI configuration with ST7735 driver initialization
- Some features require specific ESP32-IDF versions (document these)

## Code Patterns & Conventions

**Hardware Initialization Pattern** (seen in `factory_screen.ino`):
- Pin definitions grouped at top with descriptive constants
- SPI/LCD panel initialization with explicit bus and IO configs
- LVGL integration requires display driver callbacks and memory buffers
- Custom fonts declared with `LV_FONT_DECLARE()` before use

**FastLED Integration:**
- Include: `#include <FastLED.h>`
- Used alongside LVGL for simultaneous display and LED control
- Examples show RGB LED strips on dedicated pins

**SD Card & Filesystem:**
- Examples use Arduino's `SD_MMC` library with SPI mode pins
- Common use: Store UI images, web content, configuration
- Pin mapping defined in hardware config section of each sketch

**LVGL GUI Framework (lvgl9 example):**
- Custom font loading from embedded C files (e.g., `lv_font_maplemomo_14`)
- Display driver initialization through ESP-LCD HAL
- Event-driven UI updates suitable for embedded displays

## Project-Specific Conventions

**Example Organization:**
- Each `examples/*/` folder is self-contained with its own .ino
- Shared headers go in `examples/*/` subfolder (e.g., `esp_lcd_st7735.h`)
- Temporary testing sketches should follow `temp_*.ino` naming pattern
- Do NOT create new examples unless demonstrating significant new functionality

**Documentation Patterns:**
- Board-specific quick-starts in `docs/en/<variant>/`
- Technical reverse-engineering notes in `Reverse_Engineering.md`
- Hardware details in schematics with memory layout explanations

**Dependencies & Compatibility:**
- FastLED included via lib/ with special testing and refactoring tools
- LVGL v9.x for GUI examples
- ESP32 Arduino core 6.12.0 or later (see platformio.ini)
- Some features require specific IDF versions (document in sketch comments)

## Integration Points & External Systems

**SPI Flash Memory (W25Q128JVPIQ):**
- 16MB total (upgraded from 32Mb in original design)
- SD firmware blob stored at address 0x00
- Organized in 4KB sectors, 64KB blocks for wear-leveling

**Hardware Interfaces:**
- USB HID (keyboard, mouse, mass storage) requires ESP32-S3 native USB
- I2C Qwiic connector for external sensor integration
- UART for loopback/debug communication
- SD_MMC SPI interface with dedicated clock and data pins

**Wireless:**
- WiFi examples use standard Arduino WiFi library
- Web server examples access SD card content over HTTP
- Configuration stored in sketch (use defines for SSID/password)

## Common Development Tasks

**Adding a New Example:**
1. Create `examples/<FeatureName>/` directory
2. Add comprehensive .ino file demonstrating real-world usage
3. Document required hardware connections and pin modifications
4. Test on target board variant (note in comments if variant-specific)
5. Update README with link to new example

**Modifying Board Definitions:**
- Edit `.json` files in `boards/` for different board configurations
- Test build with: `pio run -e <variant> -t build`
- Validate pin mappings against schematic

**Firmware Updates:**
- Factory binary placed in `firmware/` directory
- Flash with esptool: `esptool.exe write_flash -z --flash_mode dio --flash_freq 80m --flash_size 16MB 0x0 firmware.bin`
- Set baud to 921600, use default reset before and hard reset after

## Files to Review First

1. [platformio.ini](platformio.ini) — Build configuration and environment setup
2. [examples/factory_screen/factory_screen.ino](examples/factory_screen/factory_screen.ino) — Complete hardware initialization pattern
3. [boards/dongles3.json](boards/dongles3.json) — Board definition reference
4. [Reverse_Engineering.md](Reverse_Engineering.md) — Flash memory and firmware structure details
