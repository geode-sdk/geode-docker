#!/usr/bin/env bash
set -eux
set -o pipefail

PRESET=$1

sed "s|DEFAULT_PRESET=\"_\"|DEFAULT_PRESET=\"$PRESET\"|" ./docker/build-util.sh > /usr/bin/build
chmod +x /usr/bin/build
rm ./docker/build-util.sh
