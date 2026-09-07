@echo off
setlocal
title Project Reignition Korean Mod Installer
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Install.ps1" -GameDirectory "%~1"
set "result=%errorlevel%"
echo.
if not "%result%"=="0" echo Installation failed. Check the error message above.
pause
exit /b %result%
