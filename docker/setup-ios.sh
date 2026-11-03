#!/usr/bin/env bash
set -eux

sed -i '/is not an iOS SDK/d; /message(FATAL_ERROR/d' /opt/cmake/share/cmake-*/Modules/Platform/iOS-Initialize.cmake

SDK_NAME=$(ls "${THEOS}/sdks" | grep '\.sdk' | head -1)
THEOS_SDK_PATH=${THEOS}/sdks/${SDK_NAME}
sed -i \
    -e "s|\$ENV{THEOS_SDK_PATH}|${THEOS_SDK_PATH}|g" \
    -e "s|\$ENV{OSXCROSS}|${OSXCROSS}|g" \
    /docker/ios.toolchain.cmake
