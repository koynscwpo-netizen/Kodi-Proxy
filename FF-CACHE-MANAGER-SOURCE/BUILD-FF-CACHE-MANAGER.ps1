[CmdletBinding()]
param(
    [string]$FilzaIpa,
    [switch]$Offline = $true,
    [string]$OutputDirectory,
    [string]$IosSdk
)
$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
& (Join-Path $Root "BUILD-WINDOWS.ps1") -FilzaIpa $FilzaIpa -IosSdk $IosSdk -OutputDirectory $OutputDirectory
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
