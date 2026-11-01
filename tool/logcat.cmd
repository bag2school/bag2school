@echo off
REM Saves the phone log to build\logcat.txt.
REM Works over USB or Wi-Fi, and picks one device when several are attached.
REM Usage:  .\tool\logcat.cmd            (first device, USB preferred)
REM         .\tool\logcat.cmd 4e1d78ca   (specific serial)
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$adb = Join-Path $env:LOCALAPPDATA 'Android\Sdk\platform-tools\adb.exe';" ^
  "if (-not (Test-Path $adb)) { $adb = 'adb' };" ^
  "$serial = '%1';" ^
  "$lines = & $adb devices;" ^
  "$devices = $lines | Select-String -Pattern '^\S+\s+device$' | ForEach-Object { ($_.Line -split '\s+')[0] };" ^
  "if (-not $devices) { Write-Host 'Tidak ada HP terhubung.' -ForegroundColor Yellow; exit 1 }" ^
  "if (-not $serial) {" ^
  "  $usb = $devices | Where-Object { $_ -notmatch ':\d+$' } | Select-Object -First 1;" ^
  "  $serial = if ($usb) { $usb } else { $devices | Select-Object -First 1 } }" ^
  "Write-Host ('device: ' + $serial);" ^
  "New-Item -ItemType Directory -Force -Path build | Out-Null;" ^
  "& $adb -s $serial logcat -d > build\logcat.txt;" ^
  "Write-Host 'Tersimpan di build\logcat.txt';" ^
  "Select-String -Path build\logcat.txt -Pattern '_dependents|Assertion|Exception|SIGNUP|LOGIN|OAUTH' -Context 2,8 |" ^
  "  Select-Object -Last 60"
