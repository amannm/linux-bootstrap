locals {
  build_folder = "/home/debian/build"
  image_folder = "${local.build_folder}/raspi"
}

variable "output_folder" {
  type = string
}

build {

  provisioner "file" {
    source = "util.sh"
    destination = "${build_folder}/"
  }
  provisioner "shell" {
    inline = "cd ${build_folder} && ./util.sh open bullseye 2022-09-22 arm64 ${image_folder}"
  }


  # ALSA audio configuration
  provisioner "file" {
    source = "config.txt"
    destination = "${image_folder}/boot/"
  }
  provisioner "file" {
    source = ".asoundrc"
    destination = "${image_folder}/home/pi/"
  }
  provisioner "file" {
    source = "alsa-base.conf"
    destination = "${image_folder}/etc/modprobe.d/"
  }

  # fix some (my) audio appliances not supporting USB 2.0 mode on the RPI
  provisioner "shell" {
    inline = "echo ' dwc_otg.speed=1' >> \"$1/boot/cmdline.txt\""
  }

  # install spotifyd and enable it on startup
  provisioner "file" {
    source = "../spotifyd/output/spotifyd"
    destination = "${image_folder}/usr/bin/"
  }
  provisioner "file" {
    source = "../spotifyd/output/spotifyd.service"
    destination = "${image_folder}/etc/systemd/system/"
  }
  provisioner "file" {
    source = "spotifyd.conf"
    destination = "${image_folder}/etc/"
  }
  provisioner "shell" {
    inline = "ln -s ${image_folder}/usr/lib/systemd/system/spotifyd.service ${image_folder}/etc/systemd/system/multi-user.target.wants/spotifyd.service"
  }

  provisioner "shell" {
    inline = "${build_folder}/util.sh close ${image_folder}"
  }

  provisioner "file" {
    source      = "${local.build_folder}/os.img"
    destination = "${var.output_folder}/os.img"
    direction   = "download"
  }
}