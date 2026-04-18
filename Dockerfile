# Use NVIDIA CUDA base image with cuDNN and devel tools (Ubuntu 24.04)
FROM nvidia/cuda:12.6.3-cudnn-devel-ubuntu24.04

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1

# Install system dependencies
# python3, pip, git, and libraries required for OpenCV (gl1, glib2, etc.)
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    python3-dev \
    python3-venv \
    git \
    libglib2.0-0 \
    libsm6 \
    ffmpeg \
    libgl1 \
    libxext6 \
    libxrender-dev \
    npm \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Create and activate virtual environment
ENV VIRTUAL_ENV=/opt/venv
RUN python3 -m venv $VIRTUAL_ENV
ENV PATH="$VIRTUAL_ENV/bin:$PATH"

COPY pyproject.toml .

# Install Python dependencies inside the venv
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -e ".[dev,inference]"

RUN pip install "depth-anything-3 @ git+https://github.com/ByteDance-Seed/Depth-Anything-3@main"

# Download model
RUN python3 -c 'from depth_anything_3.api import DepthAnything3; DepthAnything3.from_pretrained("depth-anything/DA3METRIC-LARGE")' || true

# Copy the rest of the application code
COPY . .

RUN chmod +x "/app/start.sh"

ENV PYTHONPATH=/app

WORKDIR /app/webapp
RUN npm install
WORKDIR /app


CMD ["/app/start.sh"]
