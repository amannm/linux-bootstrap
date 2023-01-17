#!/usr/bin/env bash

echo " dwc_otg.speed=1" >> /boot/cmdline.txt

cat > /boot/config.txt << EOF
arm_64bit=1
gpu_mem=16
camera_auto_detect=0
display_auto_detect=0
disable_splash=1
disable_poe_fan=1
enable_uart=0
enable_jtag_gpio=0
hdmi_ignore_hotplug=1
disable_overscan=1
[cm4]
otg_mode=1
[all]
[pi4]
arm_boost=1
[all]
EOF

cat > /home/pi/.asoundrc << EOF
pcm.!default {
  type hw
  card 0
}
ctl.!default {
  type hw
  card 0
}
EOF

cat > /etc/modprobe.d/alsa-base.conf << EOF
options snd_usb_audio index=0
options snd slots=snd_usb_audio
EOF