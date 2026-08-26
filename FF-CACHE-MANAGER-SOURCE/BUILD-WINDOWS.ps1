[CmdletBinding()]
param(
    [string]$FilzaIpa,
    [string]$IosSdk,
    [string]$OutputDirectory
)

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
$AppRoot = Join-Path $Root "app\ff_manager"
$Builder = Join-Path $AppRoot "build.ps1"

if ($IosSdk) { $env:IOS_SDK = [System.IO.Path]::GetFullPath($IosSdk) }
if ([string]::IsNullOrWhiteSpace($OutputDirectory)) { $OutputDirectory = Join-Path $Root "release" }

Write-Host "NOVA BODY / BODY + NECK - Windows unsigned IPA build"
Write-Host "Owner: @FAKHERDDIN5"
Write-Host "Output: $OutputDirectory"

& $Builder -FilzaIpa $FilzaIpa -Offline -OutputDirectory $OutputDirectory
if ($LASTEXITCODE -ne 0) { throw "Build failed with exit code $LASTEXITCODE" }
