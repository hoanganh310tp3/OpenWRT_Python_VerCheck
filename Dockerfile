FROM ubuntu:22.04
ENV DEBIAN_FRONTEND=noninteractive

# 1. Cài toolchain và công cụ build
RUN apt update && apt install -y \
    build-essential clang flex g++ gawk gcc-multilib gettext \
    git libncurses5-dev libssl-dev python3 python3-distutils \
    rsync unzip zlib1g-dev file wget ccache xsltproc swig \
    libelf-dev ca-certificates curl vim && apt clean

# 2. Tạo user không cần root
RUN useradd -ms /bin/bash builder && echo "builder ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
USER builder
WORKDIR /home/builder

# 3. Clone repo OpenWRT
RUN git clone --depth=1 --branch v23.05.3 https://github.com/openwrt/openwrt.git

# 4. Copy gói check_python tự viết
COPY --chown=builder:builder check_python/ ./openwrt/package/check_python/
WORKDIR /home/builder/openwrt

# 5. Bỏ các feed dễ lỗi
RUN sed -i '/telephony/d' feeds.conf.default && \
    sed -i '/routing/d' feeds.conf.default && \
    sed -i '/video/d' feeds.conf.default && \
    sed -i '/luci/d' feeds.conf.default

# 6. Cập nhật & cài feed với buffer lớn
RUN git config --global http.postBuffer 524288000 && \
    ./scripts/feeds update -a && ./scripts/feeds install -a

# 7. Cấu hình RPi4 + tích hợp package
# 7. Cấu hình tự động cho RPi4 và bật gói check_python + python3 nhẹ
RUN echo "CONFIG_TARGET_bcm27xx=y" >> .config && \
    echo "CONFIG_TARGET_bcm27xx_bcm2711=y" >> .config && \
    echo "CONFIG_TARGET_bcm27xx_bcm2711_DEVICE_rpi-4=y" >> .config && \
    echo "CONFIG_PACKAGE_check_python=y" >> .config && \
    echo "CONFIG_PACKAGE_python3-light=y" >> .config && \
    echo "CONFIG_PACKAGE_libpython3=y" >> .config && \
    echo "CONFIG_PACKAGE_python3-base=y" >> .config && \
    make defconfig

# 8. Build full image + ipk
RUN make -j1 V=s
