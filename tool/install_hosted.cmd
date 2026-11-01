@echo off
REM Builds and installs the hosted build through pm (MIUI friendly).
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0install_hosted.ps1" %*
