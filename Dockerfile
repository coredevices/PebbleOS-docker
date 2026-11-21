# Copyright (c) 2025 Core Devices LLC
# SPDX-License-Identifier: Apache-2.0

FROM ubuntu:24.04

ARG PEBBLEOS_SDK_VERSION=0.1.17

ENV PEBBLEOS_SDK_VERSION=$PEBBLEOS_SDK_VERSION

# Set default shell during Docker image build to bash
SHELL ["/bin/bash", "-c"]

# Set non-interactive frontend for apt-get to skip any user confirmations
ENV DEBIAN_FRONTEND=noninteractive

# Install system-level dependencies
RUN apt-get -y update && \
    apt-get install -y --no-install-recommends \
    bison \
    ccache \
    clang \
    cmake \
    device-tree-compiler \
    flex \
    gcc \
    gcc-multilib \
    gperf \
    git \
    gettext \
    libfreetype6-dev \
    libclang-dev \
    libglib2.0-dev \
    libgtk-3-dev \
    libncurses-dev \
    librsvg2-bin \
    libsdl2-dev \
    make \
    ninja-build \
    nodejs \
    pkg-config \
    python3-dev \
    python3-pip \
    python3-venv \
    xz-utils \
    wget \
    && rm -rf /var/lib/apt/lists/*

# Install latest Doxygen
# The version of Doxygen in Ubuntu's repos is old, and generates docs with missing functions
RUN wget -O doxygen.tar.gz "https://www.doxygen.nl/files/doxygen-1.14.0.linux.bin.tar.gz" && \
    tar xf doxygen.tar.gz && \
    mv doxygen-1.14.0/bin/* /usr/bin/ && \
    rm -r doxygen-1.14.0 doxygen.tar.gz

# Install PebbleOS SDK
RUN wget -qO- "https://github.com/coredevices/PebbleOS-SDK/releases/download/v${PEBBLEOS_SDK_VERSION}/pebbleos-sdk-installer.sh" \
    | sh -s -- --version "${PEBBLEOS_SDK_VERSION}" --prefix /opt/pebbleos-sdk --defaults

# Install Emscripten, which builds the native boards as WebAssembly
ARG EMSCRIPTEN_VERSION=6.0.12
RUN git clone --depth 1 --branch "${EMSCRIPTEN_VERSION}" https://github.com/emscripten-core/emsdk.git /opt/emsdk && \
    /opt/emsdk/emsdk install "${EMSCRIPTEN_VERSION}" && \
    /opt/emsdk/emsdk activate "${EMSCRIPTEN_VERSION}" && \
    rm -rf /opt/emsdk/downloads

ENV EMSDK=/opt/emsdk
ENV PATH="/opt/emsdk:/opt/emsdk/upstream/emscripten:$PATH"

# Install Rust, for applications written in Rust, and bindgen for their
# bindings. rust-toolchain.toml in the PebbleOS checkout picks the version.
ARG RUST_VERSION=1.100
ARG BINDGEN_VERSION=0.73.2
ENV RUSTUP_HOME=/opt/rustup
ENV CARGO_HOME=/opt/cargo
ENV PATH="/opt/cargo/bin:$PATH"
RUN wget -qO- https://sh.rustup.rs | sh -s -- -y --no-modify-path --profile minimal \
        --default-toolchain "${RUST_VERSION}" \
        --component clippy,rustfmt \
        --target thumbv7em-none-eabi,thumbv7em-none-eabihf,thumbv8m.main-none-eabi,thumbv8m.main-none-eabihf,wasm32-unknown-emscripten && \
    cargo install bindgen-cli --locked --version "${BINDGEN_VERSION}" && \
    rm -rf /opt/cargo/registry /opt/cargo/git

# Create Python virtual environment
RUN python3 -m venv /opt/venv

ENV PATH="/opt/venv/bin:$PATH"
