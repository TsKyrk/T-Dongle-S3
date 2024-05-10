:start
esptool.exe --chip esp32s3   --baud 921600 --before default_reset --after hard_reset write_flash -z --flash_mode dio --flash_freq 80m --flash_size 16MB 0x0 firmware.bin

::::::::::::: Date of this analysis : 2024.05.11 :::::::::::::::::
::
:: This way of flashing the device seems to be more reliable than using ARDUINO IDE or PLATFORMIO.
:: esptool.py is provided by Espressif here : https://github.com/espressif/esptool
:: The tool is documented here : https://docs.espressif.com/projects/esptool/en/latest/esp32/esptool/basic-options.html
:: esptool.exe is certainly an executable version of the python script. Here are the arguments used by the previous command line:
::  * chip is esp32s3
::  * baudrate is 921.6kbps
::  * before programming, resets into bootloader mode using DTR & RTS serial control lines
::  * after programming, resets into normal boot sequence using DTR line
::  * write_flash options are:
::    * -z : compressed data
::    * flash modes is DIO meaning dual SPI (MISO and MOSI are used together for data transfer)
::    * flash frequency is 80Mhz which is the maximum frequency possible 
::    * flash size is 16MB
::    * Start address is 0x00
::    * Binary file name is firmware.bin

:: firmware.bin is the factory binary that gets the T-Dongle-S3 device to work properly
:: The ESP32S3 binary structure is described here: https://docs.espressif.com/projects/esptool/en/latest/esp32s3/advanced-topics/firmware-image-format.html
::  * The file header has 8 Bytes
::    * Byte 0      : 0xE9 (always)
::    * Byte 1      : 0x03 (number of segments is 3)
::    * Byte 2      : 0x02 (SPI flash mode is DIO)
::    * Byte 3H     : 0x3  (flash size is 8MB)
::    * Byte 3L     : 0xF  (flash frequency is 80Mhz)
::    * Byte 4-7    : 0xD4 98 3C 40 (Entry point address is 0x403C98D4)  
::  * The extended file header has 16 Bytes
::    * Byte 0      : 0xEE (WP pin is 0xEE when SPI pin is set via eFuse = Write Protect ?)
::    * Byte 1-3    : 0x000000 (Drive settings for the SPI flash pins is set to 0)
::    * Byte 4-5    : 0x09 00 (The target chip ID for this binary is 0009)
::    * Byte 6      : 0x00 (deprecated field)
::    * Byte 7-8    : 0x00 00 (Minimum chip revision for this binary is .0)
::    * Byte 9-10   : 0xFF FF (Maximum chip revision for this binary is 655.35)
::    * Byte 11-14  : 0x00 00 00 00 (reserved bytes)
::    * Byte 15     : 0x01 (Hash code is appended after the checksum as SHA256 digest)
::  * New segment
::    * Byte 0-3    : 0x08 38 CE 3F (Memory offset is 0x3FCE3808)
::    * Byte 4-7    : 0x4C 04 00 00 (Segment size is 0x044C=1100 Bytes)
::    * Byte 8-1107 : 0xFF FF FF FF 1B ...
::
:: It appears that more details can be get using the image_info tool :
::    C:\esptool>py esptool.py image_info --version 2 "D:\...\firmware\firmware.bin"
::    esptool.py v4.7.0
::    File size: 4128768 (bytes)
::    Detected image type: ESP32-S3
::    
::    ESP32-S3 image header
::    =====================
::    Image version: 1
::    Entry point: 0x403c98d4
::    Segments: 3
::    Flash size: 8MB
::    Flash freq: 80m
::    Flash mode: DIO
::    
::    ESP32-S3 extended image header
::    ==============================
::    WP pin: 0xee (disabled)
::    Flash pins drive settings: clk_drv: 0x0, q_drv: 0x0, d_drv: 0x0, cs0_drv: 0x0, hd_drv: 0x0, wp_drv: 0x0
::    Chip ID: 9 (ESP32-S3)
::    Minimal chip revision: v0.0, (legacy min_rev = 0)
::    Maximal chip revision: v655.35
::    
::    Segments information
::    ====================
::    Segment   Length   Load addr   File offs  Memory types
::    -------  -------  ----------  ----------  ------------
::          0  0x0044c  0x3fce3808  0x00000018  BYTE_ACCESSIBLE, MEM_INTERNAL, DRAM
::          1  0x00be4  0x403c9700  0x0000046c  MEM_INTERNAL, IRAM
::          2  0x02a68  0x403cc700  0x00001058  MEM_INTERNAL, IRAM
::    
::    ESP32-S3 image footer
::    =====================
::    Checksum: 0xc8 (valid)
::    Validation hash: 3f6c8f5984f141d8075c85bb4d14f5d9211389c3e2f5992b3ae03ff85649cdf8 (valid)


@echo Press any key, find device program
pause
goto start

