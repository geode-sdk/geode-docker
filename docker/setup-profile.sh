#!/usr/bin/env bash
set -eux
set -o pipefail

chmod +x /opt/geode-cli/geode
ln -sf /opt/geode-cli/geode /usr/local/bin/geode

mkdir -p /mods

CLI_PROFILE="/root/.config/geode"
mkdir -p "${CLI_PROFILE}/geode" "${CLI_PROFILE}/Contents/geode"
ln -sf /mods "${CLI_PROFILE}/geode/mods"
ln -sf /mods "${CLI_PROFILE}/Contents/geode/mods"
geode profile add --name DockerProfile "${CLI_PROFILE}/GeometryDash.exe" win
geode profile add --name DockerProfileMac "${CLI_PROFILE}/GeometryDash" mac

su ubuntu -c bash <<EOF

CLI_PROFILE="/home/ubuntu/.config/geode"
mkdir -p "\${CLI_PROFILE}/geode" "\${CLI_PROFILE}/Contents/geode"
ln -sf /mods "\${CLI_PROFILE}/geode/mods"
ln -sf /mods "\${CLI_PROFILE}/Contents/geode/mods"
geode profile add --name DockerProfile "\${CLI_PROFILE}/GeometryDash.exe" win
geode profile add --name DockerProfileMac "\${CLI_PROFILE}/GeometryDash" mac
git config --global --add safe.directory '*'

EOF
# helps with "dubious ownership" in cpm-cache directories and /bindings
git config --global --add safe.directory '*'
