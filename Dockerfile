FROM debian:latest

RUN apt-get update && apt-get install -y \
    curl \
    unzip \
    sudo

RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
RUN unzip awscliv2.zip
RUN useradd -m docker && echo "docker:docker" | chpasswd && adduser docker sudo

RUN su docker -c "./aws/install"

COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
