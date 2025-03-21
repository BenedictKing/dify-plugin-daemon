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

# Install python3.12, dependencies and CJK fonts
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y \
    curl \
    git \
    python3.12 \
    python3.12-venv \
    python3.12-dev \
    python3-pip \
    ffmpeg \
    build-essential \
    libcairo2-dev \
    libffi-dev \
    libjpeg8-dev \
    libfreetype6-dev \
    libpng-dev \
    librsvg2-dev \
    pkg-config \
    locales \
    tzdata \
    language-pack-zh-hans \
    language-pack-ja \
    language-pack-ko \
    fonts-noto-cjk \
    fonts-noto-cjk-extra \
    fonts-hanazono \
    ttf-mscorefonts-installer \
    fonts-noto \
    fonts-dejavu \
    fonts-liberation \
    fonts-ubuntu \
    ttf-wqy-microhei \
    ttf-wqy-zenhei \
    fonts-arphic-ukai \
    fonts-arphic-uming \
    xfonts-wqy \
    fonts-cwtex-kai \
    fonts-cwtex-ming \
    fonts-droid-fallback \
    fonts-nanum \
    fonts-ipafont \
    fonts-ipafont-gothic \
    fonts-ipafont-mincho \
    fonts-vlgothic \
    fonts-unfonts-core \
    fonts-roboto \
    fonts-lato \
    fonts-freefont-ttf \
    fonts-opensymbol \
    wkhtmltopdf

# Configure locale and timezone
RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && \
    sed -i '/zh_CN.UTF-8/s/^# //g' /etc/locale.gen && \
    sed -i '/ja_JP.UTF-8/s/^# //g' /etc/locale.gen && \
    sed -i '/ko_KR.UTF-8/s/^# //g' /etc/locale.gen && \
    locale-gen && \
    ln -fs /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && \
    dpkg-reconfigure -f noninteractive tzdata

# Download and install dolbydu fonts
RUN git clone https://github.com/dolbydu/font.git /tmp/font \
    && mkdir -p /usr/share/fonts/custom \
    && cp /tmp/font/unicode/* /usr/share/fonts/custom/ \
    && rm -rf /tmp/font \
    && chmod 777 /usr/share/fonts/custom

# Setup Windows fonts directory for better CJK support in node-canvas
RUN mkdir -p /usr/share/fonts/winfonts && \
    chmod 777 /usr/share/fonts/winfonts && \
    cd /usr/share/fonts && \
    mkfontscale && \
    mkfontdir && \
    fc-cache -f -v

# Configure fontconfig fallback fonts for better CJK support
RUN mkdir -p /etc/fonts/conf.d

COPY 64-language-selector-prefer.conf /etc/fonts/conf.d/

RUN fc-cache -f -v

# preload tiktoken
ENV TIKTOKEN_CACHE_DIR=/app/.tiktoken

# Install dify_plugin to speedup the environment setup, test uv and preload tiktoken
RUN update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.12 1 && \
    update-alternatives --install /usr/bin/python python /usr/bin/python3.12 1 && \
    mv /usr/lib/python3.12/EXTERNALLY-MANAGED /usr/lib/python3.12/EXTERNALLY-MANAGED.bk \
    && python3 -m pip install uv \
    && uv pip install --system dify_plugin \
    && python3 -c "from uv._find_uv import find_uv_bin;print(find_uv_bin())" \
    && python3 -c "import tiktoken; tiktoken.get_encoding('gpt2').special_tokens_set; tiktoken.get_encoding('cl100k_base').special_tokens_set"

# Install playwright and Chrome
RUN uv pip install --system playwright \
    && playwright install chrome \
    && apt-get autoremove -y \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ENV PLATFORM=$PLATFORM \
    GIN_MODE=release \
    LANG="zh_CN.UTF-8" \
    LC_ALL="zh_CN.UTF-8" \
    LANGUAGE="zh_CN:en_US:ja_JP:ko_KR" \
    FONTCONFIG_PATH=/etc/fonts

# run the server, using sh as the entrypoint to avoid process being the root process
# and using bash to recycle resources
CMD ["/bin/bash", "-c", "/app/entrypoint.sh"]
