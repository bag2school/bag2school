# connect_wifi.ps1
#
# Switches adb from USB to Wi-Fi so `flutter run` works without a cable.
#
# Requirements:
#   - phone and laptop on the same Wi-Fi network
#   - USB debugging enabled (the first call still uses the cable)
#   - VPN off on the phone
#
# Usage:
#   .\tool\connect_wifi.ps1              # detect the phone IP over USB, then switch
#   .\tool\connect_wifi.ps1 -Ip 192.168.86.198
#   .\tool\connect_wifi.ps1 -Port 5555
#
# After the switch you can unplug the cable and run:
#   flutter run -d <ip>:<port>
#
# `adb reverse` keeps working over Wi-Fi, so the app can still use
# 127.0.0.1:54321 for Supabase. Run .\tool\ensure_tunnel.ps1 after connecting.

param(
    [string] $Ip,
    [int] $Port = 5555
)

$ErrorActionPreference = 'Stop'

function Find-Adb {
    $candidates = @(
        "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe",
        "$env:USERPROFILE\AppData\Local\Android\Sdk\platform-tools\adb.exe",
        'C:\Android\platform-tools\adb.exe',
        'D:\Android\platform-tools\adb.exe'
    )

    foreach ($path in $candidates) {
        if (Test-Path $path) { return $path }
    }

    $command = Get-Command adb -ErrorAction SilentlyContinue
    if ($command) { return $command.Source }

    throw 'adb.exe not found. Install Android platform-tools or add them to PATH.'
}

$adb = Find-Adb
Write-Host "adb: $adb"

$usbDevice = & $adb devices | Select-String -Pattern '^\S+\s+device$' |
    Where-Object { $_.Line -notmatch ':\d+' } |
    Select-Object -First 1

if (-not $Ip) {
    if (-not $usbDevice) {
        throw 'No USB device detected. Plug the cable once, or pass -Ip <phone-ip>.'
    }

    $ipLine = & $adb shell ip -f inet addr show wlan0 2>$null |
        Select-String -Pattern 'inet (\d+\.\d+\.\d+\.\d+)'

    if (-not $ipLine) {
        throw 'Could not read the phone Wi-Fi address. Pass -Ip <phone-ip>.'
    }

    $Ip = [regex]::Match($ipLine.Line, 'inet (\d+\.\d+\.\d+\.\d+)').Groups[1].Value
    Write-Host "phone Wi-Fi IP: $Ip"
}

if ($usbDevice) {
    Write-Host 'Switching adbd to TCP mode (the USB connection drops for a moment)...'
    & $adb tcpip $Port | Out-Null
    Start-Sleep -Seconds 2
}

& $adb connect "${Ip}:$Port" | Out-Null
Start-Sleep -Seconds 2

$connected = & $adb devices | Select-String -Pattern ([regex]::Escape("${Ip}:$Port"))
if (-not $connected) {
    throw "Could not connect to ${Ip}:$Port. Check the Wi-Fi network and that the phone is awake."
}

Write-Host "connected: ${Ip}:$Port" -ForegroundColor Green
Write-Host 'You can unplug the cable now, then run:' -ForegroundColor Green
Write-Host "  flutter run -d ${Ip}:$Port" -ForegroundColor DarkGray
Write-Host '  .\tool\ensure_tunnel.ps1    # so the app still reaches Supabase' -ForegroundColor DarkGray
