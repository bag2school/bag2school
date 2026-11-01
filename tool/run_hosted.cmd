@echo off
REM Runs Bag2School against the hosted Supabase project.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0run_hosted.ps1" %*
