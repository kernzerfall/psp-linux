# AVR Builder image
# Prebuilt images: https://s.georgar.de/builds/docker/avr_builder

FROM ubuntu:22.04

WORKDIR /toolchain

COPY setupArmLibs.sh .

RUN apt-get update && \
    apt-get install -y make curl unzip && \
    /bin/bash /toolchain/setupAvrLibs.sh

ENV PATH="/opt/avr/gcc/bin:${PATH}"
