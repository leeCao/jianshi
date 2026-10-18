#!/bin/zsh
set -euo pipefail

ROOT_DIR="${0:A:h:h}"
BUILD_DIR="$ROOT_DIR/.build"
APP_DIR="$ROOT_DIR/dist/笺事.app"
CONFIGURATION="${CONFIGURATION:-release}"

cd "$ROOT_DIR"

export CLANG_MODULE_CACHE_PATH="$BUILD_DIR/ModuleCache"
export SWIFTPM_MODULECACHE_OVERRIDE="$BUILD_DIR/ModuleCache"

# Some Command Line Tools-only installations retain a mismatched default SDK
# after an OS update. Prefer a compatible installed SDK in that specific case.
if [[ "$(xcode-select -p)" == "/Library/Developer/CommandLineTools" ]]; then
    if [[ -d "/Library/Developer/CommandLineTools/SDKs/MacOSX26.5.sdk" ]]; then
        export SDKROOT="/Library/Developer/CommandLineTools/SDKs/MacOSX26.5.sdk"
    elif [[ -d "/Library/Developer/CommandLineTools/SDKs/MacOSX13.3.sdk" ]]; then
        export SDKROOT="/Library/Developer/CommandLineTools/SDKs/MacOSX13.3.sdk"
    fi
fi

swift build -c "$CONFIGURATION" --disable-sandbox --build-system native -debug-info-format none

stage_dir="$(mktemp -d "$BUILD_DIR/app-stage.XXXXXX")"
trap 'rm -rf "$stage_dir"' EXIT
staged_app="$stage_dir/笺事.app"
mkdir -p "$staged_app/Contents/MacOS" "$staged_app/Contents/Resources/Menuminder_Menuminder.bundle"
cp "$BUILD_DIR/$CONFIGURATION/Menuminder" "$staged_app/Contents/MacOS/Menuminder"
# Copy the current source assets, so removed resources cannot survive incremental builds.
cp -R "$ROOT_DIR/Sources/Menuminder/Assets" "$staged_app/Contents/Resources/Menuminder_Menuminder.bundle/"
cp "$ROOT_DIR/Resources/Info.plist" "$staged_app/Contents/Info.plist"
cp "$ROOT_DIR/Resources/Jianshi.icns" "$staged_app/Contents/Resources/Jianshi.icns"
cp "$ROOT_DIR/Resources/Lucide-LICENSE.txt" "$staged_app/Contents/Resources/Lucide-LICENSE.txt"
chmod +x "$staged_app/Contents/MacOS/Menuminder"
chmod -R a+rX "$staged_app"

codesign --force --deep --sign - "$staged_app"
mkdir -p "$ROOT_DIR/dist"
if [[ -d "$APP_DIR" ]]; then
    mv "$APP_DIR" "$stage_dir/previous.app"
fi
mv "$staged_app" "$APP_DIR"
echo "Built: $APP_DIR"
