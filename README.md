# ARK_ONE

# Website and API Dependencies

In case you need to install the Website or API dependencies, you can find them listed here.

## System Dependencies

The current version of this project was tested on **Linux Mint**, but it should work on all Ubuntu-based systems, as well as Debian-based systems with some additional configuration.

To install the dependencies, you can run the **system_dependencies** script from the terminal on your Linux machine. This will automatically execute the necessary commands. Below is a list of what will be installed. If you already have the same or a newer version, the system will skip the installation for those packages, so you don't need to worry about duplicate installations.

### System Packages

- `sudo apt update -qq`: Updates the list of available packages.
- `sudo apt update`: Updates the package list again to ensure the latest version is used.
- `sudo apt upgrade -y`: Upgrades all installed packages to the latest versions.

### Docker and PostgreSQL

- `sudo apt install -y docker.io`: Installs Docker, a platform for developing, shipping, and running applications in containers.
- `sudo docker pull postgres`: Downloads the official PostgreSQL image from Docker Hub.
- `sudo docker run --name postgres -e POSTGRES_PASSWORD=user12342024 -d postgres`: Runs a PostgreSQL container with the password `user12342024` for the `postgres` user.

### Node Version Manager (NVM) and Node.js

- `sudo curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.0/install.sh | bash`: Downloads and installs NVM (Node Version Manager) to manage Node.js versions.
- `export NVM_DIR="$HOME/.nvm"`: Sets the environment variable for the NVM installation directory.
- `nvm install 22`: Installs Node.js version 22 using NVM.

### CRAN Repository and R Base Installation

- `sudo apt install -y --no-install-recommends software-properties-common dirmngr`: Installs tools necessary to add third-party repositories.
- `wget -qO- https://cloud.r-project.org/bin/linux/ubuntu/marutter_pubkey.asc | sudo tee -a /etc/apt/trusted.gpg.d/cran_ubuntu_key.asc`: Adds the public key for the CRAN repository (the official R repository).
- `sudo add-apt-repository "deb https://cloud.r-project.org/bin/linux/ubuntu $(lsb_release -cs)-cran40/"`: Adds the CRAN repository to the list of package sources.
- `sudo apt install -y --no-install-recommends r-base`: Installs R Base, the programming language for statistical analysis and graphics.

### Dependencies for R Packages

- `sudo apt-get install -y libcurl4-openssl-dev libpq-dev gfortran liblapack-dev zlib1g-dev libsodium-dev`: Installs libraries required for compiling and using R packages that rely on these libraries (e.g., curl, PostgreSQL, Fortran, LAPACK, zlib, and libsodium).

## Website

You can install all website dependencies using the `npm install` command within the project folder. If it doesn't work, you can follow the manual script below to create the project from scratch.
### Project Creation
The project was created using the following command:

`npx create-react-app ark-one-website --template typescript`

### NPM Packages
You can install the required NPM packages using the following commands, or run the website_dependencies script inside the ark-one-website folder to install them all at once:

`npm install react react-dom react-scripts typescript --save`
`npm install react-router-dom --save`
`npm install axios --save`
`npm install @mui/material @emotion/react @emotion/styled --save`
`npm install react-leaflet leaflet --save`
`npm install --save-dev @types/leaflet`
`npm install leaflet/dist/leaflet.css --save`
`npm install source-map-loader –save-dev`
`npm install html5-qrcode`

### Project Files
Copy the src folder to the new project and replace the existing one.

## API
When you first run the API, it will attempt to automatically install all the necessary libraries. However, it relies on the system_dependencies script to ensure that the installation completes without issues. The same approach applies to the Website.
