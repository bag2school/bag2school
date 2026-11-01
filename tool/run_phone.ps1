# Starts the local Supabase tunnel and launches Bag2School on the phone.
#
# The app talks to http://127.0.0.1:54321 on Android, and that address only
# exists while `adb reverse` is open. The tunnel disappears when the cable is
# unplugged, the phone reboots, or the adb server restarts, which shows up in
# the app as "Connection refused (errno 111)".
#
# Usage (from the project root):
#   .\tool\run_phone.ps1
#   .\tool\run_phone.ps1 -d 4e1d78ca          # pick a specific device
#   .\tool\run_phone.ps1 --release            # any flutter run flag

param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]] $FlutterArgs
)

$ErrorActionPreference = 'Stop'

# Flutter calls git for version info. Git is installed here but often missing
# from PATH, so add it for this process only.
foreach ($gitDir in @("$env:ProgramFiles\Git\cmd", "$env:LOCALAPPDATA\Programs\Git\cmd")) {
    if ((Test-Path (Join-Path $gitDir 'git.exe')) -and ($env:Path -notlike "*$gitDir*")) {
        $env:Path = "$gitDir;$env:Path"
    }
}

$adb = Join-Path $env:LOCALAPPDATA 'Android\Sdk\platform-tools\adb.exe'

if (-not (Test-Path $adb)) {
    $command = Get-Command adb -ErrorAction SilentlyContinue
    if ($command) {
        $adb = $command.Source
    }
    else {
        throw 'adb was not found. Install Android platform-tools or add them to PATH.'
    }
}

$devices = & $adb devices | Select-String 'device$'
if (-not $devices) {
    throw 'No phone detected. Connect the cable and enable USB debugging.'
}

# Rebuild the tunnel from scratch so a stale mapping cannot linger.
& $adb reverse --remove-all 2>$null | Out-Null
& "$PSScriptRoot\ensure_tunnel.ps1" | Out-Null

Write-Host 'Tunnel ready: phone 127.0.0.1:54321 -> laptop 54321' -ForegroundColor Green
Write-Host 'If it drops mid-session (cable, reboot, adb restart), run:' -ForegroundColor DarkGray
Write-Host '  .\tool\ensure_tunnel.ps1 -Watch' -ForegroundColor DarkGray
Write-Host 'Launching Bag2School...' -ForegroundColor Green

flutter run @FlutterArgs
