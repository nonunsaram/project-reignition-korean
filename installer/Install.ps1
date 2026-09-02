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
    $candidate = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot "..\..\Project Reignition - Windows v1.0.0"))
    if (Test-Path -LiteralPath (Join-Path $candidate "Project Reignition.exe")) {
        $GameDirectory = $candidate
    } else {
        $GameDirectory = Read-Host "Paste the game folder containing Project Reignition.exe"
    }
}

$game = (Resolve-Path -LiteralPath $GameDirectory).Path
$gameExe = Join-Path $game "Project Reignition.exe"
$managed = Join-Path $game "data_Sonic Remake Project_windows_x86_64"
$gameDll = Join-Path $managed "Sonic Remake Project.dll"
$gamePdb = Join-Path $managed "Sonic Remake Project.pdb"
if (!(Test-Path -LiteralPath $gameExe) -or !(Test-Path -LiteralPath $gameDll)) {
    throw "This is not a Project Reignition v1.0.0 game folder: $game"
}

try {
    $lockTest = [IO.File]::Open($gameDll, [IO.FileMode]::Open, [IO.FileAccess]::ReadWrite, [IO.FileShare]::None)
    $lockTest.Dispose()
} catch {
    throw "Close Project Reignition completely, then run the installer again. The game DLL is currently in use."
}

$currentHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $gameDll).Hash
if ($currentHash -ne $originalDllHash -and $currentHash -ne $patchedDllHash -and $previousPatchedDllHashes -notcontains $currentHash) {
    throw "The game DLL does not match supported Project Reignition v1.0.0. It may be another version or already modified."
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
Write-Host "Installation completed." -ForegroundColor Green
Write-Host "In Options, set Text Language to Korean. This release includes the complete Korean translation for all 2,321 text entries."
