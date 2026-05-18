@echo off

echo You may change the COM port according to your specific port or define it in an .env file
echo.

:: Load .env file from the user directory
set "env_file=%USERPROFILE%\secrets\t_dongle_wifi_display.env"
for /f "tokens=1,* delims==" %%A in (%env_file%) do set %%A=%%B

if "%COMPORT_TDONGLE%"=="" (
    echo ERROR: COMPORT_TDONGLE environment variable is not set.
    echo "You can define it in the OS or in this script using: set COMPORT_TDONGLE=COM3 (for example) or in %USERPROFILE%\secrets\t_dongle_wifi_display.env"
    exit /b 1
)


:: Display connected boards:
echo ==== Available boards ====
echo on
arduino-cli board list
@echo off
echo.

pause

:: To upload the compiled binary 
echo ==== Uploading the binary ====
echo on
arduino-cli upload -p %COMPORT_TDONGLE% --fqbn esp32:esp32:esp32s3usbotg wifi_display.ino
@echo off

pause