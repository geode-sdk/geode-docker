# Geode SDK Docker

![Build Docker Images](https://github.com/prevter/geode-docker/actions/workflows/build-images.yml/badge.svg)
[![Docker Hub](https://img.shields.io/badge/docker-hub-blue?logo=docker)](https://hub.docker.com/r/prevter/geode-sdk)

This repository contains the Dockerfile to build the Geode SDK cross-compilation toolchain
that runs on Linux host and can build mods for Windows, Android, macOS and iOS.

## Available Tags

TODO: these tags are old, now we have tools and geode/sdk

| Platform     | Tags                                         | Image size |
|--------------|----------------------------------------------|------------|
| Windows      | `windows`, `windows-latest`, `windows-5.9.0` | ![Docker Image Size (tag)](https://img.shields.io/docker/image-size/prevter/geode-sdk/windows?label=%20) |
| Android32/64 | `android`, `android-latest`, `android-5.9.0` | ![Docker Image Size (tag)](https://img.shields.io/docker/image-size/prevter/geode-sdk/android?label=%20) |
| macOS        | `macos`, `macos-latest`, `macos-5.9.0`       | ![Docker Image Size (tag)](https://img.shields.io/docker/image-size/prevter/geode-sdk/macos?label=%20) |
| iOS          | `ios`, `ios-latest`, `ios-5.9.0`             | ![Docker Image Size (tag)](https://img.shields.io/docker/image-size/prevter/geode-sdk/ios?label=%20) |

> [!NOTE]
> The `-latest` tags are an alias for non-tagged builds. `windows` and `windows-latest` are identical.

## Usage

Each image already contains pre-installed Geode SDK and the CLI alongside the toolchains required for that specific platform.

Navigate to the root of your mod project and run the following command:

```bash
docker run --rm -it -v ".:/workspace" -w /workspace geode-sdk/geode:<platform> /bin/bash
```
*(replace `<platform>` with `windows`, `android`, `macos` or `ios`)*

This should drop you into a bash shell with configured toolchain. To compile your mod, simply run the following commands:

```bash
# To configure
cmake --preset <platform> --presets-file /docker/CMakePresets.json

# To build
cmake --build --preset <platform> --presets-file /docker/CMakePresets.json
```

*(replace `<platform>` with `win`, `android32`, `android64`, `mac` or `ios`, or their `-debug` variants)*

You can mount your existing CPM cache into `/cpm-cache` with `-v "$CPM_SOURCE_CACHE:/cpm-cache"` in the docker call for improved compile times.

## License

This project is licensed under the Boost Software License 1.0. See the [LICENSE](LICENSE.txt) file for details.
