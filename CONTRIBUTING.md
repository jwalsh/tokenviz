# Contributing to TokenViz

## Development Setup

1. Fork and clone the repository
2. Ensure XQuartz is installed (macOS)
3. Run tests: `make test`
4. Submit PR with clear description

## Container Development

```bash
# Build container
docker build -t tokenviz .

# Run with X11 socket mounted
docker run -v /tmp/.X11-unix:/tmp/.X11-unix tokenviz
```

## Testing
- Run `make test-display` to verify X11 setup
- Run `make test` for full test suite
- Ensure clean shutdown with `make stop`
