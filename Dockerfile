# syntax=docker/dockerfile:1.7
ARG UBUNTU_VERSION=26.04
ARG OSXCROSS_VERSION=latest
ARG GEODE_CLI_VERSION=latest
ARG LLVM_VERSION=22

#
# osxcross (for MacOS / iOS)
#
FROM crazymax/osxcross:${OSXCROSS_VERSION}-ubuntu AS osxcross

ENV OSXCROSS=/osxcross \
    PATH="/osxcross/target/bin:${PATH}"

#
# Theos (for iOS)
#
FROM osxcross AS theos

ENV THEOS=/opt/theos

COPY ios-sdk.tar.xz /tmp/ios-sdk.tar.xz
COPY ./docker/setup-theos.sh /docker/setup-theos.sh

RUN bash ./docker/setup-theos.sh

#
# Base setup
#
FROM ubuntu:${UBUNTU_VERSION} AS geode-tools-base
ARG LLVM_VERSION

ENV DEBIAN_FRONTEND=noninteractive \
    GEODE_SDK=/opt/geode \
    PATH=/opt/geode-cli:$PATH

COPY ./docker/setup-base.sh /docker/setup-base.sh

RUN bash ./docker/setup-base.sh ${LLVM_VERSION}

#
# Tools / Windows (Cross compilation CMake toolchain)
#
FROM geode-tools-base AS geode-tools-windows
ARG GEODE_CLI_VERSION
ARG TARGETARCH

COPY ./docker/setup-cli.sh /docker/setup-cli.sh

RUN --mount=type=secret,id=GITHUB_TOKEN \
    bash ./docker/setup-cli.sh ${GEODE_CLI_VERSION} ${TARGETARCH}

RUN set -eux; \
    geode sdk install-linux

#
# Tools / Android (Android NDK)
#
FROM geode-tools-base AS geode-tools-android
ARG ANDROID_NDK_VERSION=r29
ARG GEODE_CLI_VERSION
ARG TARGETARCH

ENV ANDROID_NDK_ROOT=/opt/android-ndk

COPY ./docker/setup-android.sh /docker/setup-android.sh

RUN bash ./docker/setup-android.sh ${TARGETARCH} ${ANDROID_NDK_ROOT} ${ANDROID_NDK_VERSION}

COPY ./docker/setup-cli.sh /docker/setup-cli.sh

RUN --mount=type=secret,id=GITHUB_TOKEN \
    bash ./docker/setup-cli.sh ${GEODE_CLI_VERSION} ${TARGETARCH}

#
# Tools / MacOS (osxcross)
#
FROM geode-tools-base AS geode-tools-macos
ARG GEODE_CLI_VERSION
ARG TARGETARCH

# ENV PATH="/osxcross/bin:${PATH}" \
#     LD_LIBRARY_PATH="/osxcross/lib:${LD_LIBRARY_PATH}"

COPY --from=osxcross /osxcross /osxcross
COPY ./docker/macos-toolchain.cmake /docker/macos-toolchain.cmake
COPY ./docker/setup-mac.sh /docker/setup-mac.sh

RUN bash /docker/setup-mac.sh /docker/macos-toolchain.cmake

COPY ./docker/setup-cli.sh /docker/setup-cli.sh

RUN --mount=type=secret,id=GITHUB_TOKEN \
    bash ./docker/setup-cli.sh ${GEODE_CLI_VERSION} ${TARGETARCH}

#
# Tools / iOS (theos)
#
FROM geode-tools-base AS geode-tools-ios

# ENV OSXCROSS=/osxcross \
#     THEOS=/opt/theos \
#     PATH="${OSXCROSS}/target/bin:${PATH}"

COPY ios-sdk.tar.xz /tmp/ios-sdk.tar.xz

COPY --from=theos /osxcross /osxcross
COPY --from=theos /opt/theos /opt/theos
COPY ./docker/ios-toolchain.cmake /docker/ios-toolchain.cmake
COPY ./docker/setup-ios.sh /docker/setup-ios.sh

RUN bash /docker/setup-ios.sh /docker/ios-toolchain.cmake

COPY ./docker/setup-cli.sh /docker/setup-cli.sh

RUN --mount=type=secret,id=GITHUB_TOKEN \
    bash ./docker/setup-cli.sh ${GEODE_CLI_VERSION} ${TARGETARCH}

#
# SDK / Windows
#
FROM geode-tools-windows AS geode-sdk-windows
ARG GEODE_SDK_VERSION

COPY ./docker/setup-sdk.sh /docker/setup-sdk.sh

RUN bash ./docker/setup-sdk.sh ${GEODE_SDK_VERSION}

RUN set -eux; \
    geode sdk install-binaries -p windows

#
# SDK / Android
#
FROM geode-tools-android AS geode-sdk-android
ARG GEODE_SDK_VERSION

COPY ./docker/setup-sdk.sh /docker/setup-sdk.sh

RUN bash ./docker/setup-sdk.sh ${GEODE_SDK_VERSION}

RUN set -eux; \
    geode sdk install-binaries -p android32; \
    geode sdk install-binaries -p android64

#
# SDK / MacOS
#
FROM geode-tools-macos AS geode-sdk-macos
ARG GEODE_SDK_VERSION

COPY ./docker/setup-sdk.sh /docker/setup-sdk.sh

RUN bash ./docker/setup-sdk.sh ${GEODE_SDK_VERSION}

RUN set -eux; \
    geode sdk install-binaries -p mac

#
# SDK / MacOS
#
FROM geode-tools-ios AS geode-sdk-ios
ARG GEODE_SDK_VERSION

COPY ./docker/setup-sdk.sh /docker/setup-sdk.sh

RUN bash ./docker/setup-sdk.sh ${GEODE_SDK_VERSION}

RUN set -eux; \
    geode sdk install-binaries -p ios
