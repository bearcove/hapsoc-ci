# syntax = docker/dockerfile:1.4

ARG UBUNTU_VERSION="20.04"

##############################################
FROM ubuntu:${UBUNTU_VERSION} AS base
##############################################

ENV DEBIAN_FRONTEND=noninteractive

# Install some utilities
RUN set -eux; \
		apt update; \
		apt install --yes --no-install-recommends \
		# CLI http client & known certificate authorities
		curl ca-certificates \
		# Used by CircleCI, also Renovate
		git ssh \
		# Used to report code coverage
		lcov \
		# Used by the aws-s3 orb
		unzip \
		# Generally useful, to check if a file is a binary
		file \
		less \
		# C & C++ compiler
		gcc g++ \
		# Various build tools
		make pkg-config \
		# Standard C library
		libc6-dev \
		# zlib
		zlib1g-dev \
		# ICU (needed by github actions runner)
		libicu66 \
		# Needed by some crates (quickjs) to apply patches
		patch \
		# Needed by some crates that ship assemby (ravif)
		nasm \
		; \
		apt clean autoclean; \
		apt autoremove --yes; \
		rm -rf /var/lib/{apt,dpkg,cache,log}/

# Various dependencies (github actions edition)
RUN set -eux; \
		apt update; \
		apt install --yes --no-install-recommends \
		; \
		apt clean autoclean; \
		apt autoremove --yes; \
		rm -rf /var/lib/{apt,dpkg,cache,log}/

# Install mold
ENV MOLD_VERSION=1.5.1
RUN set -eux; \
    curl --fail --location "https://github.com/rui314/mold/releases/download/v${MOLD_VERSION}/mold-${MOLD_VERSION}-x86_64-linux.tar.gz" --output /tmp/mold.tar.gz; \
    tar --directory "/usr/local" -xzvf "/tmp/mold.tar.gz" --strip-components 1; \
    rm /tmp/mold.tar.gz; \
    mold --version;

# Install just
ENV JUST_VERSION=1.5.0
RUN set -eux; \
    curl --fail --location "https://github.com/casey/just/releases/download/${JUST_VERSION}/just-${JUST_VERSION}-x86_64-unknown-linux-musl.tar.gz" --output /tmp/just.tar.gz; \
    tar --directory "/usr/local/bin" -xzvf "/tmp/just.tar.gz" "just"; \
    rm /tmp/just.tar.gz; \
    just --version;

# Install sccache
ENV SCCACHE_VERSION=v0.3.0
RUN set -eux; \
    curl --fail --location "https://github.com/mozilla/sccache/releases/download/${SCCACHE_VERSION}/sccache-${SCCACHE_VERSION}-x86_64-unknown-linux-musl.tar.gz" --output /tmp/sccache.tar.gz; \
    tar --directory "/usr/local/bin" -xzvf "/tmp/sccache.tar.gz" --strip-components 1 --wildcards "*/sccache"; \
    rm /tmp/sccache.tar.gz; \
    chmod +x /usr/local/bin/sccache; \
    sccache --version;

# Install cargo-nextest
RUN set -eux; \
		curl --fail --location "https://get.nexte.st/latest/linux" --output /tmp/cargo-nextest.tar.gz; \
		tar --directory "/usr/local/bin" -xzvf "/tmp/cargo-nextest.tar.gz"; \
		rm /tmp/cargo-nextest.tar.gz; \
		chmod +x /usr/local/bin/cargo-nextest; \
		cargo-nextest --version;

# Install cargo-udeps
ENV CARGO_UDEPS_VERSION=v0.1.33
RUN set -eux; \
		curl --fail --location "https://github.com/est31/cargo-udeps/releases/download/${CARGO_UDEPS_VERSION}/cargo-udeps-${CARGO_UDEPS_VERSION}-x86_64-unknown-linux-gnu.tar.gz" --output /tmp/cargo-udeps.tar.gz; \
		tar --directory "/usr/local/bin" -xzvf "/tmp/cargo-udeps.tar.gz" --strip-components 2 --wildcards "*/cargo-udeps"; \
		rm /tmp/cargo-udeps.tar.gz; \
		chmod +x /usr/local/bin/cargo-udeps;

# Install cargo-llvm-cov
ENV CARGO_LLVM_COV_VERSION=v0.5.0
RUN set -eux; \
		curl --fail --location "https://github.com/taiki-e/cargo-llvm-cov/releases/download/${CARGO_LLVM_COV_VERSION}/cargo-llvm-cov-x86_64-unknown-linux-musl.tar.gz" --output /tmp/cargo-llvm-cov.tar.gz; \
		tar --directory "/usr/local/bin" -xzvf "/tmp/cargo-llvm-cov.tar.gz"; \
		rm /tmp/cargo-llvm-cov.tar.gz; \
		chmod +x /usr/local/bin/cargo-llvm-cov;

# Install codecov uploader
RUN set -eux; \
		curl --fail --location "https://uploader.codecov.io/latest/linux/codecov" --output "/usr/local/bin/codecov"; \
		chmod +x "/usr/local/bin/codecov";

ARG USERNAME=ci
ARG USER_UID=1000
ARG USER_GID=$USER_UID

# Create the user
RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME ;

WORKDIR /ci
RUN chown -R $USER_UID:$USER_GID /ci

# [Optional] Set the default user. Omit if you want to keep the default as root.
USER $USERNAME

# Install rustup
RUN set -eux; \
		curl --location --fail \
			"https://static.rust-lang.org/rustup/dist/x86_64-unknown-linux-gnu/rustup-init" \
			--output rustup-init; \
		chmod +x rustup-init; \
		./rustup-init -y --no-modify-path --default-toolchain none; \
		rm rustup-init;

# Add rustup to path, check that it works
ENV PATH=${PATH}:/home/ci/.cargo/bin
RUN set -eux; \
		rustup --version;

# Install github actions runner
RUN set -eux; \
		curl -o actions-runner-linux-x64-2.309.0.tar.gz -L \
			https://github.com/actions/runner/releases/download/v2.309.0/actions-runner-linux-x64-2.309.0.tar.gz ; \
		tar xzf ./actions-runner-linux-x64-2.309.0.tar.gz ; \
		echo "Done"

COPY ./entrypoint-root.sh .
COPY ./entrypoint-user.sh .

USER root

CMD ["/ci/entrypoint-root.sh"]
