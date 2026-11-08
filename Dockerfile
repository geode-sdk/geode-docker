# syntax=docker/dockerfile:1.7
ARG UBUNTU_VERSION=26.10
ARG OSXCROSS_VERSION=26.1
ARG GEODE_CLI_VERSION=latest
ARG GEODE_SDK_VERSION=latest
ARG LLVM_VERSION=23
ARG CMAKE_VERSION=4.4.5

#
# osxcross (for MacOS / iOS)
#
FROM crazymax/osxcross:${OSXCROSS_VERSION}-ubuntu AS osxcross

#
# Base setup
#
FROM ubuntu:${UBUNTU_VERSION} AS geode-tools-base
ARG LLVM_VERSION
ARG CMAKE_VERSION

ENV DEBIAN_FRONTEND=noninteractive
ENV GEODE_SDK=/opt/geode
ENV SCCACHE_DIR=/opt/sccache/cache
ENV PATH=/opt/geode-cli:$PATH

COPY ./docker/setup-base.sh /docker/setup-base.sh
RUN bash /docker/setup-base.sh ${LLVM_VERSION} ${CMAKE_VERSION}
ENV PATH=/opt/cmake/bin:$PATH

#
# Theos (for iOS)
#
FROM geode-tools-base AS theos
ARG LLVM_VERSION

ENV THEOS=/opt/theos
ENV OSXCROSS=/osxcross
ENV PATH="/osxcross/target/bin:${PATH}"

COPY ios-sdk.tar.xz /tmp/ios-sdk.tar.xz
COPY ./docker/setup-theos.1.sh /docker/setup-theos.1.sh
RUN --mount=type=secret,id=GITHUB_TOKEN \
    bash /docker/setup-theos.1.sh ${LLVM_VERSION}

WORKDIR /osxcross

RUN echo "1" | UNATTENDED=yes ./build.sh

COPY ./docker/setup-theos.2.sh /docker/setup-theos.2.sh
RUN --mount=type=secret,id=GITHUB_TOKEN \
    bash /docker/setup-theos.2.sh

#
# Geode SDK base
#
FROM ubuntu:${UBUNTU_VERSION} AS geode-sdk-base
ARG GEODE_SDK_VERSION

ENV GEODE_SDK=/opt/geode
ENV GEODE_BINDINGS_REPO_PATH=/bindings

COPY ./docker/setup-sdk.sh /docker/setup-sdk.sh
RUN --mount=type=secret,id=GITHUB_TOKEN \
    bash /docker/setup-sdk.sh ${GEODE_SDK_VERSION}

#
# Geode CLI base
#
FROM geode-tools-base AS geode-cli-base
ARG GEODE_CLI_VERSION
ARG TARGETARCH

COPY ./docker/setup-cli.sh /docker/setup-cli.sh
RUN --mount=type=secret,id=GITHUB_TOKEN \
    bash /docker/setup-cli.sh ${GEODE_CLI_VERSION} ${TARGETARCH}

#
# Tools / Windows (Cross compilation CMake toolchain)
#
FROM geode-tools-base AS geode-tools-windows
ARG TARGETARCH

ENV WIN_CROSS_ROOT=/opt/win-cross

COPY ./docker/setup-windows.sh /docker/setup-windows.sh
RUN --mount=type=secret,id=GITHUB_TOKEN \
    bash /docker/setup-windows.sh
ENV GEODE_CMAKE_TOOLCHAIN=$WIN_CROSS_ROOT/clang-msvc-sdk/clang-msvc.cmake

COPY --from=geode-cli-base /opt/geode-cli/geode /opt/geode-cli/geode
COPY ./docker/setup-profile.sh /docker/setup-profile.sh
RUN bash /docker/setup-profile.sh

#
# Tools / Android (Android NDK)
#
FROM geode-tools-base AS geode-tools-android
ARG ANDROID_NDK_VERSION=r29
ARG TARGETARCH

ENV ANDROID_NDK_ROOT=/opt/android-ndk

COPY ./docker/setup-android.sh /docker/setup-android.sh
RUN --mount=type=secret,id=GITHUB_TOKEN \
    bash /docker/setup-android.sh ${TARGETARCH} ${ANDROID_NDK_ROOT} ${ANDROID_NDK_VERSION}
ENV GEODE_CMAKE_TOOLCHAIN=$ANDROID_NDK_ROOT/build/cmake/android.toolchain.cmake

