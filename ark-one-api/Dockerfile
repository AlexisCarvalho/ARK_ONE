FROM rocker/r-ver:4.4.3

# System dependencies for R packages in libraries.R

#    libpq-dev             # RPostgres
#    libcurl4-openssl-dev  # httr, curl
#    libreadline-dev       # base R, interactive
#    libx11-dev            # ggplot2, grid
#    libxt-dev             # ggplot2, grid
#    libpng-dev            # png support for ggplot2
#    libjpeg-dev           # jpeg support for ggplot2
#    libcairo2-dev         # ggplot2, grid
#    libssl-dev            # httr, curl, jose
#    libbz2-dev            # compression
#    libzstd-dev           # compression
#    liblzma-dev           # compression
#    libtiff5-dev          # tiff support for ggplot2
#    gfortran              # forecast, lapack/blas
#    libblas-dev           # forecast, lapack/blas
#    liblapack-dev         # forecast, lapack/blas
#    libsodium-dev         # sodium, bcrypt

RUN apt-get update && apt-get install -y \
    libpq-dev \
    libcurl4-openssl-dev \
    libreadline-dev \
    libx11-dev \
    libxt-dev \
    libpng-dev \
    libjpeg-dev \
    libcairo2-dev \
    libssl-dev \
    libbz2-dev \
    libzstd-dev \
    liblzma-dev \
    libtiff5-dev \
    gfortran \
    libblas-dev \
    liblapack-dev \
    libsodium-dev \
    && rm -rf /var/lib/apt/lists/*

# Install plumber and renv
RUN install2.r --error plumber renv

WORKDIR /app

# Copie apenas arquivos necessários para restaurar dependências primeiro
COPY renv.lock renv.lock
COPY renv/activate.R renv/activate.R
COPY .Rprofile .Rprofile

# Restaure as dependências do renv antes de copiar o restante do código
RUN Rscript -e "renv::restore(prompt = FALSE)"

# Agora copie o restante do projeto (exceto renv.lock, renv/, .Rprofile já copiados)
COPY . /app

# Expose the port
EXPOSE 8000

# Set environment variables (override with docker run -e)

# +------------------------------+
# |   DATA ENTRY CONFIGURATION   |
# +------------------------------+

ENV PORT=8000
ENV HOST=0.0.0.0

# +------------------------------+
# |   DATABASE CONFIGURATION     |
# +------------------------------+

# Name of the database
ENV DB_NAME=one_database

# Server Address Information
ENV DB_HOST=172.17.0.2

# User credentials to access the database
ENV DB_USER=postgres
ENV DB_PASSWORD=user1232025

# Database Port
ENV DB_PORT=5432

# +------------------------------+
# |             KEYS             |
# +------------------------------+

# Token generation Key
ENV TOKEN_SECRET_KEY=jTkdh7uIhG5hHGTjh1jjd6sll7lYUY2D2bvkkldk

# Run the API
CMD ["Rscript", "plumber.R"]
