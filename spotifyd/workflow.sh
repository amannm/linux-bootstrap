#!/usr/bin/env bash
set -eoux

OS_IMAGE="debian-testing-arm64-netinst.iso"
OS_IMAGE_URL="https://cdimage.debian.org/cdimage/weekly-builds/arm64/iso-cd/${OS_IMAGE}"
QEMU_SHARE_PATH="/opt/homebrew/share/qemu/"

EDK2_ARM64_CODE="edk2-aarch64-code.fd"
EDK2_ARM64_VARS="edk2-arm-vars.fd"
PRESEED_CONFIG="preseed.cfg"

function build() {

  local images_folder="images"
  local os_iso="os_iso"
  local efi_code="efi_code"
  local efi_vars="efi_vars"
  local os_iso_path="${images_folder}/${os_iso}"
  local efi_code_path="${images_folder}/${efi_code}"
  local efi_vars_path="${images_folder}/${efi_vars}"

  local output_folder="output"

  if [ ! -d "${images_folder}" ]; then
    mkdir "${images_folder}"
    curl -L "${OS_IMAGE_URL}" -o "${OS_IMAGE}"
    ./util.sh build_preseed_iso "${PRESEED_CONFIG}" "${OS_IMAGE}" "${os_iso_path}"
    rm "${OS_IMAGE}"
    cp "${QEMU_SHARE_PATH}/${EDK2_ARM64_CODE}" "${efi_code_path}"
    cp "${QEMU_SHARE_PATH}/${EDK2_ARM64_VARS}" "${efi_vars_path}"
  fi

  packer build -parallel-builds=1 \
    -var "${os_iso}=${os_iso_path}" \
    -var "${efi_code}=${efi_code_path}" \
    -var "${efi_vars}=${efi_vars_path}" \
    -var "output_folder=${output_folder}" .
}

"$@"
