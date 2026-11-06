# Geode SDK Docker

<!--
![Build Docker Images](https://github.com/prevter/geode-docker/actions/workflows/build-images.yml/badge.svg)
[![Docker Hub](https://img.shields.io/badge/docker-hub-blue?logo=docker)](https://hub.docker.com/r/prevter/geode-sdk)
-->

This repository contains the Dockerfile to build the Geode SDK cross-compilation toolchain
that runs on a Linux host and can build mods for Windows, Android, macOS and iOS.

## Available Tags

TODO: add the table back

<!--
| Platform     | Tags                                         | Image size |
|--------------|----------------------------------------------|------------|
| Windows      | `windows`, `windows-latest`, `windows-5.9.0` | ![Docker Image Size (tag)](https://img.shields.io/docker/image-size/prevter/geode-sdk/windows?label=%20) |
| Android32/64 | `android`, `android-latest`, `android-5.9.0` | ![Docker Image Size (tag)](https://img.shields.io/docker/image-size/prevter/geode-sdk/android?label=%20) |
| macOS        | `macos`, `macos-latest`, `macos-5.9.0`       | ![Docker Image Size (tag)](https://img.shields.io/docker/image-size/prevter/geode-sdk/macos?label=%20) |
| iOS          | `ios`, `ios-latest`, `ios-5.9.0`             | ![Docker Image Size (tag)](https://img.shields.io/docker/image-size/prevter/geode-sdk/ios?label=%20) |

> [!NOTE]
> The `-latest` tags are an alias for non-tagged builds. `windows` and `windows-latest` are identical.

-->

## Usage

Each image already contains pre-installed Geode SDK and the CLI alongside the toolchains required for that specific platform.

Navigate to the root of your mod project and run the following command:

```bash
docker run --rm -it -v .:/code -w /code ghcr.io/geode-sdk/geode:<platform>-<version>
```
*(replace `<platform>` with `windows`, `android`, `macos` or `ios`)* \
*(replace `<version>` with a Geode version, such as `6.0.0-alpha.1`)*

> [!TIP]
> ```bash
> # Example
> docker run --rm -it -v .:/code -w /code ghcr.io/geode-sdk/geode:windows-6.0.0-alpha.1
> ```

This should drop you into a bash shell with configured toolchain. To compile your mod, simply run the following commands:

```bash
# To configure
cmake --preset <platform> --presets-file /docker/CMakePresets.json

# To build
cmake --build --preset <platform> --presets-file /docker/CMakePresets.json
```

The available platform presets are:
```
"win"             - Docker Windows x64 build
"android32"       - Docker Android ARMv7 build
"android64"       - Docker Android AARCH64 build
"mac"             - Docker MacOS x64 - AARCH64 build
"ios"             - Docker iOS AARCH64 build
"win-debug"       - Docker Windows x64 build - debug
"android32-debug" - Docker Android ARMv7 - debug
"android64-debug" - Docker Android AARCH64 - debug
"mac-debug"       - Docker MacOS x64 - AARCH64 build - debug
"ios-debug"       - Docker iOS AARCH64 build - debug
```

## Mounts

You can mount your existing CPM cache into `/cpm-cache` with `-v "$CPM_SOURCE_CACHE:/cpm-cache"` in the docker call for improved compile times.

You can also mount external mods into `/mods`, incase of external dependencies.

## License

This project is licensed under the Boost Software License 1.0. See the [LICENSE](LICENSE.txt) file for details.
