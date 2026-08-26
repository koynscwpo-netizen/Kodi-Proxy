name: Build

on:
  workflow_dispatch:

permissions:
  contents: read

jobs:
  build:
    name: Build
    runs-on: macos-latest

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Select Xcode
        shell: bash
        run: |
          set -e

          sudo xcode-select -s /Applications/Xcode.app/Contents/Developer

          echo "========================================"
          echo "XCODE"
          echo "========================================"
          xcodebuild -version
          xcodebuild -showsdks

      - name: Locate iPhoneOS SDK
        shell: bash
        run: |
          set -e

          SDK="$(xcrun --sdk iphoneos --show-sdk-path)"

          if [ ! -f "$SDK/System/Library/Frameworks/UIKit.framework/Headers/UIKit.h" ]; then
            echo "UIKit SDK headers not found"
            exit 1
          fi

          echo "IOS_SDK=$SDK" >> "$GITHUB_ENV"

          echo "========================================"
          echo "IPHONEOS SDK"
          echo "========================================"
          echo "$SDK"

      - name: Locate project
        shell: bash
        run: |
          set -e

          PROJECT_ROOT="$GITHUB_WORKSPACE/FF-CACHE-MANAGER-SOURCE"
          BUILD_PS1="$PROJECT_ROOT/app/ff_manager/build.ps1"

          if [ ! -d "$PROJECT_ROOT" ]; then
            echo "FF-CACHE-MANAGER-SOURCE not found"
            exit 1
          fi

          if [ ! -f "$BUILD_PS1" ]; then
            echo "build.ps1 not found:"
            echo "$BUILD_PS1"
            exit 1
          fi

          RELEASE_DIR="$PROJECT_ROOT/release"
          TOOLS_DIR="$PROJECT_ROOT/app/ff_manager/.tools"

          mkdir -p "$RELEASE_DIR"
          mkdir -p "$TOOLS_DIR"

          echo "PROJECT_ROOT=$PROJECT_ROOT" >> "$GITHUB_ENV"
          echo "BUILD_PS1=$BUILD_PS1" >> "$GITHUB_ENV"
          echo "RELEASE_DIR=$RELEASE_DIR" >> "$GITHUB_ENV"
          echo "TOOLS_DIR=$TOOLS_DIR" >> "$GITHUB_ENV"

          echo "========================================"
          echo "PROJECT"
          echo "========================================"
          echo "$PROJECT_ROOT"
          echo "$BUILD_PS1"

      - name: Install build tools
        shell: bash
        run: |
          set -e

          brew install llvm sevenzip

          LLVM="$(brew --prefix llvm)/bin"

          CLANG="$LLVM/clang"
          STRIP="$LLVM/llvm-strip"
          LIPO="$(xcrun --find lipo)"
          INSTALL_NAME="$(xcrun --find install_name_tool)"
          LD="$(xcrun --find ld)"
          SEVENZIP="$(command -v 7zz)"

          test -x "$CLANG"
          test -x "$STRIP"
          test -x "$LIPO"
          test -x "$INSTALL_NAME"
          test -x "$LD"
          test -x "$SEVENZIP"

          ln -sf "$CLANG" \
            "$TOOLS_DIR/clang.exe"

          ln -sf "$STRIP" \
            "$TOOLS_DIR/llvm-strip.exe"

          ln -sf "$LIPO" \
            "$TOOLS_DIR/llvm-lipo.exe"

          ln -sf "$INSTALL_NAME" \
            "$TOOLS_DIR/llvm-install-name-tool.exe"

          ln -sf "$LD" \
            "$TOOLS_DIR/ld64.lld.exe"

          ln -sf "$SEVENZIP" \
            "$TOOLS_DIR/7z.exe"

          chmod +x "$TOOLS_DIR"/*

          echo "$TOOLS_DIR" >> "$GITHUB_PATH"

          echo "========================================"
          echo "BUILD TOOLS"
          echo "========================================"

          "$TOOLS_DIR/clang.exe" --version
          "$TOOLS_DIR/llvm-strip.exe" --version
          "$TOOLS_DIR/7z.exe" --help >/dev/null

          echo "All build tools ready."

      - name: Install Python dependencies
        shell: bash
        run: |
          set -e

          python3 -m venv "$GITHUB_WORKSPACE/.venv"

          "$GITHUB_WORKSPACE/.venv/bin/python" -m pip install --upgrade pip
          "$GITHUB_WORKSPACE/.venv/bin/python" -m pip install lief Pillow

          echo "PYTHON=$GITHUB_WORKSPACE/.venv/bin/python" >> "$GITHUB_ENV"

          "$GITHUB_WORKSPACE/.venv/bin/python" -c \
            "import lief; from PIL import Image; print('Python dependencies OK')"

      - name: Verify project files
        shell: bash
        run: |
          set -e

          test -f "$BUILD_PS1"
          test -f "$PROJECT_ROOT/app/ff_manager/main.m"
          test -f "$PROJECT_ROOT/app/ff_manager/Info.plist"
          test -f "$PROJECT_ROOT/app/ff_manager/FrameworkInfo.plist"
          test -f "$PROJECT_ROOT/app/ff_manager/protect_bridge.py"
          test -f "$PROJECT_ROOT/app/ff_manager/generate_app_icons.py"
          test -f "$PROJECT_ROOT/app/ff_manager/update_plist_version.py"

          echo "========================================"
          echo "PROJECT FILE CHECK"
          echo "========================================"

          echo "build.ps1 OK"
          echo "main.m OK"
          echo "Info.plist OK"
          echo "FrameworkInfo.plist OK"
          echo "protect_bridge.py OK"
          echo "generate_app_icons.py OK"
          echo "update_plist_version.py OK"

      - name: Find Filza IPA
        shell: bash
        run: |
          set -e

          FOUND=""

          for FILE in \
            "$PROJECT_ROOT/app/ff_manager/FilzaSlop_1.0.3.ipa" \
            "$PROJECT_ROOT/FilzaSlop_1.0.3.ipa" \
            "$PROJECT_ROOT/inputs/FilzaSlop_1.0.3.ipa" \
            "$GITHUB_WORKSPACE/FilzaSlop_1.0.3.ipa"
          do
            if [ -f "$FILE" ]; then
              FOUND="$FILE"
              break
            fi
          done

          if [ -z "$FOUND" ]; then
            FOUND="$(find "$GITHUB_WORKSPACE" \
              -type f \
              -name "FilzaSlop_1.0.3.ipa" \
              -print -quit)"
          fi

          if [ -z "$FOUND" ]; then
            echo "FilzaSlop_1.0.3.ipa was not found."
            exit 1
          fi

          echo "FILZA_IPA=$FOUND" >> "$GITHUB_ENV"

          echo "========================================"
          echo "FILZA IPA"
          echo "========================================"
          echo "$FOUND"

      - name: Build IPA
        shell: pwsh
        env:
          IOS_SDK: ${{ env.IOS_SDK }}
          FF_TOOLS_ROOT: ${{ env.TOOLS_DIR }}
          PYTHON: ${{ env.PYTHON }}
          FILZA_IPA: ${{ env.FILZA_IPA }}
        run: |
          $ErrorActionPreference = "Stop"

          Write-Host "========================================"
          Write-Host "BUILD IPA"
          Write-Host "========================================"

          Write-Host "Project:"
          Write-Host "${env:PROJECT_ROOT}"

          Write-Host "SDK:"
          Write-Host "${env:IOS_SDK}"

          Write-Host "Tools:"
          Write-Host "${env:FF_TOOLS_ROOT}"

          Write-Host "Filza:"
          Write-Host "${env:FILZA_IPA}"

          if (-not (Test-Path -LiteralPath "${env:BUILD_PS1}")) {
              throw "build.ps1 not found"
          }

          if (-not (Test-Path -LiteralPath "${env:IOS_SDK}")) {
              throw "iPhoneOS SDK not found"
          }

          if (-not (Test-Path -LiteralPath "${env:FILZA_IPA}")) {
              throw "Filza IPA not found"
          }

          New-Item `
            -ItemType Directory `
            -Force `
            -Path "${env:RELEASE_DIR}" | Out-Null

          & pwsh `
            -NoProfile `
            -ExecutionPolicy Bypass `
            -File "${env:BUILD_PS1}" `
            -FilzaIpa "${env:FILZA_IPA}" `
            -Offline `
            -OutputDirectory "${env:RELEASE_DIR}"

          if ($LASTEXITCODE -ne 0) {
              throw "Build failed with exit code $LASTEXITCODE"
          }

          Write-Host "========================================"
          Write-Host "BUILD FINISHED"
          Write-Host "========================================"

      - name: Verify IPA
        shell: bash
        run: |
          set -e

          echo "========================================"
          echo "VERIFY IPA"
          echo "========================================"

          if [ ! -d "$RELEASE_DIR" ]; then
            echo "Release directory not found:"
            echo "$RELEASE_DIR"
            exit 1
          fi

          find "$RELEASE_DIR" -maxdepth 2 -type f -print

          IPA="$(find "$RELEASE_DIR" \
            -maxdepth 2 \
            -type f \
            -name "*.ipa" \
            -print -quit)"

          if [ -z "$IPA" ]; then
            echo "No IPA was generated."
            exit 1
          fi

          echo "========================================"
          echo "IPA FOUND"
          echo "========================================"
          echo "$IPA"

          echo "IPA_PATH=$IPA" >> "$GITHUB_ENV"

      - name: Upload IPA
        uses: actions/upload-artifact@v4
        with:
          name: FF-Cache-Manager-IPA
          path: ${{ env.RELEASE_DIR }}/*.ipa
          if-no-files-found: error
