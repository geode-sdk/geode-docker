#!/usr/bin/env bash
set -eux

sed -i '/is not an iOS SDK/d; /message(FATAL_ERROR/d' /usr/share/cmake-*/Modules/Platform/iOS-Initialize.cmake

SDK_NAME=$(ls "${THEOS}/sdks" | grep '\.sdk' | head -1)
echo THEOS_SDK_PATH=${THEOS}/sdks/${SDK_NAME} >> /etc/environment
