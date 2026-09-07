[CmdletBinding()]
param([string]$GameDirectory)

$ErrorActionPreference = "Stop"
$gameVersion = "v1.0.1"
$originalDllHash = "2138DAF39185E012E5390663369F6910BAB7E21799FB94380E0289F986D7E5E8"
$patchedDllHash = "F6F84E1364DA9D3D2714319F067E62B2966F36A99A3ED2F51617F0C234E32E92"

if ([string]::IsNullOrWhiteSpace($GameDirectory)) {
    $candidates = @(
        $PSScriptRoot,
        (Split-Path $PSScriptRoot -Parent),
        [IO.Path]::GetFullPath((Join-Path $PSScriptRoot "..\..\Project Reignition - Windows v1.0.1"))
    )
    $GameDirectory = $candidates |
        Where-Object { Test-Path -LiteralPath (Join-Path $_ "Project Reignition.exe") } |
        Select-Object -First 1

    if ([string]::IsNullOrWhiteSpace($GameDirectory)) {
        Write-Host "Project Reignition 게임 폴더를 자동으로 찾지 못했습니다." -ForegroundColor Yellow
        Write-Host "'Project Reignition.exe'가 들어 있는 폴더의 전체 경로를 붙여넣어 주세요."
        Write-Host "예: E:\Games\Project Reignition - Windows v1.0.1"
        Write-Host "탐색기 주소 표시줄의 경로를 복사하거나, 폴더를 이 창으로 끌어다 놓아도 됩니다."
        Write-Host "실행 파일 자체가 아니라 실행 파일이 들어 있는 폴더를 지정해야 합니다."
        Write-Host ""
        $GameDirectory = Read-Host "게임 폴더 경로"
    }
}

$GameDirectory = ([string]$GameDirectory).Trim().Trim('"')
if ([string]::IsNullOrWhiteSpace($GameDirectory) -or !(Test-Path -LiteralPath $GameDirectory -PathType Container)) {
    throw "입력한 게임 폴더를 찾을 수 없습니다: $GameDirectory"
}

$game = (Resolve-Path -LiteralPath $GameDirectory).Path
$gameExe = Join-Path $game "Project Reignition.exe"
$managed = Join-Path $game "data_Sonic Remake Project_windows_x86_64"
$gameDll = Join-Path $managed "Sonic Remake Project.dll"
$gamePdb = Join-Path $managed "Sonic Remake Project.pdb"
if (!(Test-Path -LiteralPath $gameExe) -or !(Test-Path -LiteralPath $gameDll)) {
    throw "Project Reignition $gameVersion 게임 폴더가 아닙니다. 'Project Reignition.exe'가 있는 폴더를 지정해 주세요: $game"
}

try {
    $lockTest = [IO.File]::Open($gameDll, [IO.FileMode]::Open, [IO.FileAccess]::ReadWrite, [IO.FileShare]::None)
    $lockTest.Dispose()
} catch {
    throw "Project Reignition을 완전히 종료한 뒤 설치기를 다시 실행해 주세요. 현재 게임 파일이 사용 중입니다."
}

$currentHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $gameDll).Hash
if ($currentHash -ne $originalDllHash -and $currentHash -ne $patchedDllHash) {
    throw "지원하는 Project Reignition $gameVersion 게임 파일과 일치하지 않습니다. v1.0.1 원본을 다시 준비하거나, 다른 DLL 패치를 먼저 제거해 주세요. 현재 DLL SHA-256: $currentHash"
}

$backup = Join-Path $game "ReignitionKR_Backup_v1.0.1"
New-Item -ItemType Directory -Force -Path $backup | Out-Null
if ($currentHash -eq $originalDllHash -and !(Test-Path -LiteralPath (Join-Path $backup "Sonic Remake Project.dll"))) {
    Copy-Item -LiteralPath $gameDll -Destination (Join-Path $backup "Sonic Remake Project.dll")
    if (Test-Path -LiteralPath $gamePdb) {
        Copy-Item -LiteralPath $gamePdb -Destination (Join-Path $backup "Sonic Remake Project.pdb")
    }
}

Copy-Item -LiteralPath (Join-Path $PSScriptRoot "files\Sonic Remake Project.dll") -Destination $gameDll -Force
Copy-Item -LiteralPath (Join-Path $PSScriptRoot "files\Sonic Remake Project.pdb") -Destination $gamePdb -Force

$saveLocation = Join-Path $game "saveLocation.txt"
if (Test-Path -LiteralPath $saveLocation) {
    $configured = [IO.File]::ReadAllText($saveLocation).Trim()
    $dataRoot = if (![string]::IsNullOrWhiteSpace($configured) -and (Test-Path -LiteralPath $configured -PathType Container)) { $configured } else { $game }
} else {
    $dataRoot = Join-Path $env:APPDATA "Godot\app_userdata\Sonic and the Secret Rings Remake"
}

$languageDirectory = Join-Path $dataRoot "mods\lang"
New-Item -ItemType Directory -Force -Path $languageDirectory | Out-Null
$installedPack = Join-Path $languageDirectory "ProjectReignition_Korean.pck"
$manifest = Join-Path $backup "installation.json"
if (Test-Path -LiteralPath $manifest) {
    $oldInstallation = Get-Content -Raw -LiteralPath $manifest | ConvertFrom-Json
    $oldPack = [string]$oldInstallation.PackPath
    if (![string]::IsNullOrWhiteSpace($oldPack) -and $oldPack -ne $installedPack -and (Test-Path -LiteralPath $oldPack)) {
        $releasePackHash = (Get-FileHash -Algorithm SHA256 -LiteralPath (Join-Path $PSScriptRoot "files\ProjectReignition_Korean.pck")).Hash
        $oldPackHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $oldPack).Hash
        if ($oldPackHash -eq $releasePackHash) {
            Remove-Item -LiteralPath $oldPack -Force
        }
    }
}

$previousPack = Join-Path $backup "ProjectReignition_Korean.previous.pck"
if ((Test-Path -LiteralPath $installedPack) -and !(Test-Path -LiteralPath $previousPack)) {
    Copy-Item -LiteralPath $installedPack -Destination $previousPack
}
Copy-Item -LiteralPath (Join-Path $PSScriptRoot "files\ProjectReignition_Korean.pck") -Destination $installedPack -Force

@{
    GameVersion = $gameVersion
    GameDirectory = $game
    PackPath = $installedPack
    OriginalDllHash = $originalDllHash
    PatchedDllHash = $patchedDllHash
    PackHash = (Get-FileHash -Algorithm SHA256 -LiteralPath (Join-Path $PSScriptRoot "files\ProjectReignition_Korean.pck")).Hash
} | ConvertTo-Json | Set-Content -LiteralPath $manifest -Encoding UTF8

Write-Host ""
Write-Host "한국어 패치 설치가 완료되었습니다." -ForegroundColor Green
Write-Host "게임 폴더: $game"
Write-Host "게임을 실행한 뒤 Options > Language > Text Language에서 Korean을 선택해 주세요."
Write-Host "전체 2,321개 텍스트의 한국어 번역이 포함되어 있습니다."
