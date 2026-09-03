[CmdletBinding()]
param([string]$GameDirectory)

$ErrorActionPreference = "Stop"
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
$backup = Join-Path $game "ReignitionKR_Backup_v1.0.1"
$manifest = Join-Path $backup "installation.json"
if (!(Test-Path -LiteralPath $manifest)) {
    throw "한국어 패치 설치 기록을 찾을 수 없습니다: $manifest"
}

$installation = Get-Content -Raw -LiteralPath $manifest | ConvertFrom-Json
$managed = Join-Path $game "data_Sonic Remake Project_windows_x86_64"
$gameDll = Join-Path $managed "Sonic Remake Project.dll"
$backupDll = Join-Path $backup "Sonic Remake Project.dll"
$currentHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $gameDll).Hash
$backupHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $backupDll).Hash
$dllRestored = $false
if ($currentHash -eq [string]$installation.PatchedDllHash) {
    if ($backupHash -ne [string]$installation.OriginalDllHash) {
        throw "백업 DLL 검증에 실패했습니다. 게임 파일을 덮어쓰지 않았습니다: $backupDll"
    }
    Copy-Item -LiteralPath $backupDll -Destination $gameDll -Force
    if (Test-Path -LiteralPath (Join-Path $backup "Sonic Remake Project.pdb")) {
        Copy-Item -LiteralPath (Join-Path $backup "Sonic Remake Project.pdb") -Destination (Join-Path $managed "Sonic Remake Project.pdb") -Force
    }
    $dllRestored = $true
} elseif ($currentHash -ne [string]$installation.OriginalDllHash) {
    Write-Warning "설치 후 게임 DLL이 변경되어 원본 DLL 복원을 건너뜁니다. 공식 업데이트 파일일 수 있으므로 현재 파일을 유지합니다."
}

$previousPack = Join-Path $backup "ProjectReignition_Korean.previous.pck"
$packPath = [string]$installation.PackPath
if (Test-Path -LiteralPath $packPath) {
    $currentPackHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $packPath).Hash
    if ($currentPackHash -eq [string]$installation.PackHash) {
        if (Test-Path -LiteralPath $previousPack) {
            Copy-Item -LiteralPath $previousPack -Destination $packPath -Force
        } else {
            Remove-Item -LiteralPath $packPath -Force
        }
    } else {
        Write-Warning "설치 후 한국어 PCK가 변경되어 삭제하지 않았습니다: $packPath"
    }
}

Write-Host ""
if ($dllRestored) {
    Write-Host "한국어 패치를 제거하고 Project Reignition v1.0.1 원본 DLL을 복원했습니다." -ForegroundColor Green
} else {
    Write-Host "한국어 패치 파일을 정리했습니다. 현재 게임 DLL은 변경하지 않았습니다." -ForegroundColor Green
}
Write-Host "안전을 위해 백업 폴더는 남겨 두었습니다: $backup"
