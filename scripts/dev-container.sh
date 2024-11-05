#!/bin/bash
# scripts/dev-container.sh
# Development container setup and launch for TokenViz

set -eo pipefail

IMAGE_NAME="tokenviz"
CONTAINER_NAME="tokenviz-dev"

function build() {
    echo "Building $IMAGE_NAME development container..."
    docker build -t "$IMAGE_NAME" .
}

function run() {
    echo "Starting $IMAGE_NAME with X11 support..."
    docker run -it --rm \
        --name "$CONTAINER_NAME" \
        -v /tmp/.X11-unix:/tmp/.X11-unix \
        "$IMAGE_NAME"
}

case "${1:-all}" in  # Changed default to 'all'
    build)
        build
        ;;
    run)
        run
        ;;
    all)
        build && run
        ;;
    *)
        echo "Usage: $0 {build|run|all} (defaults to all)"
        exit 1
        ;;
esac
