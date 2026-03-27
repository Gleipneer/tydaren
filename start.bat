@echo off
REM Tyda — Docker-MySQL (om tillgangligt), backend :8000, frontend :5173. Se START.md for forsta gangen.
title Tyda
cd /d "%~dp0"

echo.
echo  Startar Tyda...
echo.

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\start.ps1"
set EXITCODE=%ERRORLEVEL%

if %EXITCODE% neq 0 (
  echo.
  echo Start misslyckades (kod %EXITCODE%^).
  pause
  exit /b %EXITCODE%
)
