# Caply — Push to GitHub
# Run this from PowerShell in the Caply folder:
#   Set-ExecutionPolicy -Scope Process Bypass; .\push-to-github.ps1

$ErrorActionPreference = "Stop"
$repo = "https://github.com/sunilksoni-Claude/Caply.git"

Write-Host "`n=== Caply: Push to GitHub ===" -ForegroundColor Cyan

# Init if not already a repo
if (-not (Test-Path ".git")) {
    git init
    git checkout -b main
}

git config user.email "sunilksoni@gmail.com"
git config user.name  "Sunil Soni"

# Add remote if missing
$remotes = git remote 2>$null
if ($remotes -notcontains "origin") {
    git remote add origin $repo
} else {
    git remote set-url origin $repo
}

git add .
git status

Write-Host "`nCommitting..." -ForegroundColor Yellow
git commit -m "Initial commit: Caply subtitle editor PWA" 2>&1 | ForEach-Object {
    if ($_ -match "nothing to commit") { Write-Host "Nothing new to commit." -ForegroundColor Gray }
    else { Write-Host $_ }
}

Write-Host "`nPushing to GitHub (you may be prompted for credentials)..." -ForegroundColor Yellow
git push -u origin main --force

Write-Host "`nDone! View at: $repo" -ForegroundColor Green
