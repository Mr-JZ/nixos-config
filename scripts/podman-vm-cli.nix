{ pkgs }:

pkgs.writeShellScriptBin "podman-vm-cli" ''
  if [ -z "$1" ]; then
    podman run --rm -it -v $PWD:/workdir node:latest bash
  else
    podman run --rm -it -v $PWD:/workdir "$1" bash
  fi
''
