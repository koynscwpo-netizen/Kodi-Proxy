param(
    [string]$FilzaIpa,
    [switch]$Offline = $true,
    [string]$OutputDirectory
)

$ErrorActionPreference = "Stop"
$BrandOwner = "@KOD1BATI"
$BrandChannel = "https://t.me/k0dibabi"
$MainSourceForBrandCheck = Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) "main.m"
$MainBrandText = Get-Content -LiteralPath $MainSourceForBrandCheck -Raw
if (-not $MainBrandText.Contains($BrandOwner) -or -not $MainBrandText.Contains($BrandChannel)) {
    throw "Official brand identity is missing or modified."
}

$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
if ([string]::IsNullOrWhiteSpace($OutputDirectory)) {
    $OutputDirectory = Join-Path $Root "release"
}
$OutputDirectory = [System.IO.Path]::GetFullPath($OutputDirectory)
$ToolsRoot = if ($env:FF_TOOLS_ROOT) { $env:FF_TOOLS_ROOT } else { Join-Path $Root ".tools" }
$Sdk = if ($env:IOS_SDK) { $env:IOS_SDK } else { Join-Path $Root "iPhoneOS.sdk" }

function Find-Tool([string]$Name) {
    $cmd = Get-Command $Name -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
    if (Test-Path -LiteralPath $ToolsRoot) {
        $found = Get-ChildItem -LiteralPath $ToolsRoot -Recurse -File -Filter $Name -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($found) { return $found.FullName }
    }
    return $null
}

$Clang = Find-Tool "clang.exe"
$Linker = Find-Tool "ld64.lld.exe"
$Lipo = Find-Tool "llvm-lipo.exe"
$InstallNameTool = Find-Tool "llvm-install-name-tool.exe"
$Strip = Find-Tool "llvm-strip.exe"
$Python = if ($env:PYTHON) { $env:PYTHON } else { (Get-Command python -ErrorAction SilentlyContinue).Source }

if ([string]::IsNullOrWhiteSpace($FilzaIpa)) {
    $candidates = @(
        (Join-Path $Root "FilzaSlop_1.0.3.ipa"),
        (Join-Path (Split-Path -Parent (Split-Path -Parent $Root)) "FilzaSlop_1.0.3.ipa"),
        (Join-Path (Split-Path -Parent (Split-Path -Parent $Root)) "inputs\FilzaSlop_1.0.3.ipa")
    )
    $FilzaIpa = $candidates | Where-Object { Test-Path -LiteralPath $_ -PathType Leaf } | Select-Object -First 1
}
$FFCacheManagerBackground = Join-Path $Root "FFCacheManagerBackground.jpg"
$BrandImage = $FFCacheManagerBackground
$Build = Join-Path ([System.IO.Path]::GetTempPath()) ("FFCacheManager-v100-" + [Guid]::NewGuid().ToString("N"))
$Object = Join-Path $Build "main.o"
$SourceFile = Join-Path $Build "main.m"
$Payload = Join-Path $Build "Payload"
$App = Join-Path $Payload "FFCacheManager.app"
$Frameworks = Join-Path $App "Frameworks"
$FrameworkBundle = Join-Path $Frameworks "CoreTelemetry.framework"
$Executable = Join-Path $App "FFCacheManager"
$ProtectedBridge = Join-Path $FrameworkBundle "CoreTelemetry"
$ProtectionMetadata = Join-Path $Build "protected-core.json"
$ProtectedConfig = Join-Path $Build "ProtectedConfig.h"
$IpaBaseName = if ($Offline) { "FFCacheManager-v100-Offline-Unsigned.ipa" } else { "FFCacheManager-v100-Signer-Compatible.ipa" }
$Ipa = Join-Path $Build $IpaBaseName
$ReleaseManifest = Join-Path $Build "FFCacheManager-release-manifest-v100.json"

$Dependencies = [ordered]@{
    "clang.exe" = $Clang
    "ld64.lld.exe" = $Linker
    "llvm-lipo.exe" = $Lipo
    "llvm-install-name-tool.exe" = $InstallNameTool
    "llvm-strip.exe" = $Strip
    "python" = $Python
    "iPhoneOS.sdk" = $Sdk
    "FilzaSlop_1.0.3.ipa" = $FilzaIpa
    "FFCacheManagerBackground.jpg" = $FFCacheManagerBackground
}
foreach ($entry in $Dependencies.GetEnumerator()) {
    if ([string]::IsNullOrWhiteSpace([string]$entry.Value) -or -not (Test-Path -LiteralPath $entry.Value)) {
        throw "Missing build dependency: $($entry.Key). Run .\SETUP-WINDOWS.ps1 -CheckOnly for the expected locations."
    }
}

