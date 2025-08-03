# OpenWRT Python Image Builder (for Raspberry Pi 4)

This project builds a fully customized OpenWRT firmware image for the Raspberry Pi 4, with Python 3.11 and a custom package (`check_python`) **embedded into the final image** — no need to install anything via SSH.

---

## Features

- Based on OpenWRT `v23.05.3`
- Target: `bcm27xx/bcm2711` (Raspberry Pi 4)
- Python 3.11 built-in:
  - `python3-base`, `python3-light`
  - `libpython3`, `libbz2`, `zlib`
- Custom package: `check_python`
- Dockerized build process
- Outputs firmware image (`.img.gz`) ready to flash

---

## How to Use

### 1. Clone this repo

```bash
git clone https://github.com/hoanganh310tp3/OpenWRT_Python_VerCheck
cd openwrt-python-check

### 2. Build the Docker image

```bash
docker build -t openwrt-python-build .

### 3. Build OpenWRT image

```bash
docker run --rm -v "$(pwd)/output:/output" openwrt-python-build

After completion, the output firmware will be in:

output/openwrt-bcm27xx-bcm2711-rpi-4-ext4-factory.img.gz

### 4. Flash to SD card

Extract and flash using Raspberry Pi Imager or dd:

```bash
gunzip output/*.img.gz
sudo dd if=output/*.img of=/dev/sdX bs=4M status=progress conv=fsync

Replace /dev/sdX with your actual SD card device.

### Verify on Raspberry Pi 4

After booting the device:

```bash
ssh root@192.168.1.1

python3 --version

check_python

### Directory Structure

openwrt-python-check/
├── Dockerfile
├── check_python/         
└── output/               


### Credits

    OpenWRT

    Python Dev Team