COPY --from=geode-cli-base /opt/geode-cli/geode /opt/geode-cli/geode
COPY ./docker/setup-profile.sh /docker/setup-profile.sh
RUN bash /docker/setup-profile.sh

#
# Tools / MacOS (osxcross)
#
FROM geode-tools-base AS geode-tools-macos

ENV PATH="/osxcross/bin:${PATH}"
ENV LD_LIBRARY_PATH="/osxcross/lib:${LD_LIBRARY_PATH}"

COPY --from=osxcross /osxcross /osxcross

COPY ./docker/macos.toolchain.cmake /docker/macos.toolchain.cmake
COPY ./docker/setup-mac.sh /docker/setup-mac.sh
RUN bash /docker/setup-mac.sh
ENV GEODE_CMAKE_TOOLCHAIN=/docker/macos.toolchain.cmake

COPY --from=geode-cli-base /opt/geode-cli/geode /opt/geode-cli/geode
COPY ./docker/setup-profile.sh /docker/setup-profile.sh
RUN bash /docker/setup-profile.sh

#
# Tools / iOS (theos)
#
FROM geode-tools-base AS geode-tools-ios

ENV OSXCROSS=/osxcross
ENV THEOS=/opt/theos
ENV PATH="${OSXCROSS}/target/bin:${PATH}"

COPY --from=theos /osxcross /osxcross
COPY --from=theos /opt/theos /opt/theos

COPY ./docker/ios.toolchain.cmake /docker/ios.toolchain.cmake
COPY ./docker/setup-ios.sh /docker/setup-ios.sh
RUN bash /docker/setup-ios.sh
ENV GEODE_CMAKE_TOOLCHAIN=/docker/ios.toolchain.cmake

COPY --from=geode-cli-base /opt/geode-cli/geode /opt/geode-cli/geode
COPY ./docker/setup-profile.sh /docker/setup-profile.sh
RUN bash /docker/setup-profile.sh

#
# SDK / Windows
#
FROM geode-tools-windows AS geode-sdk-windows
ARG GEODE_SDK_VERSION

ENV GEODE_BINDINGS_REPO_PATH=/bindings
COPY --from=geode-sdk-base /bindings /bindings
COPY --from=geode-sdk-base /opt/geode /opt/geode

COPY ./docker/setup-binaries.sh /docker/setup-binaries.sh
RUN bash /docker/setup-binaries.sh win ${GEODE_SDK_VERSION}
COPY ./docker/CMakePresets.json /docker/CMakePresets.json
ENV CPM_SOURCE_CACHE=/cpm-cache

#
# SDK / Android
#
FROM geode-tools-android AS geode-sdk-android
ARG GEODE_SDK_VERSION

ENV GEODE_BINDINGS_REPO_PATH=/bindings
COPY --from=geode-sdk-base /bindings /bindings
COPY --from=geode-sdk-base /opt/geode /opt/geode

COPY ./docker/setup-binaries.sh /docker/setup-binaries.sh
RUN bash /docker/setup-binaries.sh android32 ${GEODE_SDK_VERSION}
RUN bash /docker/setup-binaries.sh android64 ${GEODE_SDK_VERSION}
COPY ./docker/CMakePresets.json /docker/CMakePresets.json
ENV CPM_SOURCE_CACHE=/cpm-cache

#
# SDK / MacOS
#
FROM geode-tools-macos AS geode-sdk-macos
ARG GEODE_SDK_VERSION

ENV GEODE_BINDINGS_REPO_PATH=/bindings
COPY --from=geode-sdk-base /bindings /bindings
COPY --from=geode-sdk-base /opt/geode /opt/geode

COPY ./docker/setup-binaries.sh /docker/setup-binaries.sh
RUN bash /docker/setup-binaries.sh mac ${GEODE_SDK_VERSION}
COPY ./docker/CMakePresets.json /docker/CMakePresets.json
ENV CPM_SOURCE_CACHE=/cpm-cache

#
# SDK / iOS
#
FROM geode-tools-ios AS geode-sdk-ios
ARG GEODE_SDK_VERSION

ENV GEODE_BINDINGS_REPO_PATH=/bindings
COPY --from=geode-sdk-base /bindings /bindings
COPY --from=geode-sdk-base /opt/geode /opt/geode

COPY ./docker/setup-binaries.sh /docker/setup-binaries.sh
RUN bash /docker/setup-binaries.sh ios ${GEODE_SDK_VERSION}
COPY ./docker/CMakePresets.json /docker/CMakePresets.json
ENV CPM_SOURCE_CACHE=/cpm-cache
