variable "os_iso" {
  type = string
}

variable "efi_code" {
  type = string
}

variable "efi_vars" {
  type = string
}

source "qemu" "debian_arm64" {
  iso_url      = var.os_iso
  iso_checksum = "none"
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

  boot_wait    = "5s"
  boot_command = ["<enter>"]
  shutdown_command = "echo 'debian' | sudo -S shutdown -P now"
  format           = "raw"

  efi_firmware_code = var.efi_code
  efi_firmware_vars = var.efi_vars

}