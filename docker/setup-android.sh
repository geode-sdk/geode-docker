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

TC=$(ls -d "${ANDROID_NDK_ROOT}"/toolchains/llvm/prebuilt/*/ | head -1)

# Remove unnecessary bins and such from android toolchain
rm -f "${TC}bin/clangd" "${TC}bin/clang-check" "${TC}bin/clang-tidy" \
      "${TC}bin/clang-scan-deps" "${TC}bin/llvm-bolt" "${TC}bin/llvm-cfi-verify" \
      "${TC}bin/sancov" "${TC}bin/lldb"
rm -f "${TC}lib/libclang.so" "${TC}lib/libclang-cpp.so" "${TC}lib/liblldb.so"
rm -rf "${TC}simpleperf" "${ANDROID_NDK_ROOT}/shader-tools" "${TC}lib/x86_64-w64-windows-gnu"
rm -rf "${TC}sysroot/usr/lib/i686-linux-android" \
       "${TC}sysroot/usr/lib/x86_64-linux-android" \
       "${TC}sysroot/usr/lib/riscv64-linux-android"
rm -rf "${TC}lib/clang"/*/lib/linux/*i686* \
       "${TC}lib/clang"/*/lib/linux/*x86_64* \
       "${TC}lib/clang"/*/lib/linux/*riscv64* \
       "${TC}lib/clang"/*/lib/linux/i386
