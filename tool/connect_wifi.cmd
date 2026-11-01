@echo off
REM Runs connect_wifi.ps1 without changing the machine execution policy.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0connect_wifi.ps1" %*
