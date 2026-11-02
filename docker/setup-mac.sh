#!/usr/bin/env bash
set -eux

TOOLCHAIN_PATH=$1

apt-get update
apt-get install -y --no-install-recommends libxml2-utils
rm -rf /var/lib/apt/lists/*
SYS_LIBXML=$(find /usr/lib/ -name "libxml2.so.*" | head -1)
if [ -n "$SYS_LIBXML" ]; then
    ln -sf "$SYS_LIBXML" $(dirname "$SYS_LIBXML")/libxml2.so.2
fi

OSXCROSS_TARGET=$(ls /osxcross/bin/*-apple-darwin*-clang | head -1 | xargs basename | sed 's/-clang$//')
OSXCROSS_SDK_PATH=$(ls -d /osxcross/SDK/*.sdk | head -1)

sed -e "s|OSXCROSS_TARGET|${OSXCROSS_TARGET}|g" -e "s|OSXCROSS_SDK_PATH|${OSXCROSS_SDK_PATH}|g" \
    $TOOLCHAIN_PATH > $TOOLCHAIN_PATH
