#!/usr/bin/env bash
set -eux

GITHUB_TOKEN=$(cat /run/secrets/GITHUB_TOKEN 2>/dev/null || true)
AUTH_HEADER=""

apt-get update
apt-get install -y --no-install-recommends \
    libxml2-dev uuid-dev libssl-dev \
    bash patch make xz-utils bzip2 cpio zlib1g-dev
rm -rf /var/lib/apt/lists/*

if [ -n "$GITHUB_TOKEN" ]; then
    AUTH_HEADER="Authorization: Basic $(printf 'X-Access-Token:%s' "$GITHUB_TOKEN" | base64 -w0)"
fi

git clone -c http.extraheader="${AUTH_HEADER}" --depth 1 https://github.com/tpoechtrager/osxcross "${OSXCROSS}"
cd "${OSXCROSS}"
sed -i 's/"-mmacosx-version-min"/"-miphoneos-version-min"/g' wrapper/main.cpp
sed -i 's/"-mmacos-version-min"/"-miphoneos-version-min"/g' wrapper/main.cpp
sed -i '/if (!detectTarget(argc, argv, target)) {/i \
  for (auto it = target.fargs.begin(); it != target.fargs.end();) {\
    if (it->find("-mmacosx-version-min") == 0 || it->find("-mmacos-version-min") == 0) {\
      it = target.fargs.erase(it);\
    } else {\
      ++it;\
    }\
  }' wrapper/main.cpp
sed -i 's/set(CMAKE_SYSTEM_NAME "Darwin")/set(CMAKE_SYSTEM_NAME "iOS")/g' tools/toolchain.cmake

mkdir -p /tmp/sdk-extract
tar -xf /tmp/ios-sdk.tar.xz -C /tmp/sdk-extract
SDK_DIR=$(ls -d /tmp/sdk-extract/*.sdk | head -1)
SDK_VERSION=$(grep -A 1 "ProductVersion" "${SDK_DIR}/System/Library/CoreServices/SystemVersion.plist" 2>/dev/null | tail -1 | sed 's/.*<string>\(.*\)<\/string>.*/\1/' | cut -d. -f1-2 || echo "18.0")
mv "${SDK_DIR}" "/tmp/sdk-extract/MacOSX${SDK_VERSION}.sdk"
tar -cJf "${OSXCROSS}/tarballs/MacOSX${SDK_VERSION}.sdk.tar.xz" -C /tmp/sdk-extract "MacOSX${SDK_VERSION}.sdk"
rm -rf /tmp/sdk-extract
