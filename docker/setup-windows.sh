#!/usr/bin/env bash
set -eux
set -o pipefail

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
rm "$XWIN"


git clone https://github.com/geode-sdk/clang-msvc-sdk "$TOOLCHAIN"

# Cleanup some stuff that is unlikely to ever be used for mod compilation

# Static C library (+ debug versions)
rm -r "$SPLAT/crt/lib/x86_64/enclave"
rm "$SPLAT/crt/lib/x86_64/libcmt.lib"
rm "$SPLAT/crt/lib/x86_64/LIBCMT.lib"
rm "$SPLAT/crt/lib/x86_64/libcmtd.lib"
rm "$SPLAT/crt/lib/x86_64/LIBCMTD.lib"
# Static C++ library
rm "$SPLAT/crt/lib/x86_64/libcpmt.lib"
rm "$SPLAT/crt/lib/x86_64/libcpmt1.lib"
rm "$SPLAT/crt/lib/x86_64/libcpmtd.lib"
rm "$SPLAT/crt/lib/x86_64/libcpmtd0.lib"
rm "$SPLAT/crt/lib/x86_64/libcpmtd1.lib"
# Static concurrency library
rm "$SPLAT/crt/lib/x86_64/libconcrt.lib"
rm "$SPLAT/crt/lib/x86_64/libconcrt1.lib"
rm "$SPLAT/crt/lib/x86_64/libconcrtd.lib"
rm "$SPLAT/crt/lib/x86_64/libconcrtd0.lib"
rm "$SPLAT/crt/lib/x86_64/libconcrtd1.lib"
# Static LLVM libc++ math libraries, only used with /Zc:cmath flag
# Extremely unlikely to be used in mods but 60mb total, remove them
rm "$SPLAT/crt/lib/x86_64/libvcmath-md.lib"
rm "$SPLAT/crt/lib/x86_64/libvcmath-mt.lib"

# Undocumented static msvcrt and libcmt libs (what is this? unused for mods?)
rm "$SPLAT/sdk/lib/um/x86_64/ntstc_msvcrt.lib"
rm "$SPLAT/sdk/lib/um/x86_64/ntstc_libcmt.lib"

# WinRT
rm -r "$SPLAT/sdk/include/cppwinrt"
rm -r "$SPLAT/sdk/include/winrt"

# MsHTML (massive headers)
rm -r "$SPLAT/sdk/include/um/Mshtmlc.h"
rm -r "$SPLAT/sdk/include/um/MsHTML.h"
rm -r "$SPLAT/sdk/include/um/MsHTML.Idl"

# Static UCRT
rm "$SPLAT/sdk/lib/ucrt/x86_64/libucrt.lib"
rm "$SPLAT/sdk/lib/ucrt/x86_64/libucrtd.lib"