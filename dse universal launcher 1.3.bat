@echo off
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Relaunching with administrator privileges...
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

cd /d "%~dp0"

:: ============================
:: CHECK CORE ISOLATION STATUS
:: ============================
echo Checking Core Isolation (Memory Integrity)...

set "CI="

for /f "tokens=3" %%A in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" /v Enabled 2^>nul ^| find /i "Enabled"') do set CI=%%A
set CI=%CI: =%

echo Detected CI value: "%CI%"

if "%CI%"=="" (
    echo Core Isolation key not found. Assuming it is disabled.
    goto CHECK_MSI
)

if /i "%CI%"=="1" goto CORE_ON
if /i "%CI%"=="0x1" goto CORE_ON

goto CHECK_MSI

:CORE_ON
color 0C
echo.
echo ================================================
echo   ERROR: Core Isolation (Memory Integrity) is ON
echo ===============================================
echo.
echo Please DISABLE Core Isolation (Memory Integrity)
echo from Windows Security - Device Security.
echo.
echo After disabling it, RESTART your PC
echo and run this script again.
echo.
pause
color 07
goto END


:: ============================================
:: CHECK IF MSI AFTERBURNER IS RUNNING
:: ============================================
:CHECK_MSI
echo Checking MSI Afterburner status...

set "MSI_RUNNING=0"

tasklist /FI "IMAGENAME eq MSIAfterburner.exe" | find /I "MSIAfterburner.exe" >nul
if %errorlevel%==0 (
    echo MSI Afterburner is running. Closing it...
    set "MSI_RUNNING=1"
    taskkill /IM MSIAfterburner.exe /F >nul 2>&1
) else (
    echo MSI Afterburner is not running.
)

echo.
goto CONTINUE_SCRIPT


:CONTINUE_SCRIPT
echo Core Isolation is disabled. Continuing...
echo.

set "loader="

if exist "steamclient_loader_x64.exe" set "loader=steamclient_loader_x64.exe"
if not defined loader if exist "HypervisorLauncher.exe" set "loader=HypervisorLauncher.exe"
if not defined loader if exist "launcher.exe" set "loader=launcher.exe"
if not defined loader if exist "hypervisor-launcher.exe" set "loader=hypervisor-launcher.exe"

if not defined loader (
    echo ERROR: No loader executable found!
    pause
    goto END
)

echo [1/3] Disabling DSE...
DSE-Patcher.exe -disable

echo Waiting 5 seconds...
timeout /t 5 /nobreak >nul

echo Found: %loader%
start "" "%loader%"

echo Waiting 5 seconds...
timeout /t 5 /nobreak >nul

echo [3/3] Enabling DSE...
DSE-Patcher.exe -enable

:: ============================================
:: RESTART MSI AFTERBURNER IF IT WAS RUNNING
:: ============================================
if "%MSI_RUNNING%"=="1" (
    echo Restarting MSI Afterburner...
    start "" "C:\Program Files (x86)\MSI Afterburner\MSIAfterburner.exe"
) else (
    echo MSI Afterburner was not running before. Skipping restart.
)

:END
exit