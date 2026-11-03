#!/usr/bin/env bash
set -eux

GITHUB_TOKEN=$(cat /run/secrets/GITHUB_TOKEN 2>/dev/null || true)
TARGETARCH=$1
ANDROID_NDK_ROOT=$2
ANDROID_NDK_VERSION=$3

if [ -n "$GITHUB_TOKEN" ]; then
    AUTH_HEADER="Authorization: Bearer $GITHUB_TOKEN"
fi

if [ "${TARGETARCH}" = "arm64" ]; then
    echo "Installing Android NDK for aarch64"
    curl -fsSL ${AUTH_HEADER:+-H "$AUTH_HEADER"} "https://github.com/SnowNF/ndk-aarch64-linux/releases/download/0.0.2/android-ndk-r29-linux-aarch64.tar.gz" -o /tmp/android-ndk.tar.gz
    mkdir -p "${ANDROID_NDK_ROOT}"
    tar -xzf /tmp/android-ndk.tar.gz -C "${ANDROID_NDK_ROOT}" --strip-components=1
    rm /tmp/android-ndk.tar.gz
else
    echo "Installing Android NDK ${ANDROID_NDK_VERSION}"
    curl -fsSL "https://dl.google.com/android/repository/android-ndk-${ANDROID_NDK_VERSION}-linux.zip" -o /tmp/android-ndk.zip
    unzip -q /tmp/android-ndk.zip -d /opt
    rm /tmp/android-ndk.zip
    mv "/opt/android-ndk-${ANDROID_NDK_VERSION}" "${ANDROID_NDK_ROOT}"
fi
echo "ANDROID_NDK_ROOT=${ANDROID_NDK_ROOT}" >> /etc/environment
