#!/usr/bin/env bash
set -eux

GEODE_SDK_VERSION=$1

echo "Installing Geode SDK ${GEODE_SDK_VERSION}"

geode sdk install "${GEODE_SDK}";
case "${GEODE_SDK_VERSION}" in
    nightly) geode sdk update nightly ;;
    latest)  geode sdk update stable ;;
    *)       geode sdk update "${GEODE_SDK_VERSION}" ;;
esac;
