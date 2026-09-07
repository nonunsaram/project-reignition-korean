[CmdletBinding()]
param(
    [string]$GameDirectory,
    [string]$DataDirectory
)

$ErrorActionPreference = 'Stop'
$expectedPackHash = 'AF4E70DE3844933D10FEEF2B591B2DB59811886FF76DD344C90D48DD661804D2'
$sourcePack = Join-Path $PSScriptRoot 'files\Korean.pck'

function Resolve-DataRoot {
    if (-not [string]::IsNullOrWhiteSpace($DataDirectory)) {
        return [IO.Path]::GetFullPath($DataDirectory.Trim().Trim('"'))
    }

    if (-not [string]::IsNullOrWhiteSpace($GameDirectory)) {
        $candidate = $GameDirectory.Trim().Trim('"')
        if (Test-Path -LiteralPath $candidate -PathType Leaf) {
            $candidate = Split-Path -Parent $candidate
        }
        if (-not (Test-Path -LiteralPath $candidate -PathType Container)) {
            throw "게임 폴더를 찾을 수 없습니다: $candidate"
        }
        $game = (Resolve-Path -LiteralPath $candidate).Path
        if (-not (Test-Path -LiteralPath (Join-Path $game 'Project Reignition.exe') -PathType Leaf)) {
            throw "Project Reignition.exe가 있는 게임 폴더가 아닙니다: $game"
        }
        $saveLocation = Join-Path $game 'saveLocation.txt'
        if (Test-Path -LiteralPath $saveLocation -PathType Leaf) {
            $configured = [IO.File]::ReadAllText($saveLocation).Trim().Trim('"')
            if (-not [string]::IsNullOrWhiteSpace($configured)) {
                if (-not [IO.Path]::IsPathRooted($configured)) {
                    $configured = Join-Path $game $configured
                }
                return [IO.Path]::GetFullPath($configured)
            }
        }
    }

    return Join-Path $env:APPDATA 'Godot\app_userdata\Sonic and the Secret Rings Remake'
}

if (-not (Test-Path -LiteralPath $sourcePack -PathType Leaf)) {
    throw "설치 파일이 빠져 있습니다. ZIP을 모두 압축 해제한 뒤 설치.bat을 실행해 주세요: $sourcePack"
}
if ((Get-FileHash -Algorithm SHA256 -LiteralPath $sourcePack).Hash -ne $expectedPackHash) {
    throw 'Korean.pck 무결성 검사에 실패했습니다. 배포 ZIP을 다시 내려받아 주세요.'
}
if (Get-Process -Name 'Project Reignition' -ErrorAction SilentlyContinue) {
    throw 'Project Reignition을 완전히 종료한 뒤 다시 실행해 주세요.'
}

$dataRoot = Resolve-DataRoot
$languageDirectory = Join-Path $dataRoot 'mods\lang'
$installedPack = Join-Path $languageDirectory 'Korean.pck'
$backupDirectory = Join-Path $dataRoot 'ReignitionKorean_Backup_v0.3'
$manifest = Join-Path $backupDirectory 'installation.json'

New-Item -ItemType Directory -Force -Path $languageDirectory | Out-Null
New-Item -ItemType Directory -Force -Path $backupDirectory | Out-Null

$previousExisted = Test-Path -LiteralPath $installedPack -PathType Leaf
$previousHash = $null
$backupPack = $null
if ($previousExisted) {
    $previousHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $installedPack).Hash
    if ($previousHash -eq $expectedPackHash -and (Test-Path -LiteralPath $manifest -PathType Leaf)) {
        Write-Host ''
        Write-Host '같은 버전의 한국어 모드가 이미 설치되어 있습니다.' -ForegroundColor Green
        Write-Host "설치 위치: $installedPack"
        exit 0
    }
    if ($previousHash -ne $expectedPackHash) {
        $backupPack = Join-Path $backupDirectory "Korean.previous.$previousHash.pck"
        if (-not (Test-Path -LiteralPath $backupPack)) {
            Copy-Item -LiteralPath $installedPack -Destination $backupPack
        }
    }
}

Copy-Item -LiteralPath $sourcePack -Destination $installedPack -Force
if ((Get-FileHash -Algorithm SHA256 -LiteralPath $installedPack).Hash -ne $expectedPackHash) {
    throw '설치 후 Korean.pck 무결성 검사에 실패했습니다.'
}

@{
    InstallerVersion = 'v0.3'
    DataRoot = $dataRoot
    PackPath = $installedPack
    PackHash = $expectedPackHash
    PreviousExisted = [bool]($previousExisted -and $previousHash -ne $expectedPackHash)
    PreviousHash = $previousHash
    BackupPath = $backupPack
} | ConvertTo-Json | Set-Content -LiteralPath $manifest -Encoding UTF8

Write-Host ''
Write-Host '한국어 모드 설치가 완료되었습니다.' -ForegroundColor Green
Write-Host "설치 위치: $installedPack"
Write-Host '게임의 Options > Mods에서 Language Mods를 켜고 재시작한 뒤,'
Write-Host 'Options > Language > Text Language에서 한국어를 선택해 주세요.'
