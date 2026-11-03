#!/usr/bin/env bash
set -eux

LLVM_VERSION=$1

GITHUB_TOKEN=$(cat /run/secrets/GITHUB_TOKEN 2>/dev/null || true)
AUTH_HEADER=""

apt-get update
apt-get install -y --no-install-recommends \
    libxml2-dev uuid-dev libssl-dev \
    bash patch make xz-utils bzip2 cpio zlib1g-dev \
    llvm-${LLVM_VERSION}-dev clang-tools-${LLVM_VERSION}
rm -rf /var/lib/apt/lists/*

if [ -n "$GITHUB_TOKEN" ]; then
    AUTH_HEADER="Authorization: Bearer $GITHUB_TOKEN"
fi

git clone --depth 1 https://github.com/tpoechtrager/osxcross "${OSXCROSS}"
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
sed -i \
  -e '/CCTOOLS_VERSION=\$STABLE_CCTOOLS_VERSION/,$ {' \
  -e '/^    CONFFLAGS=/r /dev/stdin' \
  -e '}' \
  build.sh <<'EOF'
    $SED -i '/# it may cause the build to fail./a\
\
            if test -e $LLVM_INCLUDE_DIR/llvm-c/Visibility.h; then\
              cp -f $LLVM_INCLUDE_DIR/llvm-c/Visibility.h `dirname ${0}`/include/llvm-c\
              mkdir -p `dirname ${0}`/include/llvm/Config\
              cp -f $LLVM_INCLUDE_DIR/llvm/Config/llvm-config.h `dirname ${0}`/include/llvm/Config\
            fi' configure
EOF

mkdir -p /tmp/sdk-extract
tar -xf /tmp/ios-sdk.tar.xz -C /tmp/sdk-extract
SDK_DIR=$(ls -d /tmp/sdk-extract/*.sdk | head -1)
SDK_VERSION=$(grep -A 1 "ProductVersion" "${SDK_DIR}/System/Library/CoreServices/SystemVersion.plist" 2>/dev/null | tail -1 | sed 's/.*<string>\(.*\)<\/string>.*/\1/' | cut -d. -f1-2 || echo "18.0")
mv "${SDK_DIR}" "/tmp/sdk-extract/MacOSX${SDK_VERSION}.sdk"
tar -cJf "${OSXCROSS}/tarballs/MacOSX${SDK_VERSION}.sdk.tar.xz" -C /tmp/sdk-extract "MacOSX${SDK_VERSION}.sdk"
rm -rf /tmp/sdk-extract
