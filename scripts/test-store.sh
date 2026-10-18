#!/bin/zsh
set -euo pipefail

ROOT_DIR="${0:A:h:h}"
BUILD_DIR="$ROOT_DIR/.build/store-tests"
mkdir -p "$BUILD_DIR"

if [[ -z "${SDKROOT:-}" ]]; then
    if [[ "$(xcode-select -p)" == "/Library/Developer/CommandLineTools" && -d "/Library/Developer/CommandLineTools/SDKs/MacOSX26.5.sdk" ]]; then
        export SDKROOT="/Library/Developer/CommandLineTools/SDKs/MacOSX26.5.sdk"
    else
        export SDKROOT="$(xcrun --show-sdk-path)"
    fi
fi

swiftc -parse-as-library -sdk "$SDKROOT" \
    -module-cache-path "$BUILD_DIR/ModuleCache" \
    "$ROOT_DIR/Sources/Menuminder/TodoItem.swift" \
    "$ROOT_DIR/Sources/Menuminder/TodoStore.swift" \
    "$ROOT_DIR/Tests/StoreSmoke.swift" \
    -o "$BUILD_DIR/StoreSmoke"
"$BUILD_DIR/StoreSmoke"
