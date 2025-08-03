# Use Ubuntu 22.04 as the base image
FROM ubuntu:22.04
ENV DEBIAN_FRONTEND=noninteractive

# 1. Install OpenWRT toolchain and build dependencies
RUN apt update && apt install -y \
    build-essential clang flex g++ gawk gcc-multilib gettext \
    git libncurses5-dev libssl-dev python3 python3-distutils \
    rsync unzip zlib1g-dev file wget ccache xsltproc swig \
    libelf-dev ca-certificates curl vim && apt clean

# 2. Create a non-root user for building
RUN useradd -ms /bin/bash builder && echo "builder ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
USER builder
WORKDIR /home/builder

# 3. Clone the OpenWRT source code (v23.05.3, shallow clone)
RUN git clone --depth=1 --branch v23.05.3 https://github.com/openwrt/openwrt.git

# 4. Copy your custom package "check_python" into OpenWRT's package directory
COPY --chown=builder:builder check_python/ ./openwrt/package/check_python/
WORKDIR /home/builder/openwrt

# 5. Remove feeds that often cause build errors (optional optimization)
RUN sed -i '/telephony/d' feeds.conf.default && \
    sed -i '/routing/d' feeds.conf.default && \
    sed -i '/video/d' feeds.conf.default && \
    sed -i '/luci/d' feeds.conf.default

# 6. Update and install all feeds (needed for dependencies)
RUN git config --global http.postBuffer 524288000 && \
    ./scripts/feeds update -a && ./scripts/feeds install -a

# 7. Configure target for Raspberry Pi 4 and include required packages as built-in
RUN echo "\
CONFIG_TARGET_bcm27xx=y\n\
CONFIG_TARGET_bcm27xx_bcm2711=y\n\
CONFIG_TARGET_bcm27xx_bcm2711_DEVICE_rpi-4=y\n\
CONFIG_PACKAGE_check_python=y\n\
CONFIG_PACKAGE_python3-light=y\n\
CONFIG_PACKAGE_python3-base=y\n\
CONFIG_PACKAGE_libpython3-3.11=y\n\
CONFIG_PACKAGE_libbz2=y\n\
CONFIG_PACKAGE_zlib=y\n\
" > .config && make defconfig

# 8. Build the full firmware image with integrated Python3 and check_python
RUN make -j$(nproc) V=s

# 9. Copy the generated firmware image out to /output directory (mounted by host)
RUN mkdir -p /output && \
    cp bin/targets/bcm27xx/bcm2711/*/openwrt-*-rpi-4-ext4-factory.img.gz /output/
