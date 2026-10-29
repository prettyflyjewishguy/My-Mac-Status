#!/bin/zsh
set -euo pipefail
cd "${0:A:h}/.."
STAMP="$(/bin/date +%Y%m%d-%H%M%S)"
LOGDIR="$PWD/validation-results/$STAMP"
/bin/mkdir -p "$LOGDIR"
exec > >(/usr/bin/tee "$LOGDIR/build.log") 2>&1
print "My Mac Status Community Edition — validation build"
print "Timestamp: $STAMP"
print "macOS: $(/usr/bin/sw_vers -productVersion)"
print "Architecture: $(/usr/bin/uname -m)"
print "Swift: $(/usr/bin/swiftc --version)"
print "Xcode tools: $(/usr/bin/xcode-select -p)"
print "Build command: zsh Scripts/build_on_mac.zsh"
if ! /bin/zsh Scripts/build_on_mac.zsh; then
 print -u2 "BUILD FAILED. See $LOGDIR/build.log"
 exit 1
fi
APP="$PWD/output/My Mac Status.app"
PKG="$PWD/output/My-Mac-Status-v1.0.0-community-unsigned.pkg"
[[ -d "$APP" && -f "$PKG" ]] || { print -u2 "Missing expected build output"; exit 2; }
/usr/bin/plutil -lint "$APP/Contents/Info.plist"
/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$APP/Contents/Info.plist"
/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$APP/Contents/Info.plist"
/usr/bin/codesign --verify --verbose=2 "$APP"
/usr/sbin/pkgutil --check-signature "$PKG" || true
/usr/sbin/pkgutil --expand "$PKG" "$LOGDIR/expanded-pkg"
/usr/bin/find "$LOGDIR/expanded-pkg" -maxdepth 2 -type f | /usr/bin/sort > "$LOGDIR/package-files.txt"
/usr/bin/shasum -a 256 "$PKG" "$APP/Contents/MacOS/MyMacStatus" > "$LOGDIR/sha256.txt"
print "BUILD VALIDATION COMPLETE: $LOGDIR"
print "Unsigned PKG is expected for this validation build."