New-Item -ItemType Directory -Path $FrameworkBundle -Force | Out-Null
$SevenZip = (Get-Command 7z.exe -ErrorAction SilentlyContinue).Source
if (-not $SevenZip) {
    $SevenZipDefault = "C:\Program Files\7-Zip\7z.exe"
    if (Test-Path -LiteralPath $SevenZipDefault -PathType Leaf) { $SevenZip = $SevenZipDefault }
}
if (-not $SevenZip) { throw "Missing 7-Zip (7z.exe). Install 7-Zip or add it to PATH." }
& $SevenZip e -y "-o$Build" $FilzaIpa "Payload/Filza.app/Frameworks/FilzaApplySandboxExt.dylib" | Out-Null
if ($LASTEXITCODE -ne 0) { throw "Could not extract Filza sandbox bridge ($LASTEXITCODE)" }
$SandboxBridge = Join-Path $Build "FilzaApplySandboxExt.dylib"
if (-not (Test-Path -LiteralPath $SandboxBridge -PathType Leaf)) { throw "Sandbox bridge missing after extraction" }

& $Strip --strip-debug $SandboxBridge
if ($LASTEXITCODE -ne 0) { throw "Debug-symbol stripping failed ($LASTEXITCODE)" }

& $InstallNameTool -id "@rpath/CoreTelemetry.framework/CoreTelemetry" $SandboxBridge
if ($LASTEXITCODE -ne 0) { throw "Bridge install-name protection failed ($LASTEXITCODE)" }

& $Python (Join-Path $Root "protect_bridge.py") $SandboxBridge $ProtectedBridge $ProtectionMetadata
if ($LASTEXITCODE -ne 0) { throw "Bridge export protection failed ($LASTEXITCODE)" }
Remove-Item -LiteralPath $SandboxBridge -Force

$metadata = Get-Content -LiteralPath $ProtectionMetadata -Raw | ConvertFrom-Json
if ($metadata.slices.Count -ne 2) { throw "Expected two protected core integrity records" }
$config = @"
#define FMCORE_TEXT_SHA256_A @"$($metadata.slices[0].text_sha256)"
#define FMCORE_EXPORT_SHA256_A @"$($metadata.slices[0].export_sha256)"
#define FMCORE_SECTION_SHA256_A @"$($metadata.slices[0].section_sha256)"
#define FMCORE_TEXT_SHA256_B @"$($metadata.slices[1].text_sha256)"
#define FMCORE_EXPORT_SHA256_B @"$($metadata.slices[1].export_sha256)"
#define FMCORE_SECTION_SHA256_B @"$($metadata.slices[1].section_sha256)"
"@
[System.IO.File]::WriteAllText($ProtectedConfig, $config, [System.Text.UTF8Encoding]::new($false))

Copy-Item -LiteralPath (Join-Path $Root "main.m") -Destination $SourceFile -Force

$ClangArgs = @(
    "-arch","arm64","-target","arm64-apple-ios15.0","-isysroot",$Sdk,
    "-fobjc-arc","-Os","-fstack-protector-strong","-fvisibility=hidden","-fomit-frame-pointer","-fno-ident",
    "-Werror","-Wno-deprecated-declarations"
)
if ($Offline) { $ClangArgs += "-DFM_OFFLINE_BUILD=1" }
$ClangArgs += "-DFM_RELEASE_BUILD=1"
$ClangArgs += "-DFM_REQUIRE_SIGNED_RESPONSES=1"
$ClangArgs += @("-I",$Build,"-c",$SourceFile,"-o",$Object)
& $Clang @ClangArgs
if ($LASTEXITCODE -ne 0) { throw "Compile failed ($LASTEXITCODE)" }

