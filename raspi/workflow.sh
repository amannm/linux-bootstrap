#!/usr/bin/env bash
set -eoux

function initialize() {
  curl -LO http://downloads.raspberrypi.org/raspios_lite_arm64/images/raspios_lite_arm64-2022-09-26/2022-09-22-raspios-bullseye-arm64-lite.img.xz
  mv "2022-09-22-raspios-bullseye-arm64-lite.img.xz" img/
  gunzip img/2022-09-22-raspios-bullseye-arm64-lite.img.xz
}

