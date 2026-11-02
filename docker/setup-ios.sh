#!/usr/bin/env bash
set -eux

TOOLCHAIN_PATH=$1

sed -i '/is not an iOS SDK/d; /message(FATAL_ERROR/d' /usr/share/cmake-*/Modules/Platform/iOS-Initialize.cmake

SDK_NAME=$(ls "${THEOS}/sdks" | grep '\.sdk' | head -1)
sed -e "s|THEOS_SDK_PATH|${THEOS}/sdks/${SDK_NAME}|g" -e "s|OSXCROSS_ROOT|${OSXCROSS}|g" \
    $TOOLCHAIN_PATH > $TOOLCHAIN_PATH
