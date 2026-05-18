@echo off

echo Please read the comments in this script the first time.

:: Install arduino-cli according to the instructions here : https://arduino.github.io/arduino-cli/1.0/installation/

:: Instruction to use arduino-cli can be found here : https://arduino.github.io/arduino-cli/1.0/getting-started/

:: To initialize arduino-cli.yaml
:: arduino-cli config init

:: To update core index:
:: arduino-cli core update-index

:: To detect the connected boards:
:: arduino-cli board list

:: To install esp32 core at the older 2.0.14 version (versions above will be failing) :
:: arduino-cli core install esp32:esp32@2.0.14

:: To check tat the core has been installed:
:: arduino-cli core list


:: Load .env file from the user directory
set "env_file=%USERPROFILE%\secrets\t_dongle_wifi_display.env"
for /f "tokens=1,* delims==" %%A in (%env_file%) do set %%A=%%B


::::::::::::::::::::::::::::: WIFI CREDENTIALS :::::::::::::::::::::::::::::
if "%WIFI_SSID%"=="" (
    echo ERROR: WIFI_SSID environment variable is not set.
    echo You can  define it in the OS or in this script using: set WIFI_SSID=your_ssid or in %USERPROFILE%\secrets\t_dongle_wifi_display.env
    exit /b 1
)

if "%WIFI_PASSWORD%"=="" (
    echo ERROR: WIFI_PASSWORD environment variable is not set.
    echo You can define it in the OS or in this script using: set WIFI_PASSWORD=your_password or in %USERPROFILE%\secrets\t_dongle_wifi_display.env
    exit /b 1
)

echo WIFI_SSID and WIFI_PASSWORD environment variables are set.

:: To compile the sketch and generate the binaries in this folder:
echo on
arduino-cli compile ^
  --verbose ^
  --fqbn esp32:esp32:esp32s3usbotg ^
  --libraries ..\..\lib\ ^
  --build-property compiler.cpp.extra_flags="-DWIFI_SSID=\"%WIFI_SSID%\" -DWIFI_PASSWORD=\"%WIFI_PASSWORD%\"" ^
  --export-binaries wifi_display.ino
@echo off

pause