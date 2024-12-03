{ pkgs }:

pkgs.writeShellScriptBin "meditation" ''
  # choose from the folder ~/Pictures/meditation/ one random video and play that
  # bash the videos are in the webm format
  cd ~/Pictures/meditation/
  video=$(ls | shuf -n 1)
  ${pkgs.mpv}/bin/mpv --input-ipc-server=/tmp/mpvsoc$(date +%s) ${video}
''
