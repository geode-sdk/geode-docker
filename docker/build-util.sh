#!/usr/bin/env bash

set -euo pipefail

# replaced on built images
DEFAULT_PRESET="_"

usage() {
  cat <<EOF
Usage: ${0##*/} [OPTIONS] [PRESET] [-- EXTRA_ARGS...]

Arguments:
  PRESET          CMake preset to use (default: $DEFAULT_PRESET)

Options:
  --build         Runs "cmake --build"
  -h, --help      Show this help and exit

Everything after '--' is passed directly to cmake

EOF
}

build=0
arg1=()
passthrough=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
      usage
      exit 0
      ;;
    --build)
      build=1
      shift
      ;;
    --)
      shift
      passthrough=("$@")
      break
      ;;
    -*)
      echo "Unknown option: $1" >&2
      exit 1
      ;;
    *)
      arg1+=("$1")
      shift
      ;;
  esac
done

preset="${arg1[0]:-$DEFAULT_PRESET}"

if (( build )); then
  set -x
  cmake --build --preset $preset --presets-file /docker/CMakePresets.json "${passthrough[@]}"
else
  set -x
  cmake --preset $preset --presets-file /docker/CMakePresets.json "${passthrough[@]}"
fi
