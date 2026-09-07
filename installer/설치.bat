@echo off
chcp 65001 >nul
title Project Reignition 한국어 모드 설치
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Install.ps1" -GameDirectory "%~1"
echo.
if errorlevel 1 echo 설치하지 못했습니다. 위의 오류 내용을 확인해 주세요.
pause
