# ensure_tunnel.ps1
#
# Keeps the phone able to reach the local Supabase stack.
#
# The app on Android talks to http://127.0.0.1:54321, which only exists inside
# the phone. `adb reverse` forwards that port to the laptop. The mapping is lost
# whenever the cable is unplugged, the phone reboots, or the adb server
# restarts, and then the app logs:
#
#   Access token is expired and refreshing failed ... Connection refused
#   address = 127.0.0.1, port = 54321
#
# Usage:
#   .\tool\ensure_tunnel.ps1            # apply once and exit
#   .\tool\ensure_tunnel.ps1 -Watch     # keep re-applying while it runs
#
# Ports: 54321 = API (auth, rest, realtime), 54324 = Inbucket mail UI.

param(
    [switch]$Watch,
    [int]$IntervalSeconds = 5
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

$ports = @(54321, 54324)

function Apply-Reverse {
    $devices = & $adb devices | Select-String -Pattern '\sdevice$'
    if (-not $devices) {
        Write-Host 'No device connected. Plug the phone in and enable USB debugging.'
        return $false
    }

    foreach ($port in $ports) {
        $existing = & $adb reverse --list | Select-String -Pattern "tcp:$port"
        if ($existing) {
            Write-Host "ok   tcp:$port already forwarded"
            continue
        }

        & $adb reverse "tcp:$port" "tcp:$port" | Out-Null
        Write-Host "open tcp:$port -> laptop"
    }

    return $true
}

if (-not $Watch) {
    Apply-Reverse | Out-Null
    Write-Host ''
    & $adb reverse --list
    exit 0
}

Write-Host "Watching the phone every $IntervalSeconds s. Press Ctrl+C to stop."
$lastState = ''

while ($true) {
    $devices = & $adb devices | Select-String -Pattern '\sdevice$'
    $state = if ($devices) { 'connected' } else { 'disconnected' }

    if ($state -ne $lastState) {
        Write-Host "[$(Get-Date -Format 'HH:mm:ss')] phone $state"
        $lastState = $state
    }

    if ($state -eq 'connected') {
        foreach ($port in $ports) {
            $existing = & $adb reverse --list | Select-String -Pattern "tcp:$port"
            if (-not $existing) {
                & $adb reverse "tcp:$port" "tcp:$port" | Out-Null
                Write-Host "[$(Get-Date -Format 'HH:mm:ss')] re-opened tcp:$port"
            }
        }
    }

    Start-Sleep -Seconds $IntervalSeconds
}
