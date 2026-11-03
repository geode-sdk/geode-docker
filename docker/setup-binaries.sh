#!/usr/bin/env bash
set -eux

GITHUB_TOKEN=$(cat /run/secrets/GITHUB_TOKEN 2>/dev/null || true)
AUTH_HEADER=""
PLATFORM_SUFFIX=$1
GEODE_SDK_VERSION=$2

if [ -n "$GITHUB_TOKEN" ]; then
    AUTH_HEADER="Authorization: Bearer $GITHUB_TOKEN"
fi

BIN_FOLDER_NAME=""
case "${GEODE_SDK_VERSION}" in
    nightly)
        GEODE_SDK_REQUEST="$(curl -fsSL ${AUTH_HEADER:+-H "$AUTH_HEADER"} https://api.github.com/repos/geode-sdk/geode/releases/latest)"
        GEODE_SDK_COMMIT="$(echo $GEODE_SDK_REQUEST | grep -Po '"tag_name":\s*"\Kv[^"]+')"

        curl -fsSL ${AUTH_HEADER:+-H "$AUTH_HEADER"} \
            "https://github.com/geode-sdk/geode/releases/download/nightly/geode-${GEODE_SDK_COMMIT}-${PLATFORM_SUFFIX}.zip" \
            -o /tmp/geode-bin.zip

        BIN_FOLDER_NAME="nightly" ;;
    latest)
        GEODE_SDK_LATEST_VERSION="$(
            curl -fsSL ${AUTH_HEADER:+-H "$AUTH_HEADER"} https://api.github.com/repos/geode-sdk/geode/releases/latest |
            jq -r '.tag_name'
        )"

        curl -fsSL ${AUTH_HEADER:+-H "$AUTH_HEADER"} \
            "https://github.com/geode-sdk/geode/releases/download/${GEODE_SDK_LATEST_VERSION}/geode-${GEODE_SDK_LATEST_VERSION}-${PLATFORM_SUFFIX}.zip" \
            -o /tmp/geode-bin.zip

        BIN_FOLDER_NAME="${GEODE_SDK_LATEST_VERSION:1}" ;;
    *)
        curl -fsSL ${AUTH_HEADER:+-H "$AUTH_HEADER"} \
            "https://github.com/geode-sdk/geode/releases/download/${GEODE_SDK_VERSION}/geode-${GEODE_SDK_VERSION}-${PLATFORM_SUFFIX}.zip" \
            -o /tmp/geode-bin.zip

        BIN_FOLDER_NAME="${GEODE_SDK_VERSION:1}" ;;
esac

mkdir -p "/opt/geode/bin/${BIN_FOLDER_NAME}"
unzip -q /tmp/geode-bin.zip -d /opt/geode/bin/${BIN_FOLDER_NAME}
rm /tmp/geode-bin.zip
