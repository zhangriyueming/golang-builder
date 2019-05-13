FROM golang:latest

RUN apt-get update && apt-get install -y upx-ucl

VOLUME /src
WORKDIR /src

COPY build_environment.sh /
COPY build.sh /

ENTRYPOINT ["/build.sh"]
