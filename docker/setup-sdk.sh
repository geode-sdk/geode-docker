#!/usr/bin/env bash
set -eux

GITHUB_TOKEN=$(cat /run/secrets/GITHUB_TOKEN 2>/dev/null || true)
GEODE_SDK_VERSION=$1

apt-get update
apt-get install -y --no-install-recommends \
    ca-certificates curl jq git
rm -rf /var/lib/apt/lists/*

if [ -n "$GITHUB_TOKEN" ]; then
    AUTH_HEADER="Authorization: Bearer $GITHUB_TOKEN"
fi

case "${GEODE_SDK_VERSION}" in
    nightly)
        git clone --depth 1 --branch nightly https://github.com/geode-sdk/geode.git "${GEODE_SDK}" ;;
    latest)
        GEODE_SDK_LATEST_VERSION="$(
            curl -fsSL ${AUTH_HEADER:+-H "$AUTH_HEADER"} https://api.github.com/repos/geode-sdk/geode/releases/latest |
            jq -r '.tag_name'
        )"

        git clone --depth 1 --branch "${GEODE_SDK_LATEST_VERSION}" https://github.com/geode-sdk/geode.git "${GEODE_SDK}" ;;
    *)
        git clone --depth 1 --branch "${GEODE_SDK_VERSION}" https://github.com/geode-sdk/geode.git "${GEODE_SDK}" ;;
esac
