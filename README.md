# rpi-spotifyd-usb-dongle
Automation to generate an image that turns a Raspberry Pi into a USB audio out dongle, acting as a Spotify output device in your local network
* Based on the arm64 build of Raspberry Pi OS
* Packer is used to construct a QEMU VM with an arm64 Debian environment that
* Generates an arm64 (aka aarch64) compatible `spotifyd` binary
* Entire build pipeline is capable of running locally on MacOS using M1/M2 processors

#### TODO
The remainder of the pipeline that
* Installs and configures `spotifyd`
* Configures ALSA
* Configures WLAN
* Customizes the RPI OS image