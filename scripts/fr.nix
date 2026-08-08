{ pkgs, host, username }:

pkgs.writeShellApplication {
  name = "fr";
  runtimeInputs = with pkgs; [
    coreutils
    gnugrep
    systemd
    nh
  ];
  text = ''
    log_dir="''${XDG_STATE_HOME:-$HOME/.local/state}/zaneyos"
    mkdir -p "$log_dir"

    timestamp="$(${pkgs.coreutils}/bin/date +%Y%m%d-%H%M%S)"
    log_file="$log_dir/fr-$timestamp.log"
    latest_log="$log_dir/fr-latest.log"
    before_services="$(${pkgs.coreutils}/bin/mktemp)"
    after_services="$(${pkgs.coreutils}/bin/mktemp)"
    started_at="$(${pkgs.coreutils}/bin/date --iso-8601=seconds)"

    trap 'rm -f "$before_services" "$after_services"' EXIT

    systemctl list-units --type=service --state=active --no-legend --plain \
      | ${pkgs.coreutils}/bin/cut -d ' ' -f 1 \
      | ${pkgs.coreutils}/bin/sort -u > "$before_services" || true

    exec > >(${pkgs.gawk}/bin/awk '{ print strftime("[%Y-%m-%d %H:%M:%S]"), $0; fflush() }' | tee "$log_file") 2>&1

    echo "ZaneyOS rebuild started"
    echo "Host: ${host}"
    echo "Flake: /home/${username}/zaneyos"
    echo "Log: $log_file"
    echo

    set +e
    nh os switch --hostname ${host} /home/${username}/zaneyos "$@"
    rebuild_status=$?
    set -e

    systemctl list-units --type=service --state=active --no-legend --plain \
      | ${pkgs.coreutils}/bin/cut -d ' ' -f 1 \
      | ${pkgs.coreutils}/bin/sort -u > "$after_services" || true

    echo
    echo "=== Service state changes ==="
    stopped_services="$(${pkgs.coreutils}/bin/comm -23 "$before_services" "$after_services")"
    if [[ -n "$stopped_services" ]]; then
      echo "Services active before fr but not active afterward:"
      echo "$stopped_services"
      while IFS= read -r unit; do
        [[ -n "$unit" ]] || continue
        systemctl status "$unit" --no-pager --full || true
      done <<< "$stopped_services"
    else
      echo "No previously active service remained down."
    fi

    if (( rebuild_status != 0 )); then
      echo
      echo "=== Failed systemd units ==="
      systemctl --failed --no-pager --full || true

      echo
      echo "=== Pending systemd jobs ==="
      systemctl list-jobs --no-pager || true

      echo
      echo "=== System journal since rebuild started (warning and above) ==="
      journalctl --boot --since "$started_at" --priority=warning --no-pager --output=short-precise || true
    fi

    ln -sfn "$log_file" "$latest_log"
    echo
    echo "Rebuild exit code: $rebuild_status"
    echo "Full log: $log_file"
    echo "Latest log: $latest_log"
    exit "$rebuild_status"
  '';
}
