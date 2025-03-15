FROM golang:1.22-alpine AS builder

ARG VERSION=unknown

# copy project
COPY . /app

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
    python3.12 \
    python3.12-venv \
    python3.12-dev \
    python3-pip \
    ffmpeg \
    build-essential \
    libcairo2-dev \
    libffi-dev \
    fonts-noto-cjk \
    fonts-noto-cjk-extra \
    ttf-hanazono \
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
    fonts-cns11643 \
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
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Setup Windows fonts directory for better CJK support in node-canvas
RUN mkdir -p /usr/share/fonts/winfonts && \
    chmod 777 /usr/share/fonts/winfonts && \
    cd /usr/share/fonts && \
    mkfontscale && \
    mkfontdir && \
    fc-cache -f -v

# Configure fontconfig fallback fonts for better CJK support
RUN mkdir -p /etc/fonts/conf.d && \
    cat > /etc/fonts/conf.d/64-language-selector-prefer.conf << 'EOF'
<?xml version="1.0"?>
<!DOCTYPE fontconfig SYSTEM "fonts.dtd">
<fontconfig>
    <alias>
        <family>serif</family>
        <prefer>
            <family>Bitstream Vera Serif</family>
            <family>SimSun</family>
            <family>DejaVu Serif</family>
            <family>AR PL ShanHeiSun Uni</family>
            <family>AR PL ZenKai Uni</family>
            <family>Noto Serif CJK SC</family>
        </prefer>
    </alias>
    <alias>
        <family>sans-serif</family>
        <prefer>
            <family>Bitstream Vera Sans</family>
            <family>SimSun</family>
            <family>DejaVu Sans</family>
            <family>AR PL ShanHeiSun Uni</family>
            <family>AR PL ZenKai Uni</family>
            <family>Noto Sans CJK SC</family>
        </prefer>
    </alias>
    <alias>
        <family>monospace</family>
        <prefer>
            <family>Bitstream Vera Sans Mono</family>
            <family>SimSun</family>
            <family>DejaVu Sans Mono</family>
            <family>AR PL ShanHeiSun Uni</family>
            <family>AR PL ZenKai Uni</family>
            <family>Noto Sans Mono CJK SC</family>
        </prefer>
    </alias>
    
    <!-- SVG specific font mappings -->
    <alias>
        <family>楷体</family>
        <prefer>
            <family>KaiTi</family>
            <family>KaiTi_GB2312</family>
            <family>AR PL UKai</family>
            <family>AR PL ZenKai</family>
            <family>cwTeX Q Kai</family>
            <family>Noto Sans CJK SC</family>
        </prefer>
    </alias>
    <alias>
        <family>明朝体</family>
        <prefer>
            <family>MS Mincho</family>
            <family>IPAMincho</family>
            <family>cwTeX Q Ming</family>
            <family>Noto Serif CJK JP</family>
            <family>Noto Serif CJK SC</family>
        </prefer>
    </alias>
    <alias>
        <family>Arial</family>
        <prefer>
            <family>Arial</family>
            <family>Liberation Sans</family>
            <family>Roboto</family>
            <family>Lato</family>
            <family>DejaVu Sans</family>
        </prefer>
    </alias>
    <alias>
        <family>MS Gothic</family>
        <prefer>
            <family>MS Gothic</family>
            <family>IPAGothic</family>
            <family>VL Gothic</family>
            <family>Noto Sans CJK JP</family>
            <family>Noto Sans CJK SC</family>
        </prefer>
    </alias>
    <alias>
        <family>黑体</family>
        <prefer>
            <family>SimHei</family>
            <family>Noto Sans CJK SC</family>
            <family>WenQuanYi Zen Hei</family>
            <family>Droid Sans Fallback</family>
        </prefer>
    </alias>
    <alias>
        <family>宋体</family>
        <prefer>
            <family>SimSun</family>
            <family>Noto Serif CJK SC</family>
            <family>AR PL SungtiL GB</family>
            <family>cwTeX Q Ming</family>
        </prefer>
    </alias>
    
    <!-- Additional font mappings -->
    <alias>
        <family>仿宋</family>
        <prefer>
            <family>FangSong</family>
            <family>FangSong_GB2312</family>
            <family>STFangsong</family>
            <family>Noto Serif CJK SC</family>
        </prefer>
    </alias>
    <alias>
        <family>隶书</family>
        <prefer>
            <family>LiSu</family>
            <family>Noto Sans CJK SC</family>
        </prefer>
    </alias>
    <alias>
        <family>微软雅黑</family>
        <prefer>
            <family>Microsoft YaHei</family>
            <family>WenQuanYi Micro Hei</family>
            <family>Noto Sans CJK SC</family>
        </prefer>
    </alias>
    <alias>
        <family>思源黑体</family>
        <prefer>
            <family>Source Han Sans CN</family>
            <family>Noto Sans CJK SC</family>
        </prefer>
    </alias>
    <alias>
        <family>思源宋体</family>
        <prefer>
            <family>Source Han Serif CN</family>
            <family>Noto Serif CJK SC</family>
        </prefer>
    </alias>
    <alias>
        <family>나눔고딕</family> <!-- NanumGothic -->
        <prefer>
            <family>NanumGothic</family>
            <family>Noto Sans CJK KR</family>
        </prefer>
    </alias>
    <alias>
        <family>나눔명조</family> <!-- NanumMyeongjo -->
        <prefer>
            <family>NanumMyeongjo</family>
            <family>Noto Serif CJK KR</family>
        </prefer>
    </alias>
    
    <match target="font">
        <test name="family" compare="contains">
            <string>SimSun</string>
            <string>宋体</string>
            <string>宋体-18030</string>
            <string>Song</string>
            <string>Sun</string>
            <string>Kai</string>
            <string>Ming</string>
            <string>黑体</string>
            <string>新宋体</string>
            <string>新宋体-18030</string>
            <string>楷体_GB2312</string>
            <string>仿宋_GB2312</string>
            <string>隶体</string>
            <string>SimSun-18030</string>
            <string>SimHei</string>
            <string>NSimSun</string>
            <string>NSimSun-18030</string>
            <string>KaiTi_GB2312</string>
            <string>FangSong_GB2312</string>
            <string>LiSu</string>
            <string>楷体</string>
            <string>明朝体</string>
            <string>MS Gothic</string>
            <string>仿宋</string>
            <string>隶书</string>
            <string>微软雅黑</string>
            <string>思源黑体</string>
            <string>思源宋体</string>
            <string>Microsoft YaHei</string>
            <string>Source Han Sans CN</string>
            <string>Source Han Serif CN</string>
            <string>cwTeX Q Kai</string>
            <string>cwTeX Q Ming</string>
            <string>IPAGothic</string>
            <string>IPAMincho</string>
            <string>NanumGothic</string>
            <string>NanumMyeongjo</string>
            <string>나눔고딕</string>
            <string>나눔명조</string>
        </test>
        <edit name="globaladvance">
            <bool>false</bool>
        </edit>
        <edit name="spacing">
            <int>0</int>
        </edit>
        <edit name="hinting">
            <bool>true</bool>
        </edit>
        <edit name="autohint">
            <bool>false</bool>
        </edit>
        <edit name="antialias" mode="assign">
            <bool>true</bool>
        </edit>
        <test name="pixelsize" compare="more_eq">
            <int>12</int>
        </test>
        <test name="pixelsize" compare="less_eq">
            <int>24</int>
        </test>
        <edit name="antialias" mode="assign">
            <bool>false</bool>
        </edit>
    </match>
    <match target="font">
        <test name="weight" compare="less_eq">
            <int>100</int>
        </test>
        <test compare="more_eq" target="pattern" name="weight">
            <int>180</int>
        </test>
        <edit mode="assign" name="embolden">
            <bool>true</bool>
        </edit>
    </match>
</fontconfig>
EOF
    fc-cache -f -v

# Set python3.12 as default
RUN update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.12 1 && \
    update-alternatives --install /usr/bin/python python /usr/bin/python3.12 1 && \
    mv /usr/lib/python3.12/EXTERNALLY-MANAGED /usr/lib/python3.12/EXTERNALLY-MANAGED.bk \
    && python3 -m pip install uv

# Test uv
RUN python3 -c "from uv._find_uv import find_uv_bin;print(find_uv_bin())"

# Install dify_plugin to speedup the environment setup
RUN uv pip install --system dify_plugin

# Install playwright and Chrome
RUN uv pip install --system playwright \
    && playwright install chrome

ENV PLATFORM=$PLATFORM
ENV GIN_MODE=release

# run the server, using sh as the entrypoint to avoid process being the root process
# and using bash to recycle resources
CMD ["/bin/bash", "-c", "/app/entrypoint.sh"]
