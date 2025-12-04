FROM ubuntu:24.04
RUN apt update
RUN apt install curl unzip zsh git sudo \
  build-essential wget libssl-dev software-properties-common \
  python3-requests python3-apt python3.12-venv python3-pip -y

RUN curl https://starship.rs/install.sh --output ./starship.sh;chmod +x ./starship.sh;./starship.sh -y;rm ./starship.sh

RUN curl https://mise.run | sh

RUN curl https://raw.githubusercontent.com/Hamm1/devbox/main/zshrc --output ~/.zshrc
RUN git clone https://github.com/zsh-users/zsh-autosuggestions ~/.zsh/zsh-autosuggestions

RUN chsh -s $(which zsh)

WORKDIR /root
