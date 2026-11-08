#!/usr/bin/env bash
set -eux

LLVM_VERSION=$1
CMAKE_VERSION=$2

NODE_VERSION=24
curl -fsSL https://deb.nodesource.com/setup_${NODE_VERSION}.x | bash -
apt-get update
apt-get install -y --no-install-recommends \
    ca-certificates curl gpg nodejs git unzip xz-utils \
    build-essential pkg-config ninja-build jq sccache
rm -rf /var/lib/apt/lists/*

install -d /etc/apt/keyrings
curl -fsSL https://apt.llvm.org/llvm-snapshot.gpg.key | gpg --dearmor -o /etc/apt/keyrings/llvm.gpg
echo "deb [signed-by=/etc/apt/keyrings/llvm.gpg] http://apt.llvm.org/resolute/ llvm-toolchain-resolute-${LLVM_VERSION} main" > /etc/apt/sources.list.d/llvm.list

apt-get update
apt-get install -y --no-install-recommends \
    clang-${LLVM_VERSION} lld-${LLVM_VERSION} \
    llvm-${LLVM_VERSION}
rm -rf /var/lib/apt/lists/*

for tool in /usr/bin/*-${LLVM_VERSION}; do
    [ -x "$tool" ] || continue
    name="${tool%-${LLVM_VERSION}}"
    ln -sf "$tool" "$name"
done

curl -fsSL https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}-linux-$(uname -m).sh -o /tmp/cmake.sh

mkdir /opt/cmake
sh /tmp/cmake.sh \
    --skip-license \
    --prefix=/opt/cmake
rm -f /tmp/cmake.sh
