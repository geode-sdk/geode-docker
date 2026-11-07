#!/usr/bin/env bash
set -eux

GITHUB_TOKEN=$(cat /run/secrets/GITHUB_TOKEN 2>/dev/null || true)
WIN_ARCH=x86_64
XWIN_VERSION=0.10.0
WIN_MANIFEST_VERSION=18
WIN_SDK_VERSION=10.0.28000

XWIN="$WIN_CROSS_ROOT/xwin"
SPLAT="$WIN_CROSS_ROOT/splat"
TOOLCHAIN="$WIN_CROSS_ROOT/clang-msvc-sdk"

mkdir -p "$WIN_CROSS_ROOT"

if [ -n "$GITHUB_TOKEN" ]; then
    AUTH_HEADER="Authorization: Bearer $GITHUB_TOKEN"
fi


case "$(uname -m)" in
    aarch64|arm64) SUFFIX="aarch64-unknown-linux-musl.tar.gz" ;;
    x86_64|amd64)  SUFFIX="x86_64-unknown-linux-musl.tar.gz" ;;
    *) echo "Unsupported architecture: $(uname -m)" >&2; exit 1 ;;
esac

RELEASE=$(curl -fsSL ${AUTH_HEADER:+-H "$AUTH_HEADER"} \
    https://api.github.com/repos/Jake-Shadle/xwin/releases/tags/${XWIN_VERSION})

NAME=$(jq -r --arg suffix "$SUFFIX" \
    '.assets[] | select(.name | endswith($suffix)) | .name' \
    <<< "$RELEASE" | head -n1)

URL=$(jq -r --arg name "$NAME" \
    '.assets[] | select(.name == $name) | .browser_download_url' \
    <<< "$RELEASE")

ARCHIVE="$WIN_CROSS_ROOT/temp-xwin.tar.gz"

curl -fsSL "$URL" -o "$ARCHIVE"
tar -xzf "$ARCHIVE" --strip-components=1 \
    -C "$WIN_CROSS_ROOT" "${NAME%.tar.gz}/xwin"

rm "$ARCHIVE"
chmod +x "$XWIN"

"$XWIN" \
    --accept-license \
    --manifest-version $WIN_MANIFEST_VERSION \
    --sdk-version $WIN_SDK_VERSION \
    --arch "$WIN_ARCH" \
    --cache-dir "$WIN_CROSS_ROOT/.xwin-cache" \
    splat \
    --output "$SPLAT" \
    --include-debug-libs

rm -rf "$WIN_CROSS_ROOT/.xwin-cache"


git clone https://github.com/geode-sdk/clang-msvc-sdk "$TOOLCHAIN"
