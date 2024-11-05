# TokenViz

Simple X11-based token usage visualization using xload and tmux.

## Requirements

- tmux
- XQuartz (on macOS)
- Basic Unix tools (tail, grep, etc.)

## Usage

```bash
# Start the visualization dashboard
make dashboard

# Stop everything
make stop
```

## Components

- Simple random token generators
- Basic log aggregation
- xload-based visualization
- tmux-based dashboard

## Layout

The dashboard shows:
- Left: Generator logs
- Middle: Aggregated totals
- Right: xload visualization
