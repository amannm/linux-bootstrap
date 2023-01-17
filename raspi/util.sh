#!/usr/bin/env bash
set -eoux

function open() {
  local codename="$1"
  local date="$2"
  local os_arch="$3"
  local target_dir="$4"
  local image="${date}-raspios-${codename}-${os_arch}-lite.img"
  local image_archive="${image}.xz"
  local image_url="http://downloads.raspberrypi.org/raspios_lite_${os_arch}/images/raspios_lite_${os_arch}-${date}/${image_archive}"
  curl -L "${image_url}" -o "os.img"
  gunzip "${image_archive}"
  mkdir -p "${target_dir}"
  mount -o loop,rw -t ext2 "${image}" "${target_dir}"
}

function close() {
  local target_dir="$1"
  umount "${target_dir}"
  rm -rf "${target_dir}"
}