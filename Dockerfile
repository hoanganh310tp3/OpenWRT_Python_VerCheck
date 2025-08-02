FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# 1. Cài gói build hệ thống
RUN apt update && apt install -y \
    build-essential clang flex g++ gawk gcc-multilib gettext \
    git libncurses5-dev libssl-dev python3 python3-distutils \
    rsync unzip zlib1g-dev file wget ccache xsltproc swig \
    libelf-dev ca-certificates curl vim && apt clean

# 2. Tạo user non-root
RUN useradd -ms /bin/bash builder && echo "builder ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
USER builder
WORKDIR /home/builder

# 3. Clone OpenWRT
RUN git clone --depth=1 --branch v23.05.3 https://github.com/openwrt/openwrt.git

# 4. Copy custom package check_python
COPY --chown=builder:builder check_python/ ./openwrt/package/check_python/

WORKDIR /home/builder/openwrt

# 5. Bỏ các feed có thể lỗi (luci, telephony, routing, video)
RUN sed -i '/telephony/d' feeds.conf.default && \
    sed -i '/routing/d' feeds.conf.default && \
    sed -i '/video/d' feeds.conf.default && \
    sed -i '/luci/d' feeds.conf.default

# 6. Cập nhật & cài feed
RUN ./scripts/feeds update -a && ./scripts/feeds install -a

# 7. Cấu hình tự động cho RPi4 và bật gói
RUN echo "CONFIG_TARGET_bcm27xx=y" >> .config && \
    echo "CONFIG_TARGET_bcm27xx_bcm2711=y" >> .config && \
    echo "CONFIG_TARGET_bcm27xx_bcm2711_DEVICE_rpi-4=y" >> .config && \
    echo "CONFIG_PACKAGE_check_python=y" >> .config && \
    make defconfig

# 8. Build image + gói .ipk (mất thời gian)
RUN make -j1 V=s
