@echo off
:: Ensure the script runs with admin privileges
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Requesting administrative privileges...
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

:: Prompt for connection type
echo Select the connection type:
echo [1] Wi-Fi (List IP only)
echo [2] LAN (Ethernet - Make Static)
set /p CONN_TYPE="Enter your choice (1 or 2): "

if "%CONN_TYPE%"=="1" (
    goto LIST_WIFI
) else if "%CONN_TYPE%"=="2" (
    goto CONFIG_LAN
) else (
    echo Invalid choice. Exiting...
    pause
    exit /b
)

:LIST_WIFI
:: Retrieve Wi-Fi details
echo Retrieving Wi-Fi details...

set WIFI_IP=
set WIFI_MASK=
set WIFI_GATEWAY=

:: Parse Wi-Fi IP Address
for /f "tokens=2 delims=:" %%A in ('ipconfig ^| findstr /c:"Wireless LAN adapter Wi-Fi" /c:"IPv4 Address"') do (
    for /f "tokens=*" %%B in ("%%A") do set WIFI_IP=%%B
)

:: Parse Wi-Fi Subnet Mask
for /f "tokens=2 delims=:" %%A in ('ipconfig ^| findstr /c:"Wireless LAN adapter Wi-Fi" /c:"Subnet Mask"') do (
    for /f "tokens=*" %%B in ("%%A") do set WIFI_MASK=%%B
)

:: Parse Wi-Fi Default Gateway
for /f "tokens=2 delims=:" %%A in ('ipconfig ^| findstr /c:"Wireless LAN adapter Wi-Fi" /c:"Default Gateway"') do (
    for /f "tokens=*" %%B in ("%%A") do set WIFI_GATEWAY=%%B
)

:: Trim leading/trailing whitespace properly
for /f "tokens=* delims= " %%A in ("%WIFI_IP%") do set WIFI_IP=%%A
for /f "tokens=* delims= " %%A in ("%WIFI_MASK%") do set WIFI_MASK=%%A
for /f "tokens=* delims= " %%A in ("%WIFI_GATEWAY%") do set WIFI_GATEWAY=%%A

:: Ensure defaults for missing values
if "%WIFI_IP%"=="" set WIFI_IP=Unavailable
if "%WIFI_MASK%"=="" set WIFI_MASK=Unavailable
if "%WIFI_GATEWAY%"=="" set WIFI_GATEWAY=Unavailable

goto LOG_DETAILS

:CONFIG_LAN
:: Retrieve LAN details and configure static IP
echo Configuring LAN (Ethernet) with static IP...

set LAN_IP=
set LAN_MASK=
set LAN_GATEWAY=

:: Parse LAN IP Address
for /f "tokens=2 delims=:" %%A in ('ipconfig ^| findstr /c:"Ethernet adapter Ethernet" /c:"IPv4 Address"') do (
    for /f "tokens=*" %%B in ("%%A") do set LAN_IP=%%B
)

:: Parse LAN Subnet Mask
for /f "tokens=2 delims=:" %%A in ('ipconfig ^| findstr /c:"Ethernet adapter Ethernet" /c:"Subnet Mask"') do (
    for /f "tokens=*" %%B in ("%%A") do set LAN_MASK=%%B
)

:: Parse LAN Default Gateway
for /f "tokens=2 delims=:" %%A in ('ipconfig ^| findstr /c:"Ethernet adapter Ethernet" /c:"Default Gateway"') do (
    for /f "tokens=*" %%B in ("%%A") do set LAN_GATEWAY=%%B
)

:: Trim leading/trailing spaces properly
for /f "tokens=* delims= " %%A in ("%LAN_IP%") do set LAN_IP=%%A
for /f "tokens=* delims= " %%A in ("%LAN_MASK%") do set LAN_MASK=%%A
for /f "tokens=* delims= " %%A in ("%LAN_GATEWAY%") do set LAN_GATEWAY=%%A

:: Ensure defaults for missing values
if "%LAN_IP%"=="" set LAN_IP=Unavailable
if "%LAN_MASK%"=="" set LAN_MASK=255.255.255.0
if "%LAN_GATEWAY%"=="" set LAN_GATEWAY=Unavailable

:: Apply static IP configuration if LAN details are valid
if not "%LAN_IP%"=="Unavailable" (
    netsh interface ip set address name="Ethernet" static %LAN_IP% %LAN_MASK% %LAN_GATEWAY%
    netsh interface ip set dns name="Ethernet" static %LAN_GATEWAY%
    echo [+] Static IP configuration applied successfully for Ethernet.
)

goto LOG_DETAILS

:LOG_DETAILS
:: Retrieve computer name
set COMPUTER_NAME=%COMPUTERNAME%

:: Prompt user for a custom note
set /p NOTE="Enter a custom note for this computer: "

:: Log details to a file
set OUTPUT_FILE=%~dp0list_of_devices.txt
(
    echo =======================================================
    echo          Configuration Log
    echo =======================================================
    echo Computer Name: %COMPUTER_NAME%
    echo Connection Type: %CONN_TYPE%
    echo Wi-Fi IP Address: %WIFI_IP%
    echo Wi-Fi Subnet Mask: %WIFI_MASK%
    echo Wi-Fi Gateway: %WIFI_GATEWAY%
    echo LAN IP Address: %LAN_IP%
    echo LAN Subnet Mask: %LAN_MASK%
    echo LAN Gateway: %LAN_GATEWAY%
    echo Custom Note: %NOTE%
    echo =======================================================
    echo Timestamp: %date% %time%
    echo =======================================================
) >> "%OUTPUT_FILE%"

echo Configuration information has been saved to %OUTPUT_FILE%.
pause
