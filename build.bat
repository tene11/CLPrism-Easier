@echo off
rem Double-click to build. Everything is logged to build-log.txt
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0build.ps1" %*
echo.
pause
