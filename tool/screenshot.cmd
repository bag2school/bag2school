@echo off
REM Saves a screenshot to build\screen.png (USB or Wi-Fi, first device).
REM
REM Redirection in PowerShell corrupts the PNG, so this pulls the file from the
REM phone instead of piping the bytes.
REM
REM Usage:
REM   .\tool\screenshot.cmd
REM   .\tool\screenshot.cmd 4e1d78ca
REM   .\tool\screenshot.cmd 4e1d78ca build\grant-access.png
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$adb = Join-Path $env:LOCALAPPDATA 'Android\Sdk\platform-tools\adb.exe';" ^
  "if (-not (Test-Path $adb)) { $adb = 'adb' };" ^
  "$serial = '%1';" ^
  "$out = '%2';" ^
  "if (-not $out) { $out = 'build\screen.png' }" ^
  "$lines = & $adb devices;" ^
  "$devices = $lines | Select-String -Pattern '^\S+\s+device$' | ForEach-Object { ($_.Line -split '\s+')[0] };" ^
  "if (-not $devices) { Write-Host 'Tidak ada HP terhubung.' -ForegroundColor Yellow; exit 1 }" ^
  "if (-not $serial) {" ^
  "  $usb = $devices | Where-Object { $_ -notmatch ':\d+$' } | Select-Object -First 1;" ^
  "  $serial = if ($usb) { $usb } else { $devices | Select-Object -First 1 } }" ^
  "New-Item -ItemType Directory -Force -Path (Split-Path $out) | Out-Null;" ^
  "& $adb -s $serial shell screencap -p /sdcard/bagi_screen.png;" ^
  "& $adb -s $serial pull /sdcard/bagi_screen.png $out | Out-Null;" ^
  "& $adb -s $serial shell rm /sdcard/bagi_screen.png;" ^
  "if (Test-Path $out) {" ^
  "  $size = [Math]::Round((Get-Item $out).Length / 1KB);" ^
  "  Write-Host ('Tersimpan: ' + $out + ' (' + $size + ' KB, device ' + $serial + ')')" ^
  "} else { Write-Host 'Gagal menyimpan screenshot.' -ForegroundColor Yellow }"
