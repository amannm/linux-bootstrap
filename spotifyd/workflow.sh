#!/usr/bin/env bash
set -euo

function build() {
  local images_folder="images"
  local vm_folder="machine"
  local output_folder="output"
  ../builder/workflow.sh build "${images_folder}"
  packer build -parallel-builds=1 \
    -var "images_folder=${images_folder}" \
    -var "vm_name=${vm_folder}" \
    -var "vm_folder=${vm_folder}" \
    -var "output_folder=${output_folder}" .
  rm -r "${vm_folder}"
}

"$@"