FROM ubuntu:22.04

ENV BUILD_DIR=/home/builder/uboot-kernel

ENV UBOOT_BRANCH=toradex_imx_v2020.04_5.4.70_2.3.0
ENV UBOOT_CONFIG=verdin-imx8mm_defconfig 
ENV KERNEL_BRANCH=toradex_5.4-2.3.x-imx
ENV KERNEL_CONFIG=toradex_defconfig
ENV DEVTREE_BRANCH=toradex_5.4-2.3.x-imx

#Install dependencies for build environment setup
RUN apt-get update && apt-get install wget xz-utils -y

#Instal build dependencies
RUN apt-get install bc build-essential git libncurses5-dev lzop perl libssl-dev bison flex u-boot-tools -y && \
    apt-get clean && apt-get autoremove && rm -rf /var/lib/apt/lists/*

RUN useradd builder

RUN mkdir -p ${BUILD_DIR}

WORKDIR ${BUILD_DIR}

RUN wget -O gcc-arm-9.2-2019.12-x86_64-aarch64-none-linux-gnu.tar.xz \
    "https://developer.arm.com/-/media/Files/downloads/gnu-a/9.2-2019.12/binrel/gcc-arm-9.2-2019.12-x86_64-aarch64-none-linux-gnu.tar.xz?revision=61c3be5d-5175-4db6-9030-b565aae9f766&la=en&hash=0A37024B42028A9616F56A51C2D20755C5EBBCD7"
RUN tar -xf gcc-arm-9.2-2019.12-x86_64-aarch64-none-linux-gnu.tar.xz
RUN ln -s gcc-arm-9.2-2019.12-x86_64-aarch64-none-linux-gnu gcc-linaro

RUN echo "export ARCH=arm64" >> ./export_compiler && \
    echo "export DTC_FLAGS='-@'" >> ./export_compiler && \
    echo "export PATH=~/gcc-linaro/bin/:$PATH" >> ./export_compiler && \
    echo "export CROSS_COMPILE=aarch64-none-linux-gnu-" >> ./export_compiler && \
    /bin/bash -c 'source ./export_compiler'

#Clone uboot and prepare it
RUN git clone -b ${UBOOT_BRANCH} https://git.toradex.com/u-boot-toradex.git
RUN cd ./u-boot-toradex && make ${UBOOT_CONFIG}

#Clone the kernel and configure it
doRUN git clone -b ${KERNEL_BRANCH} https://git.toradex.com/linux-toradex.git
RUN cd ./linux-toradex && make ${KERNEL_CONFIG}
#Copy custom kernel config from host
#COPY ./config/kernel/.config ./.config

WORKDIR ${BUILD_DIR}

#Clone the DTO and prepare it
RUN git clone -b ${DEVTREE_BRANCH} https://git.toradex.com/device-tree-overlays.git

RUN chown -R builder ${BUILD_DIR}   

USER builder

#Keep the container runnning even if run non-interactively
CMD ["sleep", "infinity"]