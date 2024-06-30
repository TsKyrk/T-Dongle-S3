# Modifications
2024.05.11 - First analysis (my issue wasn't solved yet)  
2024.06.30 - Additions (after my issues were fixed)

# Context
I was facing issues trying to get the device to work properly when I first bought the T-Dongle-S3. I was able to get it to work by flashing firmware.bin using esptool.exe but not by compliling and uploading Factory.ino using Arduino IDE or PlatformIO.   
I've spent some time reverse engineering the device and all the scripts provided in the repo.  
The purpose of this file is to gather all my findings for a later personal use even though my problems happened to be unrelated with them. I make the file publicly available since I believe this may also help others.  

# The esptool command line
The binary firmware.bin is uploaded on the device using the following command:

`esptool.exe --chip esp32s3   --baud 921600 --before default_reset --after hard_reset write_flash -z --flash_mode dio --flash_freq 80m --flash_size 16MB 0x0 firmware.bin`

# Esptool.exe
Using esptool.exe to flash the device appreared to be more straightforward and reliable than using ARDUINO IDE or PLATFORMIO. The aim of my investigations was to understand why.

The python script esptool.py is provided by Espressif here : https://github.com/espressif/esptool  
It is documented here : https://docs.espressif.com/projects/esptool/en/latest/esp32/esptool/basic-options.html  
The file esptool.exe provided in this folder is an executable version of the Espressif python script.

<p></p>Here is an analysis of the arguments used by the previous command line:

 * The chip to program is an esp32s3 microcontroler which is itself connected to an SPI flash memory
 * The transfer baudrate on the USB link is 921.6kbps = 921,600bps
 * Before programming, the MCU is reset into bootloader mode using DTR & RTS serial control lines
 * After programming, the MCU is reset into normal boot sequence using DTR line
 * The write_flash options are:
   * -z : compressed data
   * flash modes is DIO meaning dual SPI transfer (MISO and MOSI are used together for data transfer)
   * flash frequency is 80Mhz which is the maximum frequency allowed by the tool 
   * flash size is 16MB
   * Start address is 0x00
   * Binary file name is firmware.bin

# Memory chip
## Part number
In the schematic, the referenced flash memory chip is Winbond W25Q32. It is a 3V 32Mbits=16MByte industrial grade SPI flash with 4KB sectors. This memory chip supports dual and quad SPI operations.  
The marking visible on the memory chip is 25Q128JVPQ meaning MPN=W25Q128JVPIQ (128Mb, WSON-8 6x5mm package, -40°C/+85°C). So the memory is now 4 times bigger than on the original board design.   

## Mapping
<p></p>The memory is organized :  

* in an array of 128Mb = 128M x 1 bits = 16M x 8 bits = 16 x 1024 x 1204 x 8 bits = 16MB. 
* in 16M addresses of 8-bit words ranging from 0x000000 to 0xFFFFFF.
* in 8M addresses of 16-bit words ranging from 0x000000 to 0x7FFFFF.
* in 4M addresses of 32-bit words ranging from 0x000000 to 0x3FFFFF.
* in 2M addresses of 64-bit words ranging from  0x00000 to 0xFFFFF.
* in 65536 pages of 256B ranging from 0x00000 to 0xFFFF. Pages can be programmed individually.
* in 4096 sectors of 4KB ranging from 0x000 to 0xFFF. Sectors can be erased individually. 1 sector = 16 pages.
* in 512 groups of 32KB ranging from 0x000 to 0x1FF. Groups can be erased individually. 1 group = 8 sectors = 128 pages.
* in 256 blocks of 64KB ranging grom 0x00 to 0xFF. Blocks can be erased individually. 1 block = 2 groups = 16 sectors = 256 pages.

<p></p>For example:

* the block number 123=0x7B maps Byte-addresses ranging from 0x7B0000 to 0x7BFFFF.  
* the sector number 10 in block 123 maps Byte-addresses ranging from 0x7BA000 to 0x7BAFFF. 
* the page number 3 in sector 10 of block 123 maps Byte-addresses ranging from 0x7BA300 to 0x7BA3FF covering 256 Bytes of data on this page.

The esptool commandline is assuming a 16MByte flash memory starting from address 0x00. This means that the whole address range 0x000000 to 0x07FFFFFF should be overwritten by the write_flash command of the esptool. 

## Frequency
The maximum clock frequency (FR) is 104MHz for Vcc>2.7V except for read operations.  
The maximum clock frequency (fR) is 50MHz, only for read operations.  
Programming the flash memory at 80Mhz is compatible with the datasheet specifications.


# Firmware.bin
The firmware.bin is the factory binary that gets the T-Dongle-S3 device to work properly.  
The ESP32S3 binary structure is described here: https://docs.espressif.com/projects/esptool/en/latest/esp32s3/advanced-topics/firmware-image-format.html
 * The file header has 8 Bytes :
   * Byte 0      : 0xE9 (always)
   * Byte 1      : 0x03 (number of segments is 3)
   * Byte 2      : 0x02 (SPI flash mode is DIO)
   * Byte 3H     : 0x3  (flash size is 8MB)
   * Byte 3L     : 0xF  (flash frequency is 80Mhz)
   * Byte 4-7    : 0xD4 98 3C 40 (Entry point address is 0x403C98D4)  
 * The extended file header has 16 Bytes :
   * Byte 0      : 0xEE (WP pin is 0xEE when SPI pin is set via eFuse = Write Protect ?)
   * Byte 1-3    : 0x000000 (Drive settings for the SPI flash pins is set to 0)
   * Byte 4-5    : 0x09 00 (The target chip ID for this binary is 0009)
   * Byte 6      : 0x00 (deprecated field)
   * Byte 7-8    : 0x00 00 (Minimum chip revision for this binary is .0)
   * Byte 9-10   : 0xFF FF (Maximum chip revision for this binary is 655.35)
   * Byte 11-14  : 0x00 00 00 00 (reserved bytes)
   * Byte 15     : 0x01 (Hash code is appended after the checksum as SHA256 digest)
 * New segment :
   * Byte 0-3    : 0x08 38 CE 3F (Memory offset is 0x3FCE3808)
   * Byte 4-7    : 0x4C 04 00 00 (Segment size is 0x044C=1100 Bytes)
   * Byte 8-1107 : 0xFF FF FF FF 1B ...

More details on this factory binary can be obtained using the Espressif image_info tool:
   
<pre>
C:\esptool>py esptool.py image_info --version 2 "D:\...\firmware\firmware.bin"
esptool.py v4.7.0
File size: 4128768 (bytes)
Detected image type: ESP32-S3

ESP32-S3 image header
=====================
Image version: 1
Entry point: 0x403c98d4
Segments: 3
Flash size: 8MB
Flash freq: 80m
Flash mode: DIO

ESP32-S3 extended image header
==============================
WP pin: 0xee (disabled)
Flash pins drive settings: clk_drv: 0x0, q_drv: 0x0, d_drv: 0x0, cs0_drv: 0x0, hd_drv: 0x0,wp_drv: 0x0
Chip ID: 9 (ESP32-S3)
Minimal chip revision: v0.0, (legacy min_rev = 0)
Maximal chip revision: v655.35

Segments information
====================
Segment   Length   Load addr   File offs  Memory types
-------  -------  ----------  ----------  ------------
      0  0x0044c  0x3fce3808  0x00000018  BYTE_ACCESSIBLE, MEM_INTERNAL, DRAM
      1  0x00be4  0x403c9700  0x0000046c  MEM_INTERNAL, IRAM
      2  0x02a68  0x403cc700  0x00001058  MEM_INTERNAL, IRAM

ESP32-S3 image footer
=====================
Checksum: 0xc8 (valid)
Validation hash: 3f6c8f5984f141d8075c85bb4d14f5d9211389c3e2f5992b3ae03ff85649cdf8 (valid)
</pre>

The image header shows that this image is is intended for 80MHz programmation and dual SPI transfer mode which matches the command line.  
However it is declared with a size of 8MB instead of 16MB.

# ESP32S3 Memory mapping

The ESP32S3 memory mapping is provided here : https://dl.espressif.com/public/esp32s3-mm.pdf  
<p></p>It shows various memory spaces:

* ROM0 (256kB): ranges from 0x4000.0000 to 0x4003.FFFF (on I-BUS)
* ROM1 (128kB): ranges from 0x3FF0.0000 to 0x3FF1.FFFF (on D-BUS)
* SRAM0 (32kB): ranges from 0x4037.0000 to 0x4037.7FFF (on I-BUS, cache for external memory)
* SRAM1 (416kB): ranges 
  * from 0x4037.8000 to 0x403D.FFFF (on I-BUS) 
  * from 0x3FC8.8000 to 0x3FCE.FFFF (on D-BUS, for DMA access)
* SRAM2 (64kB): ranges from 0x3FCF.0000 to 0x3FCF.FFFF (on D-BUS, Dcache for external memory)
* RTCSLOW (8kB): ranges 
  * from 0x5000.0000 to 0x5000.1FFF (on I-BUS)
  * from 0x5000.0000 to 0x5000.1FFF (on D-BUS)
* RTCFAST (8kB): ranges
  * from 0x600F.E000 to 0x600F.FFFF (on I-BUS)
  * from 0x600F.E000 to 0x600F.FFFF (on D-BUS)
* D-CACHE/I-CACHE (32MB): ranges
  * from 0x4200.0000 to 0x43FF.FFFF (on I-BUS, external flash)
  * from 0x3C00.0000 to 0x3DFF.FFFF (on D-BUS, external flash)
* PERIPHERALS: ranges from 0x6000.0000 to 0x600D.0FFF (on D-BUS)
  * UART0 is at 0x6000.0000
  * SPI1 is at 0x6000.2000
  * SPI0 is at 0x6000.3000
  * EFUSE is at 0x6000.7000
  * Etc.

Reagarging Firmware.bin...  
Segment 0 is at 0x3fce.3808 meaning SRAM1 on D-BUS for DRAM accesses.  
Segment 1 is at 0x403c.9700 meaning SRAM1 on I-BUS.  
Segment 2 is at 0x403c.c700 meaning SRAM1 on I-BUS.  