@echo off
REM Publishes docs/*.html to GitHub Pages (main branch, /docs folder).
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0publish_site.ps1" %*
