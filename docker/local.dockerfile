FROM golang:1.22-alpine AS builder

ARG VERSION=unknown

# copy project
COPY cmd /app/cmd
COPY internal /app/internal
COPY pkg /app/pkg
COPY go.mod /app/go.mod
COPY go.sum /app/go.sum

# set working directory
WORKDIR /app

# using goproxy if you have network issues
# ENV GOPROXY=https://goproxy.cn,direct

# build
RUN go build \
    -ldflags "\
    -X 'github.com/langgenius/dify-plugin-daemon/internal/manifest.VersionX=${VERSION}' \
    -X 'github.com/langgenius/dify-plugin-daemon/internal/manifest.BuildTimeX=$(date -u +%Y-%m-%dT%H:%M:%S%z)'" \
    -o /app/main cmd/server/main.go

# copy entrypoint.sh
COPY entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh

FROM ubuntu:24.04

COPY --from=builder /app/main /app/main
COPY --from=builder /app/entrypoint.sh /app/entrypoint.sh

WORKDIR /app

# check build args
ARG PLATFORM=local

# Install python3.12 if PLATFORM is local
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y curl python3.12 python3.12-venv python3.12-dev python3-pip ffmpeg build-essential \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.12 1;

    # preload tiktoken
ENV TIKTOKEN_CACHE_DIR=/app/.tiktoken

# Install uv
RUN mv /usr/lib/python3.12/EXTERNALLY-MANAGED /usr/lib/python3.12/EXTERNALLY-MANAGED.bk && python3 -m pip install uv

# Install dify_plugin to speedup the environment setup
RUN uv pip install --system dify_plugin

# Test uv
RUN python3 -c "from uv._find_uv import find_uv_bin;print(find_uv_bin())" \
    && python3 -c "import tiktoken; tiktoken.get_encoding('gpt2').special_tokens_set; tiktoken.get_encoding('cl100k_base').special_tokens_set"

ENV PLATFORM=$PLATFORM \
    GIN_MODE=release \
    LANG="zh_CN.UTF-8" \
    LC_ALL="zh_CN.UTF-8" \
    LANGUAGE="zh_CN:en_US:ja_JP:ko_KR" \
    FONTCONFIG_PATH=/etc/fonts

# run the server, using sh as the entrypoint to avoid process being the root process
# and using bash to recycle resources
CMD ["/bin/bash", "-c", "/app/entrypoint.sh"]
