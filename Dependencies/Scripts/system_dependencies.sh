#!/bin/bash

echo "=== Updating system packages ==="
sudo apt update -qq
sudo apt update
sudo apt upgrade -y

echo "=== Installing Docker and configuring Postgres ==="
sudo apt install -y docker.io
sudo docker pull postgres
sudo docker run --name postgres -e POSTGRES_PASSWORD=user12342024 -d postgres

echo "=== Installing Node Version Manager (NVM) and Node.js ==="
sudo curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.0/install.sh | bash
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # Load nvm
nvm install 22

echo "=== Adding CRAN repository and installing R Base ==="
sudo apt install -y --no-install-recommends software-properties-common dirmngr
wget -qO- https://cloud.r-project.org/bin/linux/ubuntu/marutter_pubkey.asc | sudo tee -a /etc/apt/trusted.gpg.d/cran_ubuntu_key.asc
sudo add-apt-repository "deb https://cloud.r-project.org/bin/linux/ubuntu $(lsb_release -cs)-cran40/"
sudo apt install -y --no-install-recommends r-base

echo "=== Installing dependencies for R packages ==="
sudo apt-get install -y libcurl4-openssl-dev libpq-dev gfortran liblapack-dev zlib1g-dev libsodium-dev

echo "=== Installation complete! ==="

