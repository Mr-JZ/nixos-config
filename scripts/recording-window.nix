{ pkgs }:

pkgs.writeShellScriptBin "set-recording-window" ''
  # Get the current size of the active window
  CURRENT_SIZE=$(hyprctl activewindow | grep "size:" | awk '{print $2}')
  CURRENT_WIDTH=$(echo $CURRENT_SIZE | cut -d',' -f1)
  CURRENT_HEIGHT=$(echo $CURRENT_SIZE | cut -d',' -f2)

  # Desired size (e.g., 1920x1080)
  DESIRED_WIDTH=1920
  DESIRED_HEIGHT=1080

  # Calculate the differences
  DELTA_WIDTH=$((DESIRED_WIDTH - CURRENT_WIDTH))
  DELTA_HEIGHT=$((DESIRED_HEIGHT - CURRENT_HEIGHT))

  # Apply the size difference
  hyprctl dispatch setfloating
  hyprctl dispatch resizeactive "$DELTA_WIDTH" "$DELTA_HEIGHT"
  hyprctl dispatch centerwindow
''
