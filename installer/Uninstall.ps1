[CmdletBinding()]
param([string]$GameDirectory)

$ErrorActionPreference = "Stop"
if ([string]::IsNullOrWhiteSpace($GameDirectory)) {
    $candidate = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot "..\..\Project Reignition - Windows v1.0.0"))
    if (Test-Path -LiteralPath (Join-Path $candidate "Project Reignition.exe")) {
        $GameDirectory = $candidate
    } else {
        $GameDirectory = Read-Host "Paste the game folder containing Project Reignition.exe"
    }
}

$game = (Resolve-Path -LiteralPath $GameDirectory).Path
$backup = Join-Path $game "ReignitionKR_Backup_v1.0.0"
$manifest = Join-Path $backup "installation.json"
if (!(Test-Path -LiteralPath $manifest)) {
    throw "The installation record was not found: $manifest"
}

$installation = Get-Content -Raw -LiteralPath $manifest | ConvertFrom-Json
$managed = Join-Path $game "data_Sonic Remake Project_windows_x86_64"
Copy-Item -LiteralPath (Join-Path $backup "Sonic Remake Project.dll") -Destination (Join-Path $managed "Sonic Remake Project.dll") -Force
if (Test-Path -LiteralPath (Join-Path $backup "Sonic Remake Project.pdb")) {
    Copy-Item -LiteralPath (Join-Path $backup "Sonic Remake Project.pdb") -Destination (Join-Path $managed "Sonic Remake Project.pdb") -Force
}

$previousPack = Join-Path $backup "ProjectReignition_Korean.previous.pck"
if (Test-Path -LiteralPath $previousPack) {
    Copy-Item -LiteralPath $previousPack -Destination $installation.PackPath -Force
} elseif (Test-Path -LiteralPath $installation.PackPath) {
    Remove-Item -LiteralPath $installation.PackPath -Force
}

Write-Host ""
Write-Host "Uninstallation completed and the original DLL was restored." -ForegroundColor Green
Write-Host "The backup folder was kept for safety: $backup"
