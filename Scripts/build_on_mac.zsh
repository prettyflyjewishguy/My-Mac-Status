#!/bin/zsh
set -euo pipefail
cd "${0:A:h}/.."
NAME="My Mac Status"
VERSION="1.0.0"
BUNDLE="org.example.mymacstatus"
OUT="$PWD/output"
STAGING="$(/usr/bin/mktemp -d /tmp/MyMacStatusBuild.XXXXXXXX)"
trap '/bin/rm -rf "$STAGING"' EXIT
APP="$STAGING/$NAME.app"
/bin/mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources" "$OUT"
SOURCES=(Sources/**/*.swift(N))
(( ${#SOURCES[@]} > 0 )) || { echo "No Swift sources found" >&2; exit 1; }
/usr/bin/swiftc -O -parse-as-library -target arm64-apple-macos14.0 \
 -framework SwiftUI -framework AppKit -framework IOKit \
 "${SOURCES[@]}" -o "$APP/Contents/MacOS/MyMacStatus"
/bin/cp Resources/CommunityHelp.html "$APP/Contents/Resources/"
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
/usr/libexec/PlistBuddy -c 'Add :CFBundleVersion string 1' "$APP/Contents/Info.plist"
/usr/libexec/PlistBuddy -c 'Add :LSMinimumSystemVersion string 14.0' "$APP/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Add :CommunityBrandName string $BRAND_NAME" "$APP/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Add :CommunityBrandSubtitle string $BRAND_SUBTITLE" "$APP/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Add :CommunitySupportEmail string $SUPPORT_EMAIL" "$APP/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Add :CommunitySupportURL string $SUPPORT_URL" "$APP/Contents/Info.plist"
if [[ -f "$APP/Contents/Resources/AppIcon.icns" ]]; then
 /usr/libexec/PlistBuddy -c 'Add :CFBundleIconFile string AppIcon' "$APP/Contents/Info.plist"
fi
/usr/bin/plutil -lint "$APP/Contents/Info.plist"
/usr/bin/codesign --force --sign - "$APP"
ROOT="$STAGING/root"
/bin/mkdir -p "$ROOT/Applications"
/usr/bin/ditto --norsrc --noextattr "$APP" "$ROOT/Applications/$NAME.app"
/usr/bin/pkgbuild --root "$ROOT" --identifier "$BUNDLE.pkg" --version "$VERSION" \
 --install-location / --ownership recommended "$OUT/My-Mac-Status-v${VERSION}-community-unsigned.pkg"
/usr/bin/ditto --norsrc --noextattr "$APP" "$OUT/$NAME.app"
echo "Built community application and installer in $OUT"
