FROM golang:1.8

RUN apt-get update && apt-get install -y upx-ucl

VOLUME /src
WORKDIR /src

COPY build_environment.sh /
COPY build.sh /

RUN chmod +x /build_environment.sh /build.sh

ENTRYPOINT ["/build.sh"]
