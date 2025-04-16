FROM debian:latest

# for registering SSH key; You should set this by
#  `docker build --build-arg MACHINE_NAME="${HOST}"`
ARG MACHINE_NAME 
ENV MACHINE_NAME=${MACHINE_NAME}

ADD . /root/dotfiles-agent
WORKDIR /root/dotfiles-agent

RUN bash -c 'if [-z "$MACHINE_NAME"]; then echo "MACHINE_NAME is not set"; exit 1; fi'

# Install dependencies
RUN bash 00_install_deps.sh

# Install GitHub CLI
RUN bash 10_install_gh.sh

# Setup GitHub CLI
RUN bash 20_setup_gh.sh
