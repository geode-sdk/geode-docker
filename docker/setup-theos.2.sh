#!/usr/bin/env bash
set -eux
set -o pipefail

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

# Remove unnecessary stuff from osxcross build
rm -rf /osxcross/build /osxcross/tarballs /osxcross/.git /opt/theos/.git
# and from the toolchain
SDK_PATH="${THEOS}/sdks/${SDK_NAME}"
FRAMEWORKS="${SDK_PATH}/System/Library/Frameworks"
rm -rf "${FRAMEWORKS}/SwiftUICore.framework"
rm -rf "${FRAMEWORKS}/SwiftUI.framework"
rm -rf "${FRAMEWORKS}/Matter.framework"
rm -rf "${FRAMEWORKS}/RealityFoundation.framework"
rm -rf "${FRAMEWORKS}/AppIntents.framework"

# Remove swift module metadata for every remaining framework, which makes up most of the size in those modules
find "${FRAMEWORKS}/"*.framework \( -name '*.swiftmodule' -o -name '*.swiftinterface' -o -name '*.swiftdoc' \) -delete
