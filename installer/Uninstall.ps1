[CmdletBinding()]
param(
    [string]$GameDirectory,
    [string]$DataDirectory
)

$ErrorActionPreference = 'Stop'

function Resolve-DataRoot {
    if (-not [string]::IsNullOrWhiteSpace($DataDirectory)) {
        return [IO.Path]::GetFullPath($DataDirectory.Trim().Trim('"'))
    }
    if (-not [string]::IsNullOrWhiteSpace($GameDirectory)) {
        $candidate = $GameDirectory.Trim().Trim('"')
        if (Test-Path -LiteralPath $candidate -PathType Leaf) { $candidate = Split-Path -Parent $candidate }
        if (-not (Test-Path -LiteralPath $candidate -PathType Container)) { throw "게임 폴더를 찾을 수 없습니다: $candidate" }
        $game = (Resolve-Path -LiteralPath $candidate).Path
        if (-not (Test-Path -LiteralPath (Join-Path $game 'Project Reignition.exe') -PathType Leaf)) {
            throw "Project Reignition.exe가 있는 게임 폴더가 아닙니다: $game"
        }
        $saveLocation = Join-Path $game 'saveLocation.txt'
        if (Test-Path -LiteralPath $saveLocation -PathType Leaf) {
            $configured = [IO.File]::ReadAllText($saveLocation).Trim().Trim('"')
            if (-not [string]::IsNullOrWhiteSpace($configured)) {
                if (-not [IO.Path]::IsPathRooted($configured)) { $configured = Join-Path $game $configured }
                return [IO.Path]::GetFullPath($configured)
            }
        }
    }
    return Join-Path $env:APPDATA 'Godot\app_userdata\Sonic and the Secret Rings Remake'
}

if (Get-Process -Name 'Project Reignition' -ErrorAction SilentlyContinue) {
    throw 'Project Reignition을 완전히 종료한 뒤 다시 실행해 주세요.'
}

$dataRoot = Resolve-DataRoot
$backupDirectory = Join-Path $dataRoot 'ReignitionKorean_Backup_v0.3'
$manifest = Join-Path $backupDirectory 'installation.json'
if (-not (Test-Path -LiteralPath $manifest -PathType Leaf)) {
    throw "이 위치에서 설치 기록을 찾을 수 없습니다: $manifest"
}

$installation = Get-Content -Raw -LiteralPath $manifest | ConvertFrom-Json
$packPath = [string]$installation.PackPath
$packHash = [string]$installation.PackHash
$backupPath = [string]$installation.BackupPath

if ([bool]$installation.PreviousExisted) {
    if (-not (Test-Path -LiteralPath $backupPath -PathType Leaf)) {
        throw "이전 Korean.pck 백업을 찾을 수 없습니다: $backupPath"
    }
    if (-not [string]::IsNullOrWhiteSpace([string]$installation.PreviousHash)) {
        $backupHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $backupPath).Hash
        if ($backupHash -ne [string]$installation.PreviousHash) {
            throw '이전 Korean.pck 백업의 무결성 검사에 실패했습니다.'
        }
    }
}

if (Test-Path -LiteralPath $packPath -PathType Leaf) {
    $currentHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $packPath).Hash
    if ($currentHash -ne $packHash) {
        throw "설치 후 Korean.pck가 변경되어 제거하지 않았습니다: $packPath"
    }
    Remove-Item -LiteralPath $packPath -Force
}

if ([bool]$installation.PreviousExisted) {
    Copy-Item -LiteralPath $backupPath -Destination $packPath
    Write-Host ''
    Write-Host '한국어 모드를 제거하고 이전 Korean.pck를 복원했습니다.' -ForegroundColor Green
} else {
    Write-Host ''
    Write-Host '한국어 모드를 제거했습니다.' -ForegroundColor Green
}
Write-Host "대상 위치: $dataRoot"
Write-Host "설치 기록과 백업은 안전을 위해 남겨 두었습니다: $backupDirectory"
