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

:: To compile the sketch and generate the binaries in this folder:
echo on
arduino-cli compile --fqbn esp32:esp32:esp32s3usbotg --libraries ..\..\lib\ --export-binaries Factory.ino
@echo off

pause