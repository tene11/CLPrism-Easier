@echo off
rem Double-click to publish this folder to a private GitHub repository
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0publish.ps1" %*
echo.
pause
