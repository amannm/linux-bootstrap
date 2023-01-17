#!/usr/bin/env bash
set +eoux

sudo apt install -y libasound2-dev libssl-dev pkg-config ca-certificates git curl gcc libc6-dev
curl https://sh.rustup.rs -sSf | sh -s -- -y
source "${HOME}/.cargo/env"

BUILD_DIR="${HOME}/build"
mkdir "${BUILD_DIR}"
cd "${BUILD_DIR}" || exit 1
git clone "https://github.com/Spotifyd/spotifyd.git"
cd spotifyd || exit 1
cargo build --release