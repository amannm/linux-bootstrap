#!/usr/bin/env bash
set -eoux

#sudo apt install -y libasound2 libssl

BUILD_DIR="/tmp/build/spotifyd"

cp "${BUILD_DIR}/spotifyd" /usr/bin/

cp "${BUILD_DIR}/spotifyd.service" /etc/systemd/system/
systemctl daemon-reload
systemctl enable spotifyd.service --now

cp "${BUILD_DIR}/spotifyd.conf" /etc
systemctl start spotifyd.service