param(
    [string]$FilzaIpa,
    [switch]$Offline = $true,
    [string]$OutputDirectory
)

$ErrorActionPreference = "Stop"

$Root = Split-Path -Parent $MyInvocation.MyCommand.Path

if ([string]::IsNullOrWhiteSpace($OutputDirectory)) {
    $OutputDirectory = Join-Path $Root "release"
}

$OutputDirectory = [System.IO.Path]::GetFullPath($OutputDirectory)

$ToolsRoot = if ($env:FF_TOOLS_ROOT) {
    $env:FF_TOOLS_ROOT
} else {
    Join-Path $Root ".tools"
}

$Sdk = if ($env:IOS_SDK) {
    $env:IOS_SDK
} else {
    Join-Path $Root "iPhoneOS.sdk"
}

Write-Host "=============================================="
Write-Host "NOVA BODY / BODY + NECK - Windows unsigned IPA build"
Write-Host "=============================================="
Write-Host "Output: $OutputDirectory"
Write-Host "SDK:    $Sdk"
Write-Host ""

function Find-Tool([string]$Name) {
    $cmd = Get-Command $Name -ErrorAction SilentlyContinue

    if ($cmd) {
        return $cmd.Source
    }

    $local = Join-Path $ToolsRoot $Name

    if (Test-Path $local) {
        return $local
    }

    return $null
}

$Clang = Find-Tool "clang.exe"
$Ld64 = Find-Tool "ld64.lld.exe"
$Lipo = Find-Tool "llvm-lipo.exe"
$InstallNameTool = Find-Tool "llvm-install-name-tool.exe"
$Strip = Find-Tool "llvm-strip.exe"
$SevenZip = Find-Tool "7z.exe"

Write-Host "Checking build tools..."

if (-not $Clang) {
    throw "clang.exe not found."
}

if (-not $Ld64) {
    throw "ld64.lld.exe not found."
}

if (-not $Lipo) {
    throw "llvm-lipo.exe not found."
}

if (-not $InstallNameTool) {
    throw "llvm-install-name-tool.exe not found."
}

if (-not $Strip) {
    throw "llvm-strip.exe not found."
}

if (-not $SevenZip) {
    throw "7z.exe not found."
}

Write-Host "clang.exe found."
Write-Host "ld64.lld.exe found."
Write-Host "llvm-lipo.exe found."
Write-Host "llvm-install-name-tool.exe found."
Write-Host "llvm-strip.exe found."
Write-Host "7z.exe found."
Write-Host ""

if (-not (Test-Path $Sdk)) {
    throw "iPhoneOS SDK not found: $Sdk"
}

Write-Host "iPhoneOS SDK found."
Write-Host ""

if (-not [string]::IsNullOrWhiteSpace($FilzaIpa)) {
    if (-not (Test-Path $FilzaIpa)) {
        throw "Filza IPA not found: $FilzaIpa"
    }

    Write-Host "Filza IPA: $FilzaIpa"
}

New-Item -ItemType Directory -Force -Path $OutputDirectory | Out-Null

Write-Host ""
Write-Host "=============================================="
Write-Host "START BUILD"
Write-Host "=============================================="

# Run the existing project build script.
# The existing build.ps1 logic below this point is intentionally
# delegated to the project's current build pipeline.

$ProjectBuild = Join-Path $Root "BUILD-WINDOWS.ps1"

if (Test-Path $ProjectBuild) {
    Write-Host "Running project build pipeline..."
    & $ProjectBuild `
        -FilzaIpa $FilzaIpa `
        -IosSdk $Sdk `
        -OutputDirectory $OutputDirectory

    if ($LASTEXITCODE -ne 0) {
        throw "Build failed with exit code $LASTEXITCODE"
    }
}
else {
    Write-Host "BUILD-WINDOWS.ps1 not found."
    Write-Host "Build tools and SDK checks completed."
}

Write-Host ""
Write-Host "=============================================="
Write-Host "BUILD FINISHED"
Write-Host "=============================================="
Write-Host "Output: $OutputDirectory"
