#!/usr/bin/env bash
set -euo

ISO_URL="https://cdimage.debian.org/cdimage/weekly-builds/arm64/iso-cd/debian-testing-arm64-netinst.iso"
EDK2_ARM64_CODE_PATH="/opt/homebrew/share/qemu/edk2-aarch64-code.fd"
EDK2_ARM64_VARS_PATH="/opt/homebrew/share/qemu/edk2-arm-vars.fd"

function prepare_images() {
  local os_iso_src="os_iso_src"
  local os_iso="os_iso"
  local efi_code="efi_code"
  local efi_vars="efi_vars"

  local previous_folder
  previous_folder="$(pwd)"
  cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null
  local images_folder="$1"

  local os_iso_src_path="${images_folder}/${os_iso_src}"
  local os_iso_path="${images_folder}/${os_iso}"
  local efi_code_path="${images_folder}/${efi_code}"
  local efi_vars_path="${images_folder}/${efi_vars}"

  if [ ! -d "${images_folder}" ]; then
    mkdir "${images_folder}"
  fi
  if [ ! -f "${os_iso_src_path}" ]; then
    curl -L "${ISO_URL}" -o "${os_iso_src_path}"
  fi
  if [ ! -f "${os_iso_path}" ]; then
    local preseed_file="preseed.cfg"
    "./preseed.cfg.sh" build "${preseed_file}"
    "./util.sh" build_preseed_iso "${preseed_file}" "${os_iso_src_path}" "${os_iso_path}"
    rm "${preseed_file}"
  fi
  if [ ! -f "${efi_code_path}" ]; then
    cp "${EDK2_ARM64_CODE_PATH}" "${efi_code_path}"
  fi
  if [ ! -f "${efi_vars_path}" ]; then
    cp "${EDK2_ARM64_VARS_PATH}" "${efi_vars_path}"
  fi
}

function generate_vm {
  local images_folder="$1"
  local vm_folder="$2"
  local vm_name="$3"
  if [ ! -d "${vm_folder}" ]; then
    PACKER_LOG=1 packer build -parallel-builds=1 \
      -var "images_folder=${images_folder}" \
      -var "vm_folder=${vm_folder}" \
      -var "vm_name=${vm_name}" .
  fi
}

function build() {
  local previous_folder
  previous_folder="$(pwd)"
  local target_folder
  target_folder="$(cd "$(dirname "$1")" && pwd)/$(basename "$1")"

  cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null

  local os_iso="os_iso"
  local os_disk="os_disk"
  local efi_code="efi_code"
  local efi_vars="efi_vars"

  local images_folder="images"
  local vm_folder="machine"

  prepare_images "${images_folder}"

  if [ ! -f "${vm_folder}/${os_disk}" ]; then
    build_vm "${images_folder}" "${vm_folder}" "${os_disk}"
  fi

  mkdir -p "${target_folder}"
  cp "${vm_folder}/${os_disk}" "${target_folder}/${os_disk}"
  cp "${images_folder}/${efi_code}" "${target_folder}/${efi_code}"
  cp "${vm_folder}/${efi_vars}" "${target_folder}/${efi_vars}"

  cd "${previous_folder}"
}

function build_vm() {
  local images_folder="$1"
  local vm_folder="$2"

  local os_iso="os_iso"
  local efi_code="efi_code"
  local efi_vars="efi_vars"
  local os_disk="$3"

  local images_folder="$1"
  local vm_folder="$2"
  local vm_name="$3"

  mkdir -p "${vm_folder}"

  local os_iso_path="${images_folder}/${os_iso}"
  local os_disk_path="${vm_folder}/${os_disk}"
  local efi_code_path="${images_folder}/${efi_code}"
  local efi_vars_path="${vm_folder}/${efi_vars}"

  if [ ! -f "${efi_vars_path}" ]; then
    cp "${images_folder}/${efi_vars}" "${efi_vars_path}"
  fi
  if [ ! -f "${os_disk_path}" ]; then
    qemu-img create -f raw "${os_disk_path}" 16G
  fi

  local local_ssh_port=1337

  # create a named pipe for feeding sendkey commands to QEMU Monitor
  local fifo_path
  fifo_path="/tmp/qemu-in-$(uuidgen)"
  mkfifo "${fifo_path}"
  trap "rm -rf ${fifo_path}" EXIT ERR INT TERM
  # hold the input channel to QEMU Monitor open for at most this long
  sleep "60" >"${fifo_path}" &

  # start QEMU and feed in a named pipe to QEMU Monitor
  /opt/homebrew/bin/qemu-system-aarch64 \
    -name debian-arm64 \
    -monitor stdio \
    -display default,show-cursor=on \
    -machine type=virt,accel=hvf \
    -cpu host \
    -smp 4 \
    -m 8G \
    -nodefaults \
    -device virtio-gpu-pci \
    -device qemu-xhci \
    -device usb-kbd \
    -device virtio-net,netdev=user \
    -netdev "user,id=user,hostfwd=tcp::${local_ssh_port}-:22" \
    -drive file="${os_iso_path}",if=virtio,media=cdrom \
    -drive file="${os_disk_path}",if=virtio,format=raw,cache=writeback,discard=ignore \
    -drive file="${efi_code_path}",if=pflash,format=raw,readonly=on \
    -drive file="${efi_vars_path}",if=pflash,format=raw <"${fifo_path}" &
  local pid="$!"

  # starts the debian installation
  sleep "5"
  echo "sendkey kp_enter" >"${fifo_path}"

  # switches to the installation log terminal for debugging purposes
  sleep "5"
  echo "sendkey alt-right" >"${fifo_path}"
  echo "sendkey alt-right" >"${fifo_path}"
  echo "sendkey alt-right" >"${fifo_path}"

  # waits for the installation to complete and power down the machine
  wait "${pid}"
}

function run_vm() {
  local vm_folder="$1"

  local efi_code="efi_code"
  local efi_vars="efi_vars"
  local os_disk="os_disk"

  local os_disk_path="${vm_folder}/${os_disk}"
  local efi_code_path="${vm_folder}/${efi_code}"
  local efi_vars_path="${vm_folder}/${efi_vars}"

  local local_ssh_port=1337
  /opt/homebrew/bin/qemu-system-aarch64 \
    -name debian-arm64 \
    -monitor stdio \
    -display default,show-cursor=on \
    -machine type=virt,accel=hvf \
    -cpu host \
    -smp 4 \
    -m 8G \
    -nodefaults \
    -device virtio-gpu-pci \
    -device qemu-xhci \
    -device usb-kbd \
    -device virtio-net,netdev=user \
    -netdev "user,id=user,hostfwd=tcp::${local_ssh_port}-:22" \
    -drive file="${os_disk_path}",if=virtio,format=raw,cache=writeback,discard=ignore \
    -drive file="${efi_code_path}",if=pflash,format=raw,readonly=on \
    -drive file="${efi_vars_path}",if=pflash,format=raw
}

"$@"
