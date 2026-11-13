#!/bin/zsh
set -euo pipefail
cd "${0:A:h}/.."
NAME="My Mac Status"
VERSION="2.0"
BUNDLE="com.prettyfly.mymacstatus"
OUT="$PWD/output-v2.0-ga-candidate"
STAGING="$(/usr/bin/mktemp -d /tmp/MyMacStatusBuild.XXXXXXXX)"
trap '/bin/rm -rf "$STAGING"' EXIT
APP="$STAGING/$NAME.app"
/bin/mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources" "$OUT"
/usr/bin/python3 Scripts/verify_rc1_source.py
/usr/bin/python3 Scripts/verify_rc1_fix1_help.py
/usr/bin/python3 Scripts/verify_fix8_storage.py
SOURCES=(Sources/**/*.swift(N))
(( ${#SOURCES[@]} > 0 )) || { echo "No Swift sources found" >&2; exit 1; }
SDK_PATH="$(/usr/bin/xcrun --sdk macosx --show-sdk-path)"
[[ -d "$SDK_PATH" ]] || { echo "ERROR: macOS SDK not found: $SDK_PATH" >&2; exit 1; }
"$(/usr/bin/xcrun --sdk macosx --find swiftc)" -O -parse-as-library -target arm64-apple-macos14.0 -sdk "$SDK_PATH" \
 -framework SwiftUI -framework AppKit -framework IOKit \
 "${SOURCES[@]}" -o "$APP/Contents/MacOS/MyMacStatus"
if [[ -f Resources/BrandLogo.png ]]; then
 /bin/cp Resources/BrandLogo.png "$APP/Contents/Resources/"
fi
if [[ -f Resources/AppIcon.png ]]; then
 ICONSET="$STAGING/App.iconset"
 /bin/mkdir -p "$ICONSET"
 for SIZE in 16 32 128 256 512; do
   /usr/bin/sips -s format png -z "$SIZE" "$SIZE" Resources/AppIcon.png --out "$ICONSET/icon_${SIZE}x${SIZE}.png" >/dev/null
   DOUBLE=$((SIZE * 2))
   /usr/bin/sips -s format png -z "$DOUBLE" "$DOUBLE" Resources/AppIcon.png --out "$ICONSET/icon_${SIZE}x${SIZE}@2x.png" >/dev/null
 done
 /usr/bin/iconutil -c icns "$ICONSET" -o "$APP/Contents/Resources/AppIcon.icns"
fi
# Public build-time configuration; do not place API keys, tokens or passwords here.
BRAND_NAME="${MYMACSTATUS_BRAND_NAME:-My Mac Status}"
BRAND_SUBTITLE="${MYMACSTATUS_BRAND_SUBTITLE:-Device Health}"
SUPPORT_EMAIL="${MYMACSTATUS_SUPPORT_EMAIL:-}"
SUPPORT_URL="${MYMACSTATUS_SUPPORT_URL:-}"
/bin/cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict></dict></plist>
PLIST
/usr/libexec/PlistBuddy -c 'Add :CFBundleExecutable string MyMacStatus' "$APP/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Add :CFBundleIdentifier string $BUNDLE" "$APP/Contents/Info.plist"
/usr/libexec/PlistBuddy -c 'Add :CFBundlePackageType string APPL' "$APP/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Add :CFBundleName string $NAME" "$APP/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Add :CFBundleDisplayName string $NAME" "$APP/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Add :CFBundleShortVersionString string $VERSION" "$APP/Contents/Info.plist"
/usr/libexec/PlistBuddy -c 'Add :CFBundleVersion string 2000' "$APP/Contents/Info.plist"
/usr/libexec/PlistBuddy -c 'Add :LSMinimumSystemVersion string 14.0' "$APP/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Add :CommunityBrandName string $BRAND_NAME" "$APP/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Add :CommunityBrandSubtitle string $BRAND_SUBTITLE" "$APP/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Add :CommunitySupportEmail string $SUPPORT_EMAIL" "$APP/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Add :CommunitySupportURL string $SUPPORT_URL" "$APP/Contents/Info.plist"
if [[ -f "$APP/Contents/Resources/AppIcon.icns" ]]; then
 /usr/libexec/PlistBuddy -c 'Add :CFBundleIconFile string AppIcon' "$APP/Contents/Info.plist"
fi
/usr/bin/plutil -lint "$APP/Contents/Info.plist"
# For consistent Keychain trust across builds, use the SAME real signing identity
# used to sign the validated Fix 2.2 app. Ad-hoc signing cannot guarantee this.
SIGN_IDENTITY="${MYMACSTATUS_SIGN_IDENTITY:--}"
if [[ "$SIGN_IDENTITY" == "-" ]]; then
  if [[ "${MYMACSTATUS_REQUIRE_STABLE_SIGNING:-0}" == "1" ]]; then
    echo "ERROR: Stable signing is required for this Keychain regression test. Set MYMACSTATUS_SIGN_IDENTITY to a valid certificate." >&2
    exit 1
  fi
  echo "WARNING: ad-hoc signing selected. Existing Keychain ACLs may prompt again after a rebuild." >&2
  echo "For stable authorization, set MYMACSTATUS_SIGN_IDENTITY to the same certificate used for Fix 2.2." >&2
fi
/usr/bin/codesign --force --sign "$SIGN_IDENTITY" "$APP"
/usr/bin/codesign --verify --strict --verbose=2 "$APP"
echo "Signing details for this build:"
/usr/bin/codesign -dv --verbose=4 "$APP" 2>&1 | /usr/bin/grep -E "^(Identifier|TeamIdentifier|Authority|Signature)=" || true
ROOT="$STAGING/root"
/bin/mkdir -p "$ROOT/Applications"
/usr/bin/ditto --norsrc --noextattr "$APP" "$ROOT/Applications/$NAME.app"
/usr/bin/pkgbuild --root "$ROOT" --identifier "$BUNDLE.pkg" --version "$VERSION" \
 --install-location / --ownership recommended "$OUT/My-Mac-Status-v${VERSION}-community-unsigned.pkg"
/usr/bin/ditto --norsrc --noextattr "$APP" "$OUT/$NAME.app"
# Verify that the exact source being tested contains both feature and settings entry points.
/usr/bin/grep -q 'macOS Update Intelligence' Sources/Views/UpdateIntelligenceView.swift
/usr/bin/grep -q 'UpdateIntelligenceView()' Sources/Views/MacHealthView.swift
/usr/bin/grep -q 'Settings & Connections' Sources/Views/CompanionRootView.swift
/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' "$APP/Contents/Info.plist" 2>/dev/null || true
printf '\nBUILD ID: V2.0-GA-CANDIDATE / 2000\nAPP: %s\n' "$OUT/$NAME.app"
printf 'To launch THIS exact app (not an older installed copy):\n  open -n "%s"\n' "$OUT/$NAME.app"
echo "Bundle ID: $BUNDLE; signing identity: $SIGN_IDENTITY"
echo "Built community application and installer in $OUT"
