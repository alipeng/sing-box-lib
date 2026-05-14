#!/usr/bin/env bash
# Local replica of .github/workflows/Release.yml — runs every step in
# the same order so you can iterate on the build without pushing to CI.
#
# Usage:
#   ./build_locally.sh                # default: builds v1.13.11 into /tmp/sing-box-libbox-local
#   SINGBOX_TAG=v1.13.12 ./build_locally.sh
#   WORKDIR=/var/tmp/foo ./build_locally.sh
#   ./build_locally.sh --verify-only  # skip clone/build, just re-run verify on the existing artifact
#
# Required: Go ~1.25.9, Xcode CLI tools (for nm/awk/PlistBuddy/lipo/file),
# git, curl, zip.

set -euo pipefail

# ---------- Config ----------
SINGBOX_TAG="${SINGBOX_TAG:-v1.13.11}"
WORKDIR="${WORKDIR:-/tmp/sing-box-libbox-local}"
SINGBOX_DIR="$WORKDIR/sing-box"
PLATFORM="${PLATFORM:-ios}"     # ios, or ios,tvos,macos for the multi-slice build

VERIFY_ONLY=0
if [[ "${1:-}" == "--verify-only" ]]; then
    VERIFY_ONLY=1
fi

cd "$(dirname "$0")"

color() { printf "\033[%sm%s\033[0m\n" "$1" "$2"; }
hdr()   { color "1;36" "==> $1"; }
warn()  { color "1;33" "!!  $1"; }
fail()  { color "1;31" "XX  $1"; exit 1; }
ok()    { color "1;32" "OK  $1"; }

# ---------- Env checks ----------
command -v go     >/dev/null || fail "Go not on PATH. Install Go >= 1.25.9."
command -v git    >/dev/null || fail "git missing"
command -v zip    >/dev/null || fail "zip missing"
command -v awk    >/dev/null || fail "awk missing"
command -v nm     >/dev/null || fail "nm missing (install Xcode Command Line Tools: xcode-select --install)"
[ -x /usr/libexec/PlistBuddy ] || fail "PlistBuddy missing (Xcode Command Line Tools)"

GO_VER=$(go version | awk '{print $3}')
hdr "Environment"
echo "  Go            : $GO_VER"
echo "  PATH gomobile : $(command -v gomobile 2>/dev/null || echo '(not installed yet)')"
echo "  SINGBOX_TAG   : $SINGBOX_TAG"
echo "  PLATFORM      : $PLATFORM"
echo "  WORKDIR       : $WORKDIR"

# ---------- Clone + build ----------
if [ "$VERIFY_ONLY" -eq 0 ]; then
    hdr "Cloning / updating sing-box at $SINGBOX_TAG"
    mkdir -p "$WORKDIR"
    if [ ! -d "$SINGBOX_DIR/.git" ]; then
        git clone --depth 1 --branch "$SINGBOX_TAG" \
            https://github.com/SagerNet/sing-box.git "$SINGBOX_DIR"
    else
        ( cd "$SINGBOX_DIR" && git fetch --depth 1 origin tag "$SINGBOX_TAG" --no-tags \
          && git checkout "$SINGBOX_TAG" )
    fi
    ok "sing-box checkout: $SINGBOX_DIR ($SINGBOX_TAG)"

    hdr "Installing gomobile + gobind (make lib_install)"
    ( cd "$SINGBOX_DIR" && make lib_install )
    export PATH="$PATH:$(go env GOPATH)/bin"
    ok "gomobile @ $(command -v gomobile)"

    hdr "Building xcframework (-target apple -platform $PLATFORM)"
    ( cd "$SINGBOX_DIR" && go run ./cmd/internal/build_libbox \
        -target apple -platform "$PLATFORM" )
    ok "build_libbox finished"

    hdr "Flatten iOS slice + sync xcframework Info.plist"
    cd "$SINGBOX_DIR"

    flatten_framework() {
        local fw="$1"
        if [ ! -d "$fw/Versions" ]; then
            echo "  Already shallow: $fw"
            return
        fi
        local tmp; tmp="$(mktemp -d)"
        cp -RL "$fw/Libbox"  "$tmp/Libbox"
        cp -RL "$fw/Headers" "$tmp/Headers"
        cp -RL "$fw/Modules" "$tmp/Modules"
        cp    "$fw/Resources/Info.plist" "$tmp/Info.plist"
        rm -rf "$fw"
        mv "$tmp" "$fw"
    }

    if [ -d Libbox.xcframework/ios-arm64/Libbox.framework ]; then
        flatten_framework Libbox.xcframework/ios-arm64/Libbox.framework
    fi
    if [ -d Libbox.xcframework/tvos-arm64/Libbox.framework ]; then
        flatten_framework Libbox.xcframework/tvos-arm64/Libbox.framework
    fi

    PLIST=Libbox.xcframework/Info.plist
    COUNT=$(/usr/libexec/PlistBuddy -c "Print :AvailableLibraries" "$PLIST" | grep -c "^    Dict {")
    echo "  Slices in xcframework: $COUNT"
    for ((i=0; i<COUNT; i++)); do
        id=$(/usr/libexec/PlistBuddy -c "Print :AvailableLibraries:$i:LibraryIdentifier" "$PLIST")
        if [[ "$id" == macos* ]]; then
            /usr/libexec/PlistBuddy -c \
                "Set :AvailableLibraries:$i:BinaryPath Libbox.framework/Versions/A/Libbox" "$PLIST"
        else
            /usr/libexec/PlistBuddy -c \
                "Set :AvailableLibraries:$i:BinaryPath Libbox.framework/Libbox" "$PLIST"
        fi
    done
    echo "  --- final BinaryPath / LibraryIdentifier ---"
    /usr/libexec/PlistBuddy -c "Print :AvailableLibraries" "$PLIST" \
        | grep -E "BinaryPath|LibraryIdentifier" | sed 's/^/  /'
    ok "framework structure + Info.plist consistent"
