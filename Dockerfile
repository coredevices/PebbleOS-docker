# Copyright (c) 2025 Core Devices LLC
# SPDX-License-Identifier: Apache-2.0

FROM ubuntu:24.04

ARG PEBBLEOS_SDK_VERSION=0.1.0

ENV PEBBLEOS_SDK_VERSION=$PEBBLEOS_SDK_VERSION

# Set default shell during Docker image build to bash
SHELL ["/bin/bash", "-c"]

# Set non-interactive frontend for apt-get to skip any user confirmations
ENV DEBIAN_FRONTEND=noninteractive

# Install system-level dependencies
RUN apt-get -y update && \
    apt-get install -y --no-install-recommends \
    bison \
    clang \
    flex \
    gcc \
    gcc-multilib \
    gperf \
    git \
    gettext \
    libfreetype6-dev \
    libglib2.0-dev \
    libgtk-3-dev \
    libncurses-dev \
    librsvg2-bin \
    make \
    nodejs \
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
ENV PEBBLEOS_SDK_ROOT=/opt/pebbleos-sdk
RUN wget -qO- "https://github.com/coredevices/PebbleOS-SDK/releases/download/v${PEBBLEOS_SDK_VERSION}/pebbleos-sdk-installer.sh" \
    | sh -s -- --version "${PEBBLEOS_SDK_VERSION}" --prefix "${PEBBLEOS_SDK_ROOT}" --defaults

# Create Python virtual environment
RUN python3 -m venv /opt/venv

ENV PATH="/opt/venv/bin:$PATH"

COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["/bin/bash"]
