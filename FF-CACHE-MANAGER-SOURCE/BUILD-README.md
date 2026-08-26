# NOVA BODY — Windows unsigned IPA build

This source contains only BODY + NECK and keeps the official attribution **@FAKHERDDIN5** and channel link **https://t.me/+yzTUmx4f-ck5N2M0**. The build output is an **unsigned IPA**; no Apple Developer certificate is required for the build step itself. Installation still requires an iOS-compatible signing/install method.

## Windows requirements

1. Windows 10/11 x64.
2. PowerShell 5.1 or newer.
3. Python 3 in PATH.
4. 7-Zip.
5. LLVM/ld64 tools containing `clang.exe`, `ld64.lld.exe`, `llvm-lipo.exe`, `llvm-install-name-tool.exe`, and `llvm-strip.exe`. Put them anywhere under `app\ff_manager\.tools\` or add them to PATH.
6. A legally obtained Apple `iPhoneOS.sdk`. Put it at `app\ff_manager\iPhoneOS.sdk\` or set `IOS_SDK`.
7. `FilzaSlop_1.0.3.ipa`, because this source extracts the sandbox bridge used by the existing project. Put it in `inputs\FilzaSlop_1.0.3.ipa` or pass its path to the build command.

## Check dependencies

```powershell
powershell -ExecutionPolicy Bypass -File .\SETUP-WINDOWS.ps1 -CheckOnly
```

## Build

```powershell
powershell -ExecutionPolicy Bypass -File .\BUILD-WINDOWS.ps1
```

Or pass the two external inputs explicitly:

```powershell
powershell -ExecutionPolicy Bypass -File .\BUILD-WINDOWS.ps1 `
  -FilzaIpa "C:\path\FilzaSlop_1.0.3.ipa" `
  -IosSdk "C:\path\iPhoneOS.sdk"
```

The resulting IPA is written to `release\FFCacheManager-v100-Offline-Unsigned.ipa`, together with a SHA-256 file.

## Important

PowerShell is only the build driver. Compiling an iOS Mach-O on Windows still requires an iOS-capable clang/ld64 toolchain and Apple SDK headers/libraries. Those Apple SDK files are not redistributed in this archive.
