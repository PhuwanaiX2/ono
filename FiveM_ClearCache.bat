@echo off
:: ==============================================================================
:: FiveM Auto Cache Cleaner (Safe Mode)
:: ==============================================================================
chcp 65001 >nul
set "ShopName=OONO Shop"
title %ShopName% - FiveM Auto Cache Cleaner
color 0B

echo ===================================================
echo             %ShopName% - CLEAR FIVEM CACHE
echo ===================================================
echo This tool will safely clear your FiveM cache.
echo It will NOT delete your game-storage (to save download time).
echo.
pause

set "FiveMPath=%LocalAppData%\FiveM\FiveM.app"

if not exist "%FiveMPath%" (
    color 0C
    echo [ERROR] FiveM folder not found at:
    echo %FiveMPath%
    echo Make sure FiveM is installed correctly.
    echo.
    pause
    exit
)

echo.
echo [INFO] Closing FiveM to prevent errors...
taskkill /f /im FiveM.exe >nul 2>&1
taskkill /f /im FiveM_b*.exe >nul 2>&1
taskkill /f /im GTA5.exe >nul 2>&1
timeout /t 2 /nobreak >nul

echo.
echo [INFO] Deleting cache folders...
if exist "%FiveMPath%\data\cache" (
    echo Deleting data\cache...
    rd /s /q "%FiveMPath%\data\cache"
)
if exist "%FiveMPath%\data\server-cache" (
    echo Deleting data\server-cache...
    rd /s /q "%FiveMPath%\data\server-cache"
)
if exist "%FiveMPath%\data\server-cache-priv" (
    echo Deleting data\server-cache-priv...
    rd /s /q "%FiveMPath%\data\server-cache-priv"
)
if exist "%FiveMPath%\crashes" (
    echo Deleting crashes...
    rd /s /q "%FiveMPath%\crashes"
)
if exist "%FiveMPath%\logs" (
    echo Deleting logs...
    rd /s /q "%FiveMPath%\logs"
)

color 0A
echo.
echo ===================================================
echo    SUCCESS! FiveM Cache has been cleared safely.
echo ===================================================
echo.
pause
