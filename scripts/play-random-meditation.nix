{ pkgs }:

pkgs.writeShellScriptBin "meditation" ''
      # Check if any media is currently playing
      if playerctl status 2>/dev/null | grep -q "Playing"; then
          echo "Media is currently playing. Stopping all players..."
          playerctl pause
          sleep 1
      fi
      MEDITATION_DIR="$HOME/Pictures/meditation"

      # Check if directory exists
      if [ ! -d "$MEDITATION_DIR" ]; then
          echo "Error: Meditation directory not found at $MEDITATION_DIR"
          exit 1
      fi

      # Find all webm files and select one randomly
      VIDEO=$(find "$MEDITATION_DIR" -type f -name "*.webm" | shuf -n 1)

      if [ -z "$VIDEO" ]; then
          echo "Error: No .webm files found in $MEDITATION_DIR"
          exit 1
      fi

      # Play the selected video using mpv
      echo "Playing: $(basename "$VIDEO")"
      mpv "$VIDEO"
''
