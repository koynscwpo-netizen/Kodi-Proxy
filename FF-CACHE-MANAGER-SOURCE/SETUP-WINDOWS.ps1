[CmdletBinding()]
param([switch]$CheckOnly)
$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
$AppRoot = Join-Path $Root "app\ff_manager"
$ToolsRoot = Join-Path $AppRoot ".tools"
$SdkDefault = Join-Path $AppRoot "iPhoneOS.sdk"
$FilzaDefault = Join-Path $Root "inputs\FilzaSlop_1.0.3.ipa"

function Status($Name, $Ok, $Hint) {
    if ($Ok) { Write-Host "[OK]   $Name" } else { Write-Host "[MISS] $Name - $Hint" }
}

Write-Host "NOVA BODY - Windows build environment check"
Write-Host ""
$py = Get-Command python -ErrorAction SilentlyContinue
$seven = Get-Command 7z.exe -ErrorAction SilentlyContinue
if (-not $seven -and (Test-Path "C:\Program Files\7-Zip\7z.exe")) { $seven = Get-Item "C:\Program Files\7-Zip\7z.exe" }

$needed = @("clang.exe","ld64.lld.exe","llvm-lipo.exe","llvm-install-name-tool.exe","llvm-strip.exe")
$toolOk = $true
foreach ($n in $needed) {
    $cmd = Get-Command $n -ErrorAction SilentlyContinue
    if (-not $cmd -and (Test-Path $ToolsRoot)) { $cmd = Get-ChildItem $ToolsRoot -Recurse -File -Filter $n -ErrorAction SilentlyContinue | Select-Object -First 1 }
    $ok = [bool]$cmd; if (-not $ok) { $toolOk = $false }
    Status $n $ok "put an LLVM/ld64 toolchain under app\ff_manager\.tools or add it to PATH"
}

Status "Python 3" ([bool]$py) "install Python 3 and enable Add Python to PATH"
Status "7-Zip" ([bool]$seven) "install 7-Zip"
$sdkPath = if ($env:IOS_SDK) { $env:IOS_SDK } else { $SdkDefault }
Status "iPhoneOS.sdk" (Test-Path $sdkPath) "copy your legally obtained iPhoneOS.sdk to app\ff_manager\iPhoneOS.sdk or set IOS_SDK"
Status "Filza input IPA" (Test-Path $FilzaDefault) "place FilzaSlop_1.0.3.ipa in inputs\ or pass -FilzaIpa to BUILD-WINDOWS.ps1"

Write-Host ""
Write-Host "Build command:"
Write-Host "  powershell -ExecutionPolicy Bypass -File .\BUILD-WINDOWS.ps1"
Write-Host ""
Write-Host "Or with explicit inputs:"
Write-Host "  powershell -ExecutionPolicy Bypass -File .\BUILD-WINDOWS.ps1 -FilzaIpa 'C:\path\FilzaSlop_1.0.3.ipa' -IosSdk 'C:\path\iPhoneOS.sdk'"
