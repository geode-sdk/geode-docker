#!/usr/bin/env bash
set -eux

GITHUB_TOKEN=$(cat /run/secrets/GITHUB_TOKEN 2>/dev/null || true)
AUTH_HEADER=""
GEODE_CLI_VERSION=$1
TARGETARCH=$2

if [ -n "$GITHUB_TOKEN" ]; then
    AUTH_HEADER="Authorization: Bearer $GITHUB_TOKEN"
fi

if [ "${GEODE_CLI_VERSION}" = "latest" ]; then
    GEODE_CLI_REQUEST="$(curl -fsSL ${AUTH_HEADER:+-H "$AUTH_HEADER"} https://api.github.com/repos/geode-sdk/cli/releases/latest)"
    GEODE_CLI_VERSION="$(echo $GEODE_CLI_REQUEST | grep -Po '"tag_name":\s*"\Kv[^"]+')"
fi

echo "Installing Geode CLI ${GEODE_CLI_VERSION}"

if [ "${TARGETARCH}" = "arm64" ]; then
    CLI_SUFFIX="linux-arm"
else
    CLI_SUFFIX="linux"
fi

curl -fsSL "https://github.com/geode-sdk/cli/releases/download/${GEODE_CLI_VERSION}/geode-cli-${GEODE_CLI_VERSION}-${CLI_SUFFIX}.zip" -o /tmp/geode-cli.zip

unzip -q /tmp/geode-cli.zip -d /opt/geode-cli
rm /tmp/geode-cli.zip
chmod +x /opt/geode-cli/geode
ln -sf /opt/geode-cli/geode /usr/local/bin/geode

CLI_PROFILE="/root/.config/geode"
mkdir -p "${CLI_PROFILE}/geode/mods" "${CLI_PROFILE}/Contents/geode/mods"
geode profile add --name DockerProfile "${CLI_PROFILE}/GeometryDash.exe" win
geode profile add --name DockerProfileMac "${CLI_PROFILE}/GeometryDash" mac