& $Linker -arch arm64 -platform_version ios 15.0 15.0 -syslibroot $Sdk `
    -e _main -adhoc_codesign -dead_strip $Object `
    -framework UIKit -framework Foundation -framework CoreGraphics -framework QuartzCore -framework Security `
    -framework UniformTypeIdentifiers -lobjc -lSystem -o $Executable
if ($LASTEXITCODE -ne 0) { throw "Link failed ($LASTEXITCODE)" }

& $Strip -x $Executable
if ($LASTEXITCODE -ne 0) { throw "Application symbol stripping failed ($LASTEXITCODE)" }

$AppInfoPath = Join-Path $App "Info.plist"
Copy-Item -LiteralPath (Join-Path $Root "Info.plist") -Destination $AppInfoPath -Force
Copy-Item -LiteralPath $FFCacheManagerBackground -Destination (Join-Path $App "FFCacheManagerBackground.jpg") -Force
if ($Offline) {
    & $Python (Join-Path $Root "update_plist_version.py") $AppInfoPath "1.0" "1"
    if ($LASTEXITCODE -ne 0) { throw "Canonical Info.plist generation failed ($LASTEXITCODE)" }
}
Copy-Item -LiteralPath (Join-Path $Root "FrameworkInfo.plist") -Destination (Join-Path $FrameworkBundle "Info.plist") -Force

$IconSource = if ($BrandImage -and (Test-Path -LiteralPath $BrandImage -PathType Leaf)) { $BrandImage } else { "--fallback" }
& $Python (Join-Path $Root "generate_app_icons.py") $IconSource $App
if ($LASTEXITCODE -ne 0) { throw "Application icon generation failed ($LASTEXITCODE)" }
if ($IconSource -eq "--fallback") {
    Write-Output "[branding] Generated the built-in FF Cache Manager launcher icon."
}

if ($Offline) {
    $OfflineSource = Join-Path $Root "resources\offline"
    $CacheBody = Join-Path $OfflineSource "BODY.ffcache"
    $CacheNeck = Join-Path $OfflineSource "NECK.ffcache"
    foreach ($required in @($CacheBody, $CacheNeck)) {
        if (-not (Test-Path -LiteralPath $required -PathType Leaf)) { throw "Missing bundled offline cache file: $required" }
    }
    $OfflineCache = Join-Path $App "OfflineCache"
    New-Item -ItemType Directory -Path $OfflineCache -Force | Out-Null
    $FeatureToSource = @{ BODY = $CacheBody; NECK = $CacheNeck }
    foreach ($feature in $FeatureToSource.Keys) {
        # Keep the canonical OfflineCache copy and a root-level fallback. Some
        # third-party signing/repacking tools can alter resource subdirectories.
        Copy-Item -LiteralPath $FeatureToSource[$feature] -Destination (Join-Path $OfflineCache "$feature.ffcache") -Force
        Copy-Item -LiteralPath $FeatureToSource[$feature] -Destination (Join-Path $App "$feature.ffcache") -Force
    }
    Write-Output "[offline] bundled local profiles: BODY, NECK (OfflineCache + root fallback)"
}

Push-Location $Build
try {
    & $SevenZip a -tzip -mx=9 $Ipa "Payload" | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "IPA packaging failed ($LASTEXITCODE)" }
} finally {
    Pop-Location
}

if (-not $Offline) {
    & $Python (Join-Path $Root "generate_release_manifest.py") $App $ReleaseManifest
    if ($LASTEXITCODE -ne 0) { throw "Release manifest generation failed ($LASTEXITCODE)" }

    & $Python (Join-Path $Root "verify_build.py") $Build
    if ($LASTEXITCODE -ne 0) { throw "Security verification failed ($LASTEXITCODE)" }

    # Publish only the verified pair.  The manifest is generated from this
    # exact app bundle and is retained only for non-offline compatibility.
    New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
    $PublishedIpa = Join-Path $OutputDirectory $IpaBaseName
    $PublishedManifest = Join-Path $OutputDirectory "FFCacheManager-release-manifest-v100.json"
    $PublishedChecksums = Join-Path $OutputDirectory "FFCacheManager-v100-Signer-Compatible.sha256"
    Copy-Item -LiteralPath $Ipa -Destination $PublishedIpa -Force
    Copy-Item -LiteralPath $ReleaseManifest -Destination $PublishedManifest -Force

    & $Python (Join-Path $Root "verify_build.py") $Build --ipa $PublishedIpa --manifest $PublishedManifest
    if ($LASTEXITCODE -ne 0) { throw "Security verification failed ($LASTEXITCODE)" }

    @(
        "{0} *{1}" -f (Get-FileHash -Algorithm SHA256 -LiteralPath $PublishedIpa).Hash.ToUpperInvariant(), $IpaBaseName
        "{0} *{1}" -f (Get-FileHash -Algorithm SHA256 -LiteralPath $PublishedManifest).Hash.ToUpperInvariant(), "FFCacheManager-release-manifest-v100.json"
    ) | Set-Content -LiteralPath $PublishedChecksums -Encoding ascii
}

& $Lipo -info $Executable
if ($Offline) {
    New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
    $PublishedIpa = Join-Path $OutputDirectory $IpaBaseName
    Copy-Item -LiteralPath $Ipa -Destination $PublishedIpa -Force
    $PublishedChecksum = Join-Path $OutputDirectory ($IpaBaseName + ".sha256")
    ("{0} *{1}" -f (Get-FileHash -Algorithm SHA256 -LiteralPath $PublishedIpa).Hash.ToUpperInvariant(), $IpaBaseName) | Set-Content -LiteralPath $PublishedChecksum -Encoding ascii
    Write-Output "Built unsigned IPA: $PublishedIpa"
    Write-Output "SHA256: $PublishedChecksum"
} else {
    Write-Output "Built: $PublishedIpa"
    Write-Output "Release manifest: $PublishedManifest"
    Write-Output "Checksums: $PublishedChecksums"
}
