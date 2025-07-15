#!/bin/bash

echo "=== Updating system packages ==="
sudo apt update -qq
sudo apt update
sudo apt upgrade -y

echo "=== Installing essential packages ==="

PACKAGES=(
    libpq-dev
    libcurl4-openssl-dev
    libreadline-dev
    libx11-dev
    libxt-dev
    libpng-dev
    libjpeg-dev
    libcairo2-dev
    libssl-dev
    libbz2-dev
    libzstd-dev
    liblzma-dev
    libtiff5-dev
    gfortran
    libblas-dev
    liblapack-dev
    libsodium-dev
)

sudo apt-get install -y "${PACKAGES[@]}"

echo "=== Installing Docker and configuring Postgres ==="
sudo apt install -y docker.io
sudo docker pull postgres
sudo docker run --name postgres -e POSTGRES_PASSWORD=user1232025 -d postgres

echo "=== Installing Node Version Manager (NVM) and Node.js ==="
sudo curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.0/install.sh | bash
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
nvm install 22

echo "=== Adding CRAN repository and installing R Base ==="
sudo apt install -y --no-install-recommends software-properties-common dirmngr
wget -qO- https://cloud.r-project.org/bin/linux/ubuntu/marutter_pubkey.asc | sudo tee -a /etc/apt/trusted.gpg.d/cran_ubuntu_key.asc
sudo add-apt-repository "deb https://cloud.r-project.org/bin/linux/ubuntu $(lsb_release -cs)-cran40/"
sudo apt install -y --no-install-recommends r-base

echo "=== Installation complete! ==="