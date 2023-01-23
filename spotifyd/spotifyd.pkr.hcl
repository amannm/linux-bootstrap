locals {
  repo_path = "/home/debian/build/spotifyd"
}
variable "vm_folder" {
  type = string
}
variable "vm_name" {
  type = string
}
variable "images_folder" {
  type = string
}
variable "output_folder" {
  type = string
}
source "qemu" "debian_arm64" {
  vm_name             = var.vm_name
  output_directory    = var.vm_folder
  iso_url             = "${var.images_folder}/os_disk"
  disk_image = true
  iso_checksum        = "none"
  qemu_binary         = "qemu-system-aarch64"
  accelerator         = "hvf"
  use_default_display = true
  machine_type        = "virt"
  qemuargs            = [
    ["-cpu", "host"],
    ["-boot", "menu=off"],
    ["-device", "qemu-xhci"],
    ["-device", "usb-kbd"],
    ["-device", "virtio-gpu-pci"],
    ["-device", "virtio-net,netdev=user.0"],
  ]
  headless = true

  cpus           = 4
  memory         = 8192
  disk_size      = "16G"
  disk_interface = "virtio"
  net_device     = "virtio-net"

  ssh_username     = "debian"
  ssh_password     = "debian"
  ssh_wait_timeout = "300s"

  shutdown_command = "echo 'debian' | sudo shutdown now"
  format           = "raw"

  efi_firmware_code = "${var.images_folder}/efi_code"
  efi_firmware_vars = "${var.images_folder}/efi_vars"
}
build {
  sources = ["source.qemu.debian_arm64"]
  provisioner "shell" {
    script = "spotifyd.sh"
  }
  provisioner "file" {
    source      = "${local.repo_path}/target/release/spotifyd"
    destination = "${var.output_folder}/spotifyd"
    direction   = "download"
  }
  provisioner "file" {
    source      = "${local.repo_path}/contrib/spotifyd.service"
    destination = "${var.output_folder}/spotifyd.service"
    direction   = "download"
  }
}