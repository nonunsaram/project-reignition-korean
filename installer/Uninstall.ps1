[CmdletBinding()]
param([string]$GameDirectory)

$ErrorActionPreference = "Stop"
if ([string]::IsNullOrWhiteSpace($GameDirectory)) {
    $candidates = @(
        $PSScriptRoot,
        (Split-Path $PSScriptRoot -Parent),
        [IO.Path]::GetFullPath((Join-Path $PSScriptRoot "..\..\Project Reignition - Windows v1.0.0"))
    )
    $GameDirectory = $candidates |
        Where-Object { Test-Path -LiteralPath (Join-Path $_ "Project Reignition.exe") } |
        Select-Object -First 1

    if ([string]::IsNullOrWhiteSpace($GameDirectory)) {
        Write-Host "Project Reignition 게임 폴더를 자동으로 찾지 못했습니다." -ForegroundColor Yellow
        Write-Host "'Project Reignition.exe'가 들어 있는 폴더의 전체 경로를 붙여넣어 주세요."
        Write-Host "예: E:\Games\Project Reignition - Windows v1.0.0"
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
$backup = Join-Path $game "ReignitionKR_Backup_v1.0.0"
$manifest = Join-Path $backup "installation.json"
if (!(Test-Path -LiteralPath $manifest)) {
    throw "한국어 패치 설치 기록을 찾을 수 없습니다: $manifest"
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
Write-Host "한국어 패치를 제거하고 원본 게임 파일을 복원했습니다." -ForegroundColor Green
Write-Host "안전을 위해 백업 폴더는 남겨 두었습니다: $backup"
