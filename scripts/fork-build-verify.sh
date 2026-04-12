#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

SCHEME="${CMUX_BUILD_SCHEME:-cmux}"
CONFIGURATION="${CMUX_BUILD_CONFIGURATION:-Debug}"
DESTINATION="${CMUX_BUILD_DESTINATION:-platform=macOS}"
DERIVED_DATA_PATH="${CMUX_DERIVED_DATA_PATH:-$REPO_ROOT/.build/xcode-derived}"
SOURCE_PACKAGES_DIR="${CMUX_SOURCE_PACKAGES_DIR:-$REPO_ROOT/.build/swiftpm}"

select_xcode() {
  if [[ -n "${DEVELOPER_DIR:-}" ]]; then
    return
  fi

  if [[ -d "/Applications/Xcode.app/Contents/Developer" ]]; then
    export DEVELOPER_DIR="/Applications/Xcode.app/Contents/Developer"
    return
  fi

  local xcode_app
  xcode_app="$(
    find /Applications -maxdepth 1 -name 'Xcode*.app' -type d 2>/dev/null \
      | sort \
      | tail -n 1
  )"

  if [[ -n "$xcode_app" && -d "$xcode_app/Contents/Developer" ]]; then
    export DEVELOPER_DIR="$xcode_app/Contents/Developer"
  fi
}

cd "$REPO_ROOT"

select_xcode

if ! XCODE_VERSION_OUTPUT="$(xcodebuild -version 2>&1)"; then
  echo "$XCODE_VERSION_OUTPUT" >&2
  echo "Full Xcode is required to build cmux. CommandLineTools alone is not enough." >&2
  exit 1
fi

echo "$XCODE_VERSION_OUTPUT"
echo "Using DEVELOPER_DIR=${DEVELOPER_DIR:-$(xcode-select -p 2>/dev/null || echo unset)}"

git submodule update --init --recursive

if [[ ! -d "GhosttyKit.xcframework" ]]; then
  ./scripts/download-prebuilt-ghosttykit.sh
fi

mkdir -p "$DERIVED_DATA_PATH" "$SOURCE_PACKAGES_DIR"

xcodebuild \
  -project GhosttyTabs.xcodeproj \
  -scheme "$SCHEME" \
  -configuration "$CONFIGURATION" \
  -clonedSourcePackagesDirPath "$SOURCE_PACKAGES_DIR" \
  -resolvePackageDependencies

CMUX_SKIP_ZIG_BUILD="${CMUX_SKIP_ZIG_BUILD:-1}" xcodebuild \
  -project GhosttyTabs.xcodeproj \
  -scheme "$SCHEME" \
  -configuration "$CONFIGURATION" \
  -clonedSourcePackagesDirPath "$SOURCE_PACKAGES_DIR" \
  -disableAutomaticPackageResolution \
  -destination "$DESTINATION" \
  -derivedDataPath "$DERIVED_DATA_PATH" \
  CODE_SIGNING_ALLOWED=NO \
  build

APP_PATH="$DERIVED_DATA_PATH/Build/Products/$CONFIGURATION/cmux.app"
test -d "$APP_PATH"

echo "Build verified: $APP_PATH"
