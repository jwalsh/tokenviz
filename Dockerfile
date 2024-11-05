FROM ubuntu:22.04

# Install required packages
RUN apt-get update && apt-get install -y \
    tmux \
    x11-apps \
    xauth \
    make \
    && rm -rf /var/lib/apt/lists/*

# Set up working directory
WORKDIR /app

# Copy application files
COPY . .

# Set display for X11
ENV DISPLAY=:1

# Default command
CMD ["make", "dashboard"]
