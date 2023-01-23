#!/usr/bin/env bash
set -euo

function build() {
  local images_folder="images"
  ../builder/workflow.sh build "${images_folder}"

  local vm_folder="machine"
  local output_folder="output"
  PACKER_LOG=1 packer build -parallel-builds=1 \
    -var "images_folder=${images_folder}" \
    -var "vm_name=${vm_folder}" \
    -var "vm_folder=${vm_folder}" \
    -var "output_folder=${output_folder}" .
  rm -r "${vm_folder}"

}

function build_test() {
  local images_folder="images"
  ../builder/workflow.sh build "${images_folder}"

  run_vm "${images_folder}" 1234

}

function run_vm() {
  local vm_folder="$1"
  local vm_ssh_port="$2"

  local os_disk="os_disk"
  local efi_code="efi_code"
  local efi_vars="efi_vars"

  local os_disk_path="${vm_folder}/${os_disk}"
  local efi_code_path="${vm_folder}/${efi_code}"
  local efi_vars_path="${vm_folder}/${efi_vars}"

  /opt/homebrew/bin/qemu-system-aarch64 \
    -name debian-arm64 \
    -monitor stdio \
    -display default,show-cursor=on \
    -machine type=virt,accel=hvf \
    -cpu host \
    -smp 4 \
    -m 8192 \
    -nodefaults \
    -device virtio-gpu-pci \
    -device qemu-xhci \
    -device usb-kbd \
    -device virtio-net,netdev=user \
    -netdev "user,id=user,hostfwd=tcp::${vm_ssh_port}-:22" \
    -drive file="${os_disk_path}",if=virtio,format=raw,cache=writeback,discard=ignore \
    -drive file="${efi_code_path}",if=pflash,format=raw,readonly=on \
    -drive file="${efi_vars_path}",if=pflash,format=raw
}

function local_test() {

  local os_img="os_img"
  local firmware="firmware"

#  if [ ! -f "${os_img}" ]; then
#    curl -L "https://downloads.raspberrypi.org/raspios_lite_arm64/images/raspios_lite_arm64-2022-09-26/2022-09-22-raspios-bullseye-arm64-lite.img.xz" -o "${os_img}.xz"
#    gunzip "${os_img}.xz"
#    qemu-img resize "${os_img}" 8G
#  fi

#  if [ ! -f "${firmware}" ]; then
#    curl -L "https://github.com/raspberrypi/firmware/raw/master/boot/bcm2708-rpi-b-rev1.dtb" -o "${firmware}"
#  fi

  /opt/homebrew/bin/qemu-system-aarch64 \
    -name rpi-3b-arm64 \
    -machine type=raspi3b \
    -cpu cortex-a53 \
    -smp 4 \
    -m 1024 \
    -kernel "output/kernel" \
    -dtb "output/${firmware}" \
    -sd "${os_img}" \
    -serial stdio \
    -append "loglevel=8 console=ttyAMA0,115200 dwc_otg.lpm_enable=0 root=/dev/mmcblk0p2 rootdelay=1"

}

"$@"
