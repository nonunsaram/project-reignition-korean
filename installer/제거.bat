@echo off
setlocal
title Project Reignition Korean Mod Uninstaller
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Uninstall.ps1" -GameDirectory "%~1"
set "result=%errorlevel%"
echo.
if not "%result%"=="0" echo Uninstallation failed. Check the error message above.
pause
exit /b %result%
