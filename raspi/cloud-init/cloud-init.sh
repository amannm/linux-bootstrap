#!/usr/bin/env bash
set -eoux

apt-get install cloud-init -y

touch /boot/meta-data
touch /boot/user-data

cat > /etc/cloud/cloud.cfg.d/99_raspi.cfg <<EOF
datasource_list:
  - NoCloud
datasource:
  NoCloud:
    seedfrom: /boot/
users:
  - default
system_info:
  distro: debian
  default_user:
    name: pi
    lock_passwd: false
    groups:
      - pi
      - adm
      - dialout
      - cdrom
      - sudo
      - audio
      - video
      - render
      - plugdev
      - games
      - users
      - input
      - netdev
      - spi
      - i2c
      - gpio
    sudo:
      - "ALL=(ALL) NOPASSWD: ALL"
    shell: /bin/bash
  paths:
    cloud_dir: /var/lib/cloud/
    templates_dir: /etc/cloud/templates/
  package_mirrors:
    - arches:
        - default
      failsafe:
        primary: http://raspbian.raspberrypi.org/raspbian
        security: http://raspbian.raspberrypi.org/raspbian
  ssh_svcname: ssh
EOF