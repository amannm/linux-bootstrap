#!/usr/bin/env bash

set -eoux

function extract_efi_image() {
  local source_iso="$1"
  local efi_img="$2"
  local start_block
  local block_count
  start_block=$(hdiutil imageinfo "${source_iso}" 2>&1 | grep partition-start | tail -n 1 | grep -o "[0-9]\+")
  block_count=$(hdiutil imageinfo "${source_iso}" 2>&1 | grep partition-length | tail -n 1 | grep -o "[0-9]\+")
  dd if="${source_iso}" bs=512 skip="${start_block}" count="${block_count}" of="${efi_img}"
}

function build_efi_iso() {
  local modified_source="$1"
  local efi_img="$2"
  local target_iso="$3"
  local target_iso_volume_name="$4"
  xorriso -as mkisofs \
    -r -V "${target_iso_volume_name}" \
    -o "${target_iso}" \
    -J -joliet-long -cache-inodes \
    -e boot/grub/efi.img \
    -no-emul-boot \
    -append_partition 2 0xef "${efi_img}" \
    -partition_cyl_align all \
    "${modified_source}"
}

function inject_preseed() {
  local preseed_file="$1"
  local source_files="$2"
  sudo chmod -R +w "${source_files}/install.a64/"
  sudo gunzip "${source_files}/install.a64/initrd.gz"
  local initrd_source="initrd_source"
  mkdir "${initrd_source}"
  cd "${initrd_source}"
  sudo cpio -i -F "../${source_files}/install.a64/initrd"
  sudo cp "../${preseed_file}" .
  sudo find . | sudo cpio -o -H newc -F "../${source_files}/install.a64/initrd"
  cd ..
  sudo rm -rf "${initrd_source}"
  sudo gzip "${source_files}/install.a64/initrd"
  sudo chmod -R -w "${source_files}/install.a64/"
  cd "${source_files}"
  sudo chmod +w md5sum.txt
  find . -follow -type f ! -name md5sum.txt -print0 | xargs -0 md5 -r | sudo tee md5sum.txt > /dev/null
  sudo chmod -w md5sum.txt
  cd ..
}

function extract_source_iso() {
  #sudo kmutil load -p "/System/Library/Extensions/cd9660.kext"
  #sudo kmutil load -p "/System/Library/Extensions/udf.kext"
  local source_iso="$1"
  local source_files="$2"
  local source_files_mount="${source_files}-mount"
  mkdir -p "${source_files}"
  mkdir -p "${source_files_mount}"
  local disk
  disk=$(hdiutil attach "${source_iso}" -nomount | grep -o "/dev/disk[0-9]\+" | tail -n 1)
  mount -t cd9660 "${disk}" "${source_files_mount}"
  sudo cp -R "${source_files_mount}/." "${source_files}"
  umount "${source_files_mount}"
  hdiutil detach "${disk}"
  rm -r "${source_files_mount}"
}

function build_preseed_iso() {
  local preseed_file="$1"
  local source_iso="$2"
  local preseed_iso="$3"

  local source_iso_ext="${source_iso}.iso"
  mv "${source_iso}" "${source_iso_ext}"
  local source_files="isofiles"
  extract_source_iso "${source_iso_ext}" "${source_files}"
  inject_preseed "${preseed_file}" "${source_files}"
  local efi_img="efi.img"
  extract_efi_image "${source_iso_ext}" "${efi_img}"
  original_iso_volume_name=$(hdiutil imageinfo "${source_iso_ext}" 2>&1 | grep "partition-name" | tail -n 1 | grep -o "Debian.\+" | xargs)
  build_efi_iso "${source_files}" "${efi_img}" "${preseed_iso}" "${original_iso_volume_name}"
  rm "${efi_img}"
  mv "${source_iso_ext}" "${source_iso}"
  sudo rm -rf "${source_files}"
}

"$@"
