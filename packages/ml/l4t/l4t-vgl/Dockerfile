#---
# name: l4t-vgl
# alias: vgl
# group: ml
#---
ARG BASE_IMAGE
# Use a the pytorch image provided by jetson-containers
FROM dustynv/l4t-pytorch:r36.4.0

# Set environment variables for Poetry and Python
ENV POETRY_VERSION=1.7.1 \
    POETRY_HOME="/opt/poetry" \
    POETRY_VIRTUALENVS_IN_PROJECT=true \
    POETRY_NO_INTERACTION=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=off \
	DEBIAN_FRONTEND=noninteractive

# Add Poetry to the PATH
ENV PATH="$POETRY_HOME/bin:$PATH"

# Install dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    python3 python3-venv python3-pip \
    libgl1 \
    libglib2.0-0 \
    libsm6 \
    libxrender1 \
    libxext6 \
    build-essential \
	libgdal-dev \
	gdal-bin \
    && rm -rf /var/lib/apt/lists/*

# Optional: Make 'python' point to 'python3'
RUN update-alternatives --install /usr/bin/python python /usr/bin/python3 1

# Install Poetry
RUN curl -sSL https://install.python-poetry.org | python3 -

# Clean up apt caches to reduce image size
RUN apt-get autoremove -y \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

RUN git clone -b jetson_orin https://github.com/JoseHinojosaHidalgo/visual_localization.git .

RUN git submodule update --init --recursive

RUN python3 -m venv .venv --system-site-packages

RUN poetry env use .venv/bin/python

RUN poetry lock

# Install project dependencies
RUN poetry install

# Add the virtual environment's bin directory to the PATH
ENV VIRTUAL_ENV=/app/.venv
ENV PATH="$VIRTUAL_ENV/bin:$PATH"