fi

# ---------- Verify (mirrors workflow step 7) ----------
hdr "Verify iOS slice has real Libbox symbols"
cd "$SINGBOX_DIR"

IOS_LIB=Libbox.xcframework/ios-arm64/Libbox.framework/Libbox
[ -f "$IOS_LIB" ] || fail "Missing iOS Libbox binary at $IOS_LIB"

echo "--- file ---"
file "$IOS_LIB"

SIZE=$(stat -f%z "$IOS_LIB")
SIZE_MB=$(echo "scale=1; $SIZE/1024/1024" | bc)
echo "--- size ---"
echo "$SIZE bytes (${SIZE_MB} MB)"
[ "$SIZE" -ge 10000000 ] || fail "iOS Libbox is $SIZE bytes (<10MB) — looks like an empty stub."

FOUND=0

echo "--- nm -gU sample ---"
nm -gU "$IOS_LIB" 2>&1 | awk '/_LibboxSetup/{print; n++} n==5{exit}' || true
if nm -gU "$IOS_LIB" 2>&1 | awk '$2 == "T" && $3 == "_LibboxSetup" {found=1; exit} END {exit !found}'; then
    echo "  -> matched via nm -gU + awk fields"
    FOUND=1
fi

echo "--- nm --defined-only sample ---"
nm --defined-only "$IOS_LIB" 2>&1 | awk '/_LibboxSetup/{print; n++} n==5{exit}' || true
if nm --defined-only "$IOS_LIB" 2>&1 | awk '$2 == "T" && $3 == "_LibboxSetup" {found=1; exit} END {exit !found}'; then
    echo "  -> matched via nm --defined-only + awk fields"
    FOUND=1
fi

# Belt-and-braces: hex-dump the symbol string. If it's in the binary
# at all, this will find it. Works on raw Mach-O archives without any
# nm parsing.
echo "--- raw byte scan for 'LibboxSetup' ---"
COUNT_RAW=$(LC_ALL=C tr '\0' '\n' < "$IOS_LIB" | grep -c "LibboxSetup" || true)
echo "  occurrences of 'LibboxSetup' in raw bytes: $COUNT_RAW"
if [ "$COUNT_RAW" -gt 0 ]; then
    FOUND=1
fi

if [ "$FOUND" -eq 0 ]; then
    fail "iOS Libbox binary has no LibboxSetup symbol via any method — link is broken."
fi
ok "iOS Libbox binary contains LibboxSetup"

# ---------- Repack + checksum ----------
if [ "$VERIFY_ONLY" -eq 0 ]; then
    hdr "Repack zip + compute checksum"
    cd "$SINGBOX_DIR"
    rm -f Libbox.xcframework.zip
    zip -ryq Libbox.xcframework.zip Libbox.xcframework
    CHECKSUM=$(shasum -a 256 Libbox.xcframework.zip | awk '{print $1}')
    ZIP_SIZE=$(stat -f%z Libbox.xcframework.zip)
    ZIP_MB=$(echo "scale=1; $ZIP_SIZE/1024/1024" | bc)
    echo "  zip: Libbox.xcframework.zip (${ZIP_MB} MB)"
    echo "  sha256: $CHECKSUM"
    ok "ready at $SINGBOX_DIR/Libbox.xcframework.zip"
fi

color "1;32" "✓ All steps passed."
