#!/usr/bin/env bash
set -eoux

function open() {
  local target_dir="$1"
  local target_dir_boot="${target_dir}-boot"
  local image_url="https://downloads.raspberrypi.org/raspios_lite_arm64/images/raspios_lite_arm64-2022-09-26/2022-09-22-raspios-bullseye-arm64-lite.img.xz"
  local image_name="os.img"

  sudo apt install -y curl ca-certificates xz-utils tree

  if [ ! -f "${image_name}" ]; then
    curl -L "${image_url}" -o "${image_name}.xz"
    xz -d "${image_name}.xz"
  fi
  mkdir "${target_dir}"
  mkdir "${target_dir_boot}"

  local sector_size=512

  local boot_offset
  boot_offset="$(sudo fdisk -l "${image_name}" -o "Start" | tail -2 | head -1 | xargs)"
  boot_offset_bytes=$(( boot_offset * sector_size ))

  local boot_size
  boot_size="$(sudo fdisk -l "${image_name}" -o "Sectors" | tail -2 | head -1 | xargs)"
  boot_size_bytes=$(( boot_size * sector_size ))

  sudo mount -o loop,ro,offset="${boot_offset_bytes}",sizelimit="${boot_size_bytes}" "${image_name}" "${target_dir_boot}"

  local offset
  offset="$(sudo fdisk -l "${image_name}" -o "Start" | tail -1 | xargs)"
  offset_bytes=$(( offset * sector_size ))

  local offset_size
  offset_size="$(sudo fdisk -l "${image_name}" -o "Sectors" | tail -1 | xargs)"
  offset_size_bytes=$(( offset_size * sector_size ))

  sudo mount -o loop,rw,offset="${offset_bytes}",sizelimit="${offset_size_bytes}" "${image_name}" "${target_dir}"

  tree -dfi --noreport "${target_dir}" | xargs -I{} mkdir -p "./temp/{}"
  cp -a "./temp/home/debian/image" "./build"
  chown -R debian "./build"
}

function close() {
  local target_dir="$1"
  local target_dir_boot="${target_dir}-boot"
  cp -a "./build" "${target_dir}"
  sudo umount "${target_dir}"
  sudo umount "${target_dir_boot}"
  rm -rf "${target_dir}"
  rm -rf "${target_dir_boot}"
}

function download() {
  local package_names
  package_names="$(apt-cache depends --recurse --no-recommends --no-suggests --no-conflicts --no-breaks --no-replaces --no-enhances cloud-init | grep "^\w" | sort -u)"
  apt-get download "${package_names}"
}

"$@"