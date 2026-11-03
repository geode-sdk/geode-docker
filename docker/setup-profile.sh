#!/usr/bin/env bash
set -eux

chmod +x /opt/geode-cli/geode
ln -sf /opt/geode-cli/geode /usr/local/bin/geode

CLI_PROFILE="/root/.config/geode"
mkdir -p "${CLI_PROFILE}/geode/mods" "${CLI_PROFILE}/Contents/geode/mods"
geode profile add --name DockerProfile "${CLI_PROFILE}/GeometryDash.exe" win
geode profile add --name DockerProfileMac "${CLI_PROFILE}/GeometryDash" mac

su ubuntu -c bash <<EOF

CLI_PROFILE="/home/ubuntu/.config/geode"
mkdir -p "\${CLI_PROFILE}/geode/mods" "\${CLI_PROFILE}/Contents/geode/mods"
geode profile add --name DockerProfile "\${CLI_PROFILE}/GeometryDash.exe" win
geode profile add --name DockerProfileMac "\${CLI_PROFILE}/GeometryDash" mac

EOF
