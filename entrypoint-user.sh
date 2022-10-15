#!/bin/bash -eux

export CARGO_HOME=/vol/cargo
mkdir $CARGO_HOME

source ~/.cargo/env

export SCCACHE_DIR=/vol/sccache
export SCCACHE_CACHE_SIZE=10G
export SCCACHE_ERROR_LOG=/tmp/sccache_log.txt
# export SCCACHE_LOG=debug
sccache --start-server
export RUSTC_WRAPPER=sccache

./config.sh \
	--url https://github.com/hapsoc \
	--name flym \
	--replace \
	--work ../vol/work \
	--token "${GITHUB_ACTIONS_TOKEN}"
./run.sh