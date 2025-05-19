FROM --platform=linux/amd64 ubuntu:24.04
RUN apt update
RUN apt install curl unzip zsh git sudo \
  build-essential wget libssl-dev software-properties-common \
  python3-requests python3-apt python3.12-venv python3-pip -y

RUN curl https://starship.rs/install.sh --output ./starship.sh;chmod +x ./starship.sh;./starship.sh -y;rm ./starship.sh

RUN curl -L https://dl.dagger.io/dagger/install.sh | BIN_DIR=$HOME/.local/bin sh

ARG ZIG_VERSION=zig-linux-x86_64-0.14.0
ARG ZLS_VERSION=0.14.0
# ARG ZIG_DOWNLOAD=https://ziglang.org/builds/$ZIG_VERSION.tar.xz
ARG ZIG_DOWNLOAD=https://ziglang.org/download/$ZLS_VERSION/$ZIG_VERSION.tar.xz
RUN curl $ZIG_DOWNLOAD --output /tmp/zig.tar.xz; tar -xf /tmp/zig.tar.xz -C /tmp; mkdir /root/.zig; cp -r /tmp/$ZIG_VERSION/.  /root/.zig/; chmod 777  /root/.zig
RUN curl -L https://github.com/zigtools/zls/releases/download/$ZLS_VERSION/zls-x86_64-linux.tar.xz --output /root/zls.tar.xz; tar -xf  /root/zls.tar.xz -C  /root; cp -r  /root/zls  /root/.zig/; chmod 777  /root/.zig/zls; rm -rf  /root/zls.tar.xz  /root/bin /root/zls
RUN curl https://raw.githubusercontent.com/Hamm1/devbox/main/zshrc --output ~/.zshrc
RUN git clone https://github.com/zsh-users/zsh-autosuggestions ~/.zsh/zsh-autosuggestions

RUN chsh -s $(which zsh)

WORKDIR /root
