# run_hosted.ps1
#
# Runs Bag2School against the hosted Supabase project instead of the laptop.
#
# Usage:
#   .\tool\run_hosted.cmd                  # first connected device
#   .\tool\run_hosted.cmd -Device 192.168.86.198:5555
#
# The URL and publishable key are the ones from the hosted dashboard. They are
# public values; the secret/service_role key must never be used in the app.

param(
    [string] $Device,
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

$url = 'https://yookyjknkefxledfyybv.supabase.co'
$key = 'sb_publishable_xoYG7gKUySYkYwZ21eu_8Q_uRivcSsp'

$adb = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"
if (-not (Test-Path $adb)) {
    $command = Get-Command adb -ErrorAction SilentlyContinue
    if ($command) { $adb = $command.Source }
    else { throw 'adb.exe tidak ditemukan.' }
}

if (-not $Device) {
    $line = & $adb devices | Select-String -Pattern '^\S+\s+device$' | Select-Object -First 1
    if (-not $line) { throw 'Tidak ada HP terhubung. Colok kabel atau jalankan connect_wifi.cmd.' }
    $Device = ($line.Line -split '\s+')[0]
}

Write-Host "device : $Device"
Write-Host "supabase: $url"

flutter run -d $Device `
    --dart-define=SUPABASE_URL=$url `
    --dart-define=SUPABASE_KEY=$key `
    @FlutterArgs
