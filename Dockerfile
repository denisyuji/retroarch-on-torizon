FROM ubuntu:16.04
ENV TERM linux
ENV DEBIAN_FRONTEND noninteractive

# Basic apt update
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends locales ca-certificates &&  rm -rf /var/lib/apt/lists/*
# Get basic packages
RUN apt-get update && apt-get install -y \
    build-essential cmake git crossbuild-essential-arm64
#Build libretro cores
ENV CC aarch64-linux-gnu-gcc
ENV CXX aarch64-linux-gnu-g++
ENV ARCH aarch64
RUN git clone git://github.com/libretro/libretro-super.git && \
	cd libretro-super && ./libretro-fetch.sh && ./libretro-build.sh && \
  mkdir ../libretro_dist && cp -r dist/* ../libretro_dist && \
  cd .. && rm -rf libretro-super


FROM torizon/arm64v8-debian-base
WORKDIR /home

# Make sure the user can access DRM and video devices
RUN usermod -a -G video,render,input,audio torizon
ENV DISPLAY=":0"
ENV XDG_RUNTIME_DIR="/tmp/1000-runtime-dir"

RUN apt-get -y update && apt install -y \
 libdrm-vivante1 \
 libegl-vivante1 libegl-vivante1-dev \
 libgal-vivante1 libgal-vivante1-dev \
 libgbm-vivante1 libgbm-vivante1-dev \
 libgl-vivante1 libgl-vivante1-dev \
 libgles-cl-vivante1 libgles-cm-vivante1 \
 libglesv1-cl-vivante1 libglesv1-cm-vivante1 libglesv1-cm-vivante1-dev \
 libglesv2-vivante1 libglesv2-vivante1-dev \
 libglslc-vivante1 \
 libllvm-vivante1 \
 libopenvg-vivante1 libopenvg-vivante1-dev \
 libspirv-vivante1 \
 libvsc-vivante1 \
 libvulkan-vivante1
 #libvdk-vivante1 \

RUN apt install retroarch && apt install retroarch-assets
RUN apt install libretro-mupen64plus
COPY --from=0 /libretro_dist/unix/* /usr/lib/aarch64-linux-gnu/libretro/
COPY --from=0 /libretro_dist/info/* /usr/share/libretro/info/
COPY retroarch.cfg .
COPY retroarch-core-options.cfg .

ENTRYPOINT taskset 0x60 retroarch --verbose --config=/home/retroarch.cfg --menu
