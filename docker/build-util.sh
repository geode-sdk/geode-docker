#!/usr/bin/env bash

set -euo pipefail

# replaced on built images
DEFAULT_PRESET="_"

usage() {
  cat <<EOF
Configures and builds a CMake project using a preset from the docker image

Usage: ${0##*/} [OPTIONS] [PRESET] [-- EXTRA_ARGS...]

Arguments:
  PRESET           CMake preset to use (default: $DEFAULT_PRESET)

Options:
  -c, --configure  Only run cmake configure
  -b, --build      Only run cmake build
  -h, --help       Show this help and exit

Everything after '--' is passed directly to cmake

EOF
}

configure=1
build=1
arg1=()
passthrough=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
      usage
      exit 0
      ;;
    -b|--build)
      configure=0
      shift
      ;;
    -c|--configure)
      build=0
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

if (( configure )); then
  set -x
  cmake --preset $preset --presets-file /docker/CMakePresets.json "${passthrough[@]}"
  if (( build )); then
    cmake --build --preset $preset --presets-file /docker/CMakePresets.json --parallel
  fi
elif (( build )); then
  # add --parallel when no passthrough args
  if (( ${#passthrough[@]} == 0 )); then
    passthrough=(--parallel)
  fi
  set -x
  cmake --build --preset $preset --presets-file /docker/CMakePresets.json "${passthrough[@]}"
else
  echo "Invalid args: cant have both -b and -c" >&2
  exit 1
fi
