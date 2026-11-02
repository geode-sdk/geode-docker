#!/usr/bin/env bash
set -eux

LLVM_VERSION=$1

NODE_VERSION=24
curl -fsSL https://deb.nodesource.com/setup_${NODE_VERSION}.x | bash -
apt-get update
apt-get install -y --no-install-recommends \
    ca-certificates curl gpg nodejs git unzip xz-utils \
    build-essential cmake pkg-config ninja-build jq
rm -rf /var/lib/apt/lists/*

install -d /etc/apt/keyrings
curl -fsSL https://apt.llvm.org/llvm-snapshot.gpg.key | gpg --dearmor -o /etc/apt/keyrings/llvm.gpg
echo "deb [signed-by=/etc/apt/keyrings/llvm.gpg] http://apt.llvm.org/resolute/ llvm-toolchain-resolute-${LLVM_VERSION} main" > /etc/apt/sources.list.d/llvm.list

apt-get update
apt-get install -y --no-install-recommends \
    clang-${LLVM_VERSION} clang-tools-${LLVM_VERSION} lld-${LLVM_VERSION} \
    llvm-${LLVM_VERSION} llvm-${LLVM_VERSION}-dev
rm -rf /var/lib/apt/lists/*

for tool in clang clang++ lld lld-link llvm-ar llvm-ranlib llvm-nm llvm-rc llvm-mt; do
    ln -sf /usr/bin/${tool}-${LLVM_VERSION} /usr/bin/${tool}
done
