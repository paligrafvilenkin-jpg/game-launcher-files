@echo off
chcp 65001 >nul
cd /d "%~dp0"

echo %PROCESSOR_IDENTIFIER% | find /i "AMD" >nul
if %errorlevel% equ 0 (
    set "DRIVER_PATH=driver_amd\SimpleSvm.sys"
) else (
    set "DRIVER_PATH=driver_intel\hyperkd.sys"
)

sc stop denuvo >nul 2>&1
sc delete denuvo >nul 2>&1

sc create denuvo type=kernel start=demand binPath="%~dp0%DRIVER_PATH%"
sc start denuvo

start /wait "" "ACShadows.exe"

sc stop denuvo
sc delete denuvo