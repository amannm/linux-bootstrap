locals {
  home = "/home/debian/"
  image_root = "/home/debian/image"
  build_root = "/home/debian/build"
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
  iso_url             = "images/os_disk"
  disk_image          = true
  iso_checksum        = "none"
  qemu_binary         = "qemu-system-aarch64"
  accelerator         = "hvf"
  use_default_display = true
  headless            = true
  machine_type        = "virt"
  qemuargs            = [
    ["-cpu", "host"],
    ["-boot", "menu=off"],
    ["-device", "qemu-xhci"],
    ["-device", "usb-kbd"],
    ["-device", "virtio-gpu-pci"],
    ["-device", "virtio-net,netdev=user.0"],
  ]
  cpus              = 4
  memory            = 8192
  disk_size         = "16G"
  format            = "raw"
  disk_interface    = "virtio"
  net_device        = "virtio-net"
  ssh_username      = "debian"
  ssh_password      = "debian"
  ssh_wait_timeout  = "60s"
  shutdown_command = "echo 'debian' | sudo shutdown now"
  efi_firmware_code = "${var.images_folder}/efi_code"
  efi_firmware_vars = "${var.images_folder}/efi_vars"
  boot_wait         = "15s"
}

build {
  sources = ["source.qemu.debian_arm64"]
  provisioner "file" {
    source      = "util.sh"
    destination = "/home/debian/"
  }
  provisioner "shell" {
    inline = [
      "chmod +x ${local.home}/util.sh",
      "sudo ${local.home}/util.sh open ${local.image_root}",
    ]
  }

  # fix some (my) audio appliances not supporting USB 2.0 mode on the RPI
  provisioner "file" {
    source      = "./boot/cmdline.txt"
    destination = "${local.build_root}/boot/"
  }

  # ALSA audio configuration
  provisioner "file" {
    source      = "./boot/config.txt"
    destination = "${local.build_root}/boot/"
  }
  provisioner "file" {
    source      = "./alsa/.asoundrc"
    destination = "${local.build_root}/home/pi/"
  }
  provisioner "file" {
    source      = "./alsa/alsa-base.conf"
    destination = "${local.build_root}/etc/modprobe.d/"
  }

  # install spotifyd and enable it on startup
  provisioner "file" {
    source      = "../spotifyd/output/spotifyd"
    destination = "${local.build_root}/usr/bin/"
  }
  provisioner "file" {
    source      = "../spotifyd/output/spotifyd.service"
    destination = "${local.build_root}/etc/systemd/system/"
  }
  provisioner "file" {
    source      = "./spotifyd/spotifyd.conf"
    destination = "${local.build_root}/etc/"
  }
  provisioner "shell" {
    inline = ["ln -sf /usr/lib/systemd/system/spotifyd.service ${local.build_root}/etc/systemd/system/multi-user.target.wants/spotifyd.service"]
  }

  provisioner "file" {
    source      = "${local.image_root}-boot/bcm2710-rpi-3-b-plus.dtb"
    destination = "${var.output_folder}/firmware"
    direction   = "download"
  }

  provisioner "file" {
    source      = "${local.image_root}-boot/kernel8.img"
    destination = "${var.output_folder}/kernel"
    direction   = "download"
  }

  provisioner "shell" {
    inline = ["sudo ${local.home}/util.sh close ${local.image_root}"]
  }

  provisioner "file" {
    source      = "os.img"
    destination = "${var.output_folder}/os_img"
    direction   = "download"
  }
}