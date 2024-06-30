@echo off

echo Change the COM port according to your specific port
echo.

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
arduino-cli upload -p COM7 --fqbn esp32:esp32:esp32s3usbotg Factory.ino
@echo off

pause