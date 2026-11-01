# install_hosted.ps1
#
# Builds the app against the hosted Supabase project and installs it on the
# phone through `pm install`, which works on MIUI/HyperOS where `adb install`
# returns INSTALL_FAILED_USER_RESTRICTED.
#
# Usage:
#   .\tool\install_hosted.cmd
#   .\tool\install_hosted.cmd -Device 4e1d78ca

param(
    [string] $Device
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

$dart = 'D:\Flutter\flutter\bin\cache\dart-sdk\bin\dart.exe'
$snap = 'D:\Flutter\flutter\bin\cache\flutter_tools.snapshot'
if (-not (Test-Path $dart)) {
    $dart = 'dart'
    $snap = ''
}

Write-Host "device  : $Device"
Write-Host "supabase: $url"
Write-Host 'Building debug APK (this takes a few minutes)...'

$args = @()
if ($snap) { $args += $snap }
$args += @(
    'build', 'apk', '--debug',
    "--dart-define=SUPABASE_URL=$url",
    "--dart-define=SUPABASE_KEY=$key"
)

& $dart @args
if ($LASTEXITCODE -ne 0) { throw 'Build gagal.' }

$apk = 'build\app\outputs\flutter-apk\app-debug.apk'
Write-Host 'Installing through pm (MIUI friendly)...'
& $adb -s $Device push $apk /data/local/tmp/bag2school.apk | Out-Null
$result = & $adb -s $Device shell "pm install -r -t /data/local/tmp/bag2school.apk"
Write-Host $result.Trim()

if ($result -notmatch 'Success') { throw 'Instalasi gagal. Lihat pesan di atas.' }

& $adb -s $Device shell 'monkey -p com.bag2school.app -c android.intent.category.LAUNCHER 1' | Out-Null
Write-Host 'Aplikasi dijalankan dengan Supabase hosted.' -ForegroundColor Green
