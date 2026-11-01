# publish_site.ps1
#
# Publishes the policy pages (docs/*.html) to GitHub Pages.
#
# GitHub Pages serves the `main` branch, folder /docs. Our working branch keeps
# the real history, so this script refreshes a single-commit snapshot branch
# (`publish`) from the working branch and force-pushes it to main.
#
# Usage:
#   .\tool\publish_site.cmd
#   .\tool\publish_site.cmd -Message "docs: new support email"
#   .\tool\publish_site.cmd -Source feature/schedule -Remote origin -Branch main

param(
    [string] $Message = "Bag2School: public snapshot for GitHub Pages",
    [string] $Source,
    [string] $Remote = "origin",
    [string] $Branch = "main",
    [string] $Snapshot = "publish"
)

$ErrorActionPreference = 'Stop'

function Find-Git {
    $candidates = @(
        "$env:ProgramFiles\Git\cmd\git.exe",
        "${env:ProgramFiles(x86)}\Git\cmd\git.exe",
        "$env:LOCALAPPDATA\Programs\Git\cmd\git.exe"
    )
    foreach ($path in $candidates) {
        if (Test-Path $path) { return $path }
    }
    $command = Get-Command git -ErrorAction SilentlyContinue
    if ($command) { return $command.Source }
    throw 'git.exe tidak ditemukan. Install Git atau tambahkan ke PATH.'
}

$git = Find-Git
Write-Host "git    : $git"

if (-not $Source) {
    $Source = (& $git branch --show-current).Trim()
    if (-not $Source) { throw 'Tidak bisa membaca branch aktif.' }
}

# Only tracked changes block publishing; untracked art files are fine.
$dirty = & $git status --porcelain --untracked-files=no
if ($dirty) {
    Write-Host 'Ada perubahan yang belum di-commit:' -ForegroundColor Yellow
    $dirty | ForEach-Object { Write-Host "  $_" }
    throw 'Commit dulu (git add + git commit) sebelum publish.'
}

$remoteUrl = & $git remote get-url $Remote 2>$null
if (-not $remoteUrl) { throw "Remote '$Remote' belum ada. Jalankan: git remote add $Remote <url>" }

Write-Host "source : $Source"
Write-Host "remote : $Remote ($remoteUrl) -> $Branch"
Write-Host ''

$switched = $false
try {
    if (& $git rev-parse --verify --quiet $Snapshot) {
        & $git checkout -f $Snapshot | Out-Null
    } else {
        & $git checkout --orphan $Snapshot | Out-Null
    }
    $switched = $true

    # Take the exact file set of the working branch, without its history.
    & $git read-tree $Source

    & $git commit -q --amend -m $Message

    $size = (& $git ls-tree -r --long HEAD |
        ForEach-Object { [int](($_ -split '\s+')[3]) } |
        Measure-Object -Sum).Sum
    $count = (& $git ls-files | Measure-Object).Count
    Write-Host ("snapshot: {0:N1} MB, {1} file, commit {2}" -f ($size / 1MB), $count, (& $git rev-parse --short HEAD))

    Write-Host "mendorong ke $Remote/$Branch ..." -ForegroundColor Cyan
    & $git push --force $Remote "${Snapshot}:${Branch}"
}
finally {
    if ($switched) {
        & $git checkout -f $Source | Out-Null
        Write-Host "kembali ke branch $Source"
    }
}

$remoteUrl -match 'github\.com[/:](?<owner>[^/]+)/(?<repo>[^/.]+)' | Out-Null
$owner = $Matches['owner']
$repo = $Matches['repo']

if ($owner -and $repo) {
    Write-Host ''
    Write-Host 'Selesai. Tunggu ±1 menit, lalu buka (Ctrl+F5):' -ForegroundColor Green
    Write-Host "  https://$owner.github.io/$repo/"
    Write-Host "  https://$owner.github.io/$repo/privacy.html"
    Write-Host "  https://$owner.github.io/$repo/delete-account.html"
}
