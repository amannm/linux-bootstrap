#!/usr/bin/env bash
set -eou

function build() {
  local target_file="$1"
  local name="${2:-"machine"}"
  local username="${2:-"debian"}"
  cat > "${target_file}" << EOF
d-i preseed/early_command string umount /media || true

d-i debian-installer/locale string en_US
d-i keyboard-configuration/xkb-keymap select us

d-i netcfg/choose_interface select auto
d-i netcfg/get_hostname string ${name}
d-i netcfg/get_domain string local
d-i netcfg/wireless_wep string

d-i mirror/country string manual
d-i mirror/http/hostname string http.us.debian.org
d-i mirror/http/directory string /debian
d-i mirror/http/proxy string

d-i passwd/root-password password root
d-i passwd/root-password-again password root
d-i passwd/user-fullname string ${username}
d-i passwd/username string ${username}
d-i passwd/user-password password debian
d-i passwd/user-password-again password debian

d-i clock-setup/utc boolean true
d-i time/zone string US/Central
d-i clock-setup/ntp boolean true

d-i partman-auto/method string lvm
d-i partman-auto-lvm/guided_size string max
d-i partman-lvm/device_remove_lvm boolean true
d-i partman-md/device_remove_md boolean true
d-i partman-lvm/confirm boolean true
d-i partman-lvm/confirm_nooverwrite boolean true
d-i partman-auto/choose_recipe select atomic
d-i partman-partitioning/confirm_write_new_label boolean true
d-i partman/choose_partition select finish
d-i partman/confirm boolean true
d-i partman/confirm_nooverwrite boolean true

d-i base-installer/install-recommends boolean false
d-i apt-setup/cdrom/set-first boolean false
d-i apt-setup/disable-cdrom-entries boolean true

tasksel tasksel/first multiselect
d-i pkgsel/include string openssh-server sudo
d-i pkgsel/upgrade select full-upgrade
d-i pkgsel/install-language-support boolean false

popularity-contest popularity-contest/participate boolean false

d-i grub-installer/only_debian boolean true
d-i grub-installer/with_other_os boolean true
d-i grub-installer/bootdev string ${name}-vg

d-i finish-install/reboot_in_progress note

d-i debian-installer/exit/poweroff boolean true

d-i preseed/late_command string echo '${username} ALL=(ALL) NOPASSWD: ALL' > /target/etc/sudoers.d/${username}
EOF
}

"$@"