#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

APP_NAME="${CMUX_LOW_COST_APP_NAME:-cmux_improve}"
BUNDLE_ID="${CMUX_LOW_COST_BUNDLE_ID:-com.cmuxterm.app.debug.cmux.improve}"
SCHEME="${CMUX_BUILD_SCHEME:-cmux}"
CONFIGURATION="${CMUX_BUILD_CONFIGURATION:-Release}"
DESTINATION="${CMUX_BUILD_DESTINATION:-generic/platform=macOS}"
DERIVED_DATA_PATH="${CMUX_DERIVED_DATA_PATH:-$REPO_ROOT/.build/xcode-release}"
SOURCE_PACKAGES_DIR="${CMUX_SOURCE_PACKAGES_DIR:-$REPO_ROOT/.build/swiftpm-release}"
ARTIFACTS_DIR="${CMUX_ARTIFACTS_DIR:-$REPO_ROOT/.build/artifacts/cmux_improve_release}"

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

plist_set_or_add() {
  local plist="$1"
  local key="$2"
  local type="$3"
  local value="$4"

  /usr/libexec/PlistBuddy -c "Set :${key} ${value}" "$plist" >/dev/null 2>&1 \
    || /usr/libexec/PlistBuddy -c "Add :${key} ${type} ${value}" "$plist" >/dev/null
}

plist_set_bool_or_add() {
  local plist="$1"
  local key="$2"
  local value="$3"

  /usr/libexec/PlistBuddy -c "Set :${key} ${value}" "$plist" >/dev/null 2>&1 \
    || /usr/libexec/PlistBuddy -c "Add :${key} bool ${value}" "$plist" >/dev/null
}

sanitize_socket_slug() {
  echo "$1" \
    | tr '[:upper:]' '[:lower:]' \
    | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//; s/-+/-/g'
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

mkdir -p "$DERIVED_DATA_PATH" "$SOURCE_PACKAGES_DIR" "$ARTIFACTS_DIR"

xcodebuild \
  -project GhosttyTabs.xcodeproj \
  -scheme "$SCHEME" \
  -configuration "$CONFIGURATION" \
  -clonedSourcePackagesDirPath "$SOURCE_PACKAGES_DIR" \
  -resolvePackageDependencies

CMUX_SKIP_ZIG_BUILD="${CMUX_SKIP_ZIG_BUILD:-0}" xcodebuild \
  -project GhosttyTabs.xcodeproj \
  -scheme "$SCHEME" \
  -configuration "$CONFIGURATION" \
  -clonedSourcePackagesDirPath "$SOURCE_PACKAGES_DIR" \
  -disableAutomaticPackageResolution \
  -destination "$DESTINATION" \
  -derivedDataPath "$DERIVED_DATA_PATH" \
  ARCHS="arm64 x86_64" \
  ONLY_ACTIVE_ARCH=NO \
  CODE_SIGNING_ALLOWED=NO \
  build

PRODUCTS_DIR="$DERIVED_DATA_PATH/Build/Products/$CONFIGURATION"
BASE_APP_PATH="$PRODUCTS_DIR/cmux.app"
PACKAGE_APP_PATH="$PRODUCTS_DIR/${APP_NAME}.app"

if [[ ! -d "$BASE_APP_PATH" ]]; then
  echo "Build completed, but $BASE_APP_PATH was not found" >&2
  exit 1
fi

rm -rf "$PACKAGE_APP_PATH"
ditto "$BASE_APP_PATH" "$PACKAGE_APP_PATH"

INFO_PLIST="$PACKAGE_APP_PATH/Contents/Info.plist"
if [[ ! -f "$INFO_PLIST" ]]; then
  echo "Missing Info.plist at $INFO_PLIST" >&2
  exit 1
fi

BASE_MARKETING_VERSION="$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$INFO_PLIST" 2>/dev/null || echo "0.0.0")"
if [[ -n "${GITHUB_RUN_ID:-}" ]]; then
  RUN_ATTEMPT="$(printf '%02d' "${GITHUB_RUN_ATTEMPT:-1}")"
  BUILD_NUMBER="${CMUX_LOW_COST_BUILD_NUMBER:-${GITHUB_RUN_ID}${RUN_ATTEMPT}}"
else
  BUILD_NUMBER="${CMUX_LOW_COST_BUILD_NUMBER:-$(date -u +%Y%m%d%H%M%S)}"
fi
MARKETING_VERSION="${CMUX_LOW_COST_MARKETING_VERSION:-${BASE_MARKETING_VERSION}-improve.${BUILD_NUMBER}}"
SHORT_SHA="$(git rev-parse --short=9 HEAD 2>/dev/null || true)"

plist_set_or_add "$INFO_PLIST" "CFBundleName" "string" "$APP_NAME"
plist_set_or_add "$INFO_PLIST" "CFBundleDisplayName" "string" "$APP_NAME"
plist_set_or_add "$INFO_PLIST" "CFBundleIdentifier" "string" "$BUNDLE_ID"
plist_set_or_add "$INFO_PLIST" "CFBundleShortVersionString" "string" "$MARKETING_VERSION"
plist_set_or_add "$INFO_PLIST" "CFBundleVersion" "string" "$BUILD_NUMBER"
if [[ -n "$SHORT_SHA" ]]; then
  plist_set_or_add "$INFO_PLIST" "CMUXCommit" "string" "$SHORT_SHA"
fi

# This package is intentionally unsigned/not notarized, so disable Sparkle
# metadata that points at upstream release feeds.
/usr/libexec/PlistBuddy -c "Delete :SUPublicEDKey" "$INFO_PLIST" >/dev/null 2>&1 || true
/usr/libexec/PlistBuddy -c "Delete :SUFeedURL" "$INFO_PLIST" >/dev/null 2>&1 || true
plist_set_bool_or_add "$INFO_PLIST" "SUEnableAutomaticChecks" "false"
plist_set_bool_or_add "$INFO_PLIST" "SUAutomaticallyUpdate" "false"

ENTITLEMENTS="$REPO_ROOT/cmux.entitlements"
CLI_PATH="$PACKAGE_APP_PATH/Contents/Resources/bin/cmux"
HELPER_PATH="$PACKAGE_APP_PATH/Contents/Resources/bin/ghostty"
if [[ -f "$CLI_PATH" ]]; then
  /usr/bin/codesign --force --options runtime --timestamp=none --sign - --entitlements "$ENTITLEMENTS" "$CLI_PATH"
fi
if [[ -f "$HELPER_PATH" ]]; then
  /usr/bin/codesign --force --options runtime --timestamp=none --sign - --entitlements "$ENTITLEMENTS" "$HELPER_PATH"
fi
/usr/bin/codesign --force --options runtime --timestamp=none --sign - --entitlements "$ENTITLEMENTS" --deep "$PACKAGE_APP_PATH"
/usr/bin/codesign --verify --deep --strict --verbose=2 "$PACKAGE_APP_PATH"

rm -rf "$ARTIFACTS_DIR"
mkdir -p "$ARTIFACTS_DIR"

APP_ZIP="$ARTIFACTS_DIR/${APP_NAME}-app.zip"
PACKAGE_ROOT="$ARTIFACTS_DIR/${APP_NAME}"
DMG_ROOT="$ARTIFACTS_DIR/dmg-root"
DMG_PATH="$ARTIFACTS_DIR/${APP_NAME}.dmg"
PACKAGE_ZIP="$ARTIFACTS_DIR/${APP_NAME}-low-cost.zip"
METADATA_PATH="$ARTIFACTS_DIR/metadata.env"

rm -rf "$PACKAGE_ROOT" "$DMG_ROOT"
mkdir -p "$PACKAGE_ROOT" "$DMG_ROOT"

ditto "$PACKAGE_APP_PATH" "$PACKAGE_ROOT/${APP_NAME}.app"
cat > "$PACKAGE_ROOT/README.txt" <<EOF
${APP_NAME}

This is a low-cost Release build for local testing.

- Build configuration: ${CONFIGURATION}
- Bundle identifier: ${BUNDLE_ID}
- Marketing version: ${MARKETING_VERSION}
- Build number: ${BUILD_NUMBER}
- Commit: ${SHORT_SHA:-unknown}
- Code signing: ad-hoc
- Apple notarization: no

If macOS blocks the app because it was downloaded from the internet, use
Right Click > Open. If needed, remove quarantine with:

  xattr -dr com.apple.quarantine ${APP_NAME}.app
EOF

ditto -c -k --sequesterRsrc --keepParent "$PACKAGE_APP_PATH" "$APP_ZIP"
ditto -c -k --sequesterRsrc "$PACKAGE_ROOT" "$PACKAGE_ZIP"

ditto "$PACKAGE_APP_PATH" "$DMG_ROOT/${APP_NAME}.app"
ln -s /Applications "$DMG_ROOT/Applications"
hdiutil create -volname "$APP_NAME" -srcfolder "$DMG_ROOT" -ov -format UDZO "$DMG_PATH"

SOCKET_SLUG="$(sanitize_socket_slug "${BUNDLE_ID#com.cmuxterm.app.debug.}")"
SOCKET_PATH="/tmp/cmux-debug-${SOCKET_SLUG}.sock"
{
  echo "APP_NAME=$APP_NAME"
  echo "BUNDLE_ID=$BUNDLE_ID"
  echo "APP_PATH=$PACKAGE_APP_PATH"
  echo "SOCKET_PATH=$SOCKET_PATH"
  echo "APP_ZIP=$APP_ZIP"
  echo "PACKAGE_ZIP=$PACKAGE_ZIP"
  echo "DMG_PATH=$DMG_PATH"
  echo "MARKETING_VERSION=$MARKETING_VERSION"
  echo "BUILD_NUMBER=$BUILD_NUMBER"
  echo "COMMIT=${SHORT_SHA:-unknown}"
} > "$METADATA_PATH"

echo "Low-cost release package created:"
echo "  App: $PACKAGE_APP_PATH"
echo "  App zip: $APP_ZIP"
echo "  Package zip: $PACKAGE_ZIP"
echo "  DMG: $DMG_PATH"
echo "  Metadata: $METADATA_PATH"
