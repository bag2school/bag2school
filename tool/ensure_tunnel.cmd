@echo off
REM Runs ensure_tunnel.ps1 without changing the machine execution policy.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0ensure_tunnel.ps1" %*
