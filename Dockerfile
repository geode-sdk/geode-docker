# syntax=docker/dockerfile:1.7
ARG UBUNTU_VERSION=26.04
ARG OSXCROSS_VERSION=26.1
ARG GEODE_CLI_VERSION=latest
ARG GEODE_SDK_VERSION=latest
ARG LLVM_VERSION=22

#
# osxcross (for MacOS / iOS)
#
FROM crazymax/osxcross:${OSXCROSS_VERSION}-ubuntu AS osxcross

#
# Base setup
#
FROM ubuntu:${UBUNTU_VERSION} AS geode-tools-base
ARG LLVM_VERSION

ENV DEBIAN_FRONTEND=noninteractive \
    GEODE_SDK=/opt/geode \
    PATH=/opt/geode-cli:$PATH

COPY ./docker/setup-base.sh /docker/setup-base.sh
RUN bash /docker/setup-base.sh ${LLVM_VERSION}

#
# Theos (for iOS)
#
FROM geode-tools-base AS theos

ENV THEOS=/opt/theos \
    OSXCROSS=/osxcross \
    PATH="/osxcross/target/bin:${PATH}"

COPY ios-sdk.tar.xz /tmp/ios-sdk.tar.xz
COPY ./docker/setup-theos.1.sh /docker/setup-theos.1.sh
RUN --mount=type=secret,id=GITHUB_TOKEN \
    bash /docker/setup-theos.1.sh

WORKDIR /osxcross

RUN echo "1" | UNATTENDED=yes ./build.sh

COPY ./docker/setup-theos.2.sh /docker/setup-theos.2.sh
RUN --mount=type=secret,id=GITHUB_TOKEN \
    bash /docker/setup-theos.2.sh

#
# Geode SDK base
#
FROM geode-tools-base AS geode-sdk-base
ARG GEODE_SDK_VERSION

COPY ./docker/setup-sdk.sh /docker/setup-sdk.sh
RUN --mount=type=secret,id=GITHUB_TOKEN \
    bash /docker/setup-sdk.sh ${GEODE_SDK_VERSION}

#
# Tools / Windows (Cross compilation CMake toolchain)
#
FROM geode-tools-base AS geode-tools-windows
ARG GEODE_CLI_VERSION
ARG TARGETARCH

COPY ./docker/setup-cli.sh /docker/setup-cli.sh
RUN --mount=type=secret,id=GITHUB_TOKEN \
    bash /docker/setup-cli.sh ${GEODE_CLI_VERSION} ${TARGETARCH}

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
RUN --mount=type=secret,id=GITHUB_TOKEN \
    bash /docker/setup-android.sh ${TARGETARCH} ${ANDROID_NDK_ROOT} ${ANDROID_NDK_VERSION}

COPY ./docker/setup-cli.sh /docker/setup-cli.sh
RUN --mount=type=secret,id=GITHUB_TOKEN \
    bash /docker/setup-cli.sh ${GEODE_CLI_VERSION} ${TARGETARCH}

#
# Tools / MacOS (osxcross)
#
FROM geode-tools-base AS geode-tools-macos
ARG GEODE_CLI_VERSION
ARG TARGETARCH

ENV PATH="/osxcross/bin:${PATH}"

COPY --from=osxcross /osxcross /osxcross

COPY ./docker/macos-toolchain.cmake /docker/macos-toolchain.cmake
COPY ./docker/setup-mac.sh /docker/setup-mac.sh
RUN bash /docker/setup-mac.sh /docker/macos-toolchain.cmake

COPY ./docker/setup-cli.sh /docker/setup-cli.sh
RUN --mount=type=secret,id=GITHUB_TOKEN \
    bash /docker/setup-cli.sh ${GEODE_CLI_VERSION} ${TARGETARCH}

#
# Tools / iOS (theos)
#
FROM geode-tools-base AS geode-tools-ios
ARG GEODE_CLI_VERSION
ARG TARGETARCH

ENV OSXCROSS=/osxcross \
    THEOS=/opt/theos \
    PATH="${OSXCROSS}/target/bin:${PATH}"

COPY --from=theos /osxcross /osxcross
COPY --from=theos /opt/theos /opt/theos

COPY ./docker/ios-toolchain.cmake /docker/ios-toolchain.cmake
COPY ./docker/setup-ios.sh /docker/setup-ios.sh
RUN bash /docker/setup-ios.sh /docker/ios-toolchain.cmake

COPY ./docker/setup-cli.sh /docker/setup-cli.sh
RUN --mount=type=secret,id=GITHUB_TOKEN \
    bash /docker/setup-cli.sh ${GEODE_CLI_VERSION} ${TARGETARCH}

#
# SDK / Windows
#
FROM geode-tools-windows AS geode-sdk-windows

COPY --from=geode-sdk-base /opt/geode /opt/geode

RUN set -eux; \
    geode sdk install-binaries -p windows

#
# SDK / Android
#
FROM geode-tools-android AS geode-sdk-android

COPY --from=geode-sdk-base /opt/geode /opt/geode

RUN set -eux; \
    geode sdk install-binaries -p android32; \
    geode sdk install-binaries -p android64

#
# SDK / MacOS
#
FROM geode-tools-macos AS geode-sdk-macos

COPY --from=geode-sdk-base /opt/geode /opt/geode

RUN set -eux; \
    geode sdk install-binaries -p mac

#
# SDK / iOS
#
FROM geode-tools-ios AS geode-sdk-ios

COPY --from=geode-sdk-base /opt/geode /opt/geode

RUN set -eux; \
    geode sdk install-binaries -p ios
