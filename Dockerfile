# All credit goes to Yves Blusseau, Nicolas Duchon, and all the contributors of the original Github repository
FROM arm32v7/golang:1.18.3-alpine AS go-builder

ENV DOCKER_GEN_VERSION=0.7.4

# Build docker-gen
RUN apk add --no-cache --virtual .build-deps \
        curl \
        gcc \
        git \
        make \
        musl-dev \
    && go get github.com/jwilder/docker-gen \
    && cd /go/src/github.com/jwilder/docker-gen \
    && git -c advice.detachedHead=false checkout $DOCKER_GEN_VERSION \
    && make get-deps \
    && make all \
    && go clean -cache \
    && mv docker-gen /usr/local/bin/ \
    && rm -rf /go/src \
    && apk del .build-deps

FROM arm32v7/alpine:3.12.3

LABEL maintainer="Alexander Krause <akr@informatik.uni-kiel.de>"

ARG GIT_DESCRIBE
ARG ACMESH_VERSION=2.8.8

ENV COMPANION_VERSION=$GIT_DESCRIBE \
    DOCKER_HOST=unix:///var/run/docker.sock \
    PATH=$PATH:/app

# Install packages required by the image
RUN apk add --no-cache --virtual .bin-deps \
        bash \
        coreutils \
        curl \
        jq \
        openssl \
        socat

# Install docker-gen from build stage
COPY --from=go-builder /usr/local/bin/docker-gen /usr/local/bin/

# Install acme.sh
COPY /install_acme.sh /app/install_acme.sh
RUN chmod +rx /app/install_acme.sh \
    && sync \
    && /app/install_acme.sh \
    && rm -f /app/install_acme.sh

COPY /app/ /app/

WORKDIR /app

ENTRYPOINT [ "/bin/bash", "/app/entrypoint.sh" ]
CMD [ "/bin/bash", "/app/start.sh" ]
