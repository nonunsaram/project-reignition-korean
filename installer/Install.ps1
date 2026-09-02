[CmdletBinding()]
param([string]$GameDirectory)

$ErrorActionPreference = "Stop"
$originalDllHash = "EEFBE9FBCFAD5B5EBD2525641A3D5E4CE8894517BEE890762BDEB674C57E1796"
$patchedDllHash = "5477FEE496056D7FB0161214AF8A59FB0C4F2FBADDFA35DF1B752ECEB6AA26F8"
$previousPatchedDllHashes = @(
	"F794ACD6EB253A650FB28CBA898F110FFBAB6502EE120A74FD1666CB92A03FB4",
	"485C8EC012DB6CF2A1F1D7668B3D7BB7A005D9D404A6FA8E3AF19C728150F3C4",
	"988FB2C56F3C5FB845FF447693EF218CF37452BF88937A179167C70AECDC4F06",
	"9544577BF258F03C209EEEFC45AAF4A1B445AD8C13498B5EDF4535F689C631DA",
	"48DCFDC26943EA4D1A13824FDC13579357F71B63E85B88ADC7FB824EA70C0B8B",
	"B631561EBD63622FC47E02F9D1137DFBFDF79B6D66D5ABA289B1DD49D6347DD6",
	"2302A746371F193B9FA6C443528B5C0514876708E75F4E531A3986150B07046A",
	"0AD377F6712DAA15F00A5A72D7B4B26FA744171E481A43A21F6EA6AC54AD99CB",
	"8E773039AA978EC3ECA05DCBCFFF03DEED6D804B7A9FDAB535902EEAA544903F",
	"0AC2FB264F1B8726A4C145B0FE2898C403F8A5DFE0008C3BCC91474AB02A7EB5",
	"BD9EAC2160F2F813FA422961E40693D27D4FA09F9A1975CACF8E557595DE2928",
	"700D9B821C4304EADB0E946270A39DB6AFF5089D20FCA3700D7A0074901CB0BB",
	"219200978A37C3BDCB01D0B9205A0C23DDA612FF0B5E0723DAE80168BB9AF965",
	"4FA7C872D09B9AE2EBBFE10183F848DE7A74FC172BE343CE23CC71A3DB2399A1",
    "28990F4965ACFF4819C3883FB54B89D5CAEFBD0845742E035316ADFB969B4A16",
    "E2778573851F13A5078C929F3A0DB58DBB07193A8D271BFFC1663260591127E4"
)

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
    throw "Project Reignition v1.0.0 게임 폴더가 아닙니다. 'Project Reignition.exe'가 있는 폴더를 지정해 주세요: $game"
}

try {
    $lockTest = [IO.File]::Open($gameDll, [IO.FileMode]::Open, [IO.FileAccess]::ReadWrite, [IO.FileShare]::None)
    $lockTest.Dispose()
} catch {
    throw "Project Reignition을 완전히 종료한 뒤 설치기를 다시 실행해 주세요. 현재 게임 파일이 사용 중입니다."
}

$currentHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $gameDll).Hash
if ($currentHash -ne $originalDllHash -and $currentHash -ne $patchedDllHash -and $previousPatchedDllHashes -notcontains $currentHash) {
    throw "지원하는 Project Reignition v1.0.0 게임 파일과 일치하지 않습니다. 다른 버전이거나 이미 다른 패치로 수정된 파일일 수 있습니다."
}

$backup = Join-Path $game "ReignitionKR_Backup_v1.0.0"
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
    GameDirectory = $game
    PackPath = $installedPack
} | ConvertTo-Json | Set-Content -LiteralPath $manifest -Encoding UTF8

Write-Host ""
Write-Host "한국어 패치 설치가 완료되었습니다." -ForegroundColor Green
Write-Host "게임 폴더: $game"
Write-Host "게임을 실행한 뒤 Options > Language > Text Language에서 Korean을 선택해 주세요."
Write-Host "전체 2,321개 텍스트의 한국어 번역이 포함되어 있습니다."
