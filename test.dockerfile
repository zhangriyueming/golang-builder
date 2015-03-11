FROM golang:1.4
MAINTAINER CenturyLink Labs <clt-labs-futuretech@centurylink.com>

VOLUME /src
WORKDIR /src

COPY build_environment.sh /
COPY test.sh /

ENTRYPOINT ["/test.sh"]
