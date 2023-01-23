#!/usr/bin/env bash
set -euo

function build() {
  local source_vm_folder="source"
  local vm_folder="machine"
  local output_folder="output"
  ../builder/workflow.sh build "${source_vm_folder}"
  packer build -parallel-builds=1 \
    -var "images_folder=${source_vm_folder}" \
    -var "vm_name=${vm_folder}" \
    -var "vm_folder=${vm_folder}" \
    -var "output_folder=${output_folder}" .
  rm -r "${vm_folder}"
}

"$@"