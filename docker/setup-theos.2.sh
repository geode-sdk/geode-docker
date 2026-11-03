#!/usr/bin/env bash
set -eux

GITHUB_TOKEN=$(cat /run/secrets/GITHUB_TOKEN 2>/dev/null || true)
AUTH_HEADER=""

if [ -n "$GITHUB_TOKEN" ]; then
    AUTH_HEADER="Authorization: Bearer $GITHUB_TOKEN"
fi

rm -rf target/SDK/MacOSX*.sdk
git clone --depth 1 https://github.com/theos/theos "${THEOS}"
tar -xf /tmp/ios-sdk.tar.xz -C "${THEOS}/sdks"
SDK_NAME=$(ls "${THEOS}/sdks" | grep '\.sdk' | head -1)
ln -sf "${THEOS}/sdks/${SDK_NAME}" "${OSXCROSS}/target/SDK/${SDK_NAME}"
ln -sf "${THEOS}/sdks/${SDK_NAME}" "${OSXCROSS}/target/SDK/MacOSX26.1.sdk"
rm /tmp/ios-sdk.tar.xz
