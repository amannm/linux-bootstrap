locals {
  repo_path = "/home/debian/build/spotifyd"
}

variable "output_folder" {
  type = string
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