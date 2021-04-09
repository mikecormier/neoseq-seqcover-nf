FROM ubuntu:18.04

LABEL version="1.0.0" maintainer="Mike Cormier <cormiermichaelj@gmail.com>"
ARG MOSDEPTH_VERSION="v0.3.1"
ARG SEQCOVER_VERSION="v0.0.5"

RUN apt-get update && apt-get install -y procps wget
RUN wget -qO /usr/local/bin/mosdepth https://github.com/brentp/mosdepth/releases/download/${MOSDEPTH_VERSION}/mosdepth && chmod +x /usr/local/bin/mosdepth
RUN wget -qO /usr/local/bin/seqcover https://github.com/brentp/seqcover/releases/download/${SEQCOVER_VERSION}/seqcover && chmod +x /usr/local/bin/seqcover
