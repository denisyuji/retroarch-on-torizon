#Image to build the libretro cores

FROM ubuntu:16.04
ENV TERM linux
ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update &&  \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    locales \
    ca-certificates \
    build-essential \
    cmake \
    git \
    crossbuild-essential-arm64 \
    && apt-get clean && apt-get autoremove && rm -rf /var/lib/apt/lists/*

ENV CC aarch64-linux-gnu-gcc
ENV CXX aarch64-linux-gnu-g++
ENV ARCH aarch64

RUN git clone git://github.com/libretro/libretro-super.git && \
	cd libretro-super && ./libretro-fetch.sh && ./libretro-build.sh && \
  mkdir ../libretro_dist && cp -r dist/* ../libretro_dist && \
  cd .. && rm -rf libretro-super

# Image to execute on embedded device

FROM torizon/arm64v8-debian-base
WORKDIR /home

RUN apt-get -y update && apt-get install -y --no-install-recommends \
  libdrm-vivante1 \
  libegl-vivante1 \
  libgal-vivante1 \
  libgbm-vivante1 \
  libgl-vivante1 \
  libgles-cm-vivante1 \
  libglesv1-cm-vivante1 \
  libglesv2-vivante1 \
  libglslc-vivante1 \
  retroarch \
  retroarch-assets \
  libasound2-plugins \
  alsa-utils \
  && apt-get clean && apt-get autoremove && rm -rf /var/lib/apt/lists/*

RUN usermod -a -G video,render,input,audio torizon

COPY --from=0 /libretro_dist/unix/* /usr/lib/aarch64-linux-gnu/libretro/
COPY --from=0 /libretro_dist/info/* /usr/share/libretro/info/
COPY retroarch.cfg .
COPY retroarch-core-options.cfg .

ENTRYPOINT taskset 0x60 retroarch --verbose --config=/home/retroarch.cfg --menu
