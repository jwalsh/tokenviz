# Setup Instructions

1. Ensure XQuartz is installed (macOS):
   ```bash
   brew install --cask xquartz
   ```

2. Install tmux:
   ```bash
   brew install tmux  # macOS
   # or
   sudo apt install tmux  # Ubuntu/Debian
   ```

3. Start XQuartz and enable network connections:
   - Open XQuartz
   - XQuartz -> Preferences -> Security
   - Check "Allow connections from network clients"

4. Launch the dashboard:
   ```bash
   make dashboard
   ```
