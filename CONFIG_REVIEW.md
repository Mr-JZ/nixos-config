# ZaneyOS configuration review backlog

This file tracks review recommendations that were deliberately not folded into
the first hardening pass. They are useful improvements, but each needs either a
larger refactor, a workflow decision, or testing with the relevant hardware and
applications.

## Agenix migration follow-up

- After the first successful `fu` activation, confirm that
  `/run/agenix/api-keys` and `/run/agenix/gcloudrc` exist, are owned by `mr-jz`,
  and have mode `0400`. Then remove the legacy plaintext files
  `~/.cache/api_keys` and `~/.gcloudrc`.
- Edit encrypted values from the `secrets` directory with agenix and
  `RULES=secrets.nix`; never place decrypted values in Nix expressions or commit
  plaintext copies.

## Package and development environments

- Move user-facing applications and ordinary CLI tools out of
  `environment.systemPackages` and into Home Manager.
- Move project-specific compilers, SDKs, language servers, and build tools into
  per-project `devShells` or `devenv` environments.
- Replace global `allowUnfree = true` with an `allowUnfreePredicate` after
  documenting the proprietary applications that are intentionally installed.
- Audit the custom `gorun` derivation and pin it to a commit instead of the
  `master` branch name.

## Module structure

- Continue splitting the large host files into focused modules for boot,
  networking, locale, audio, desktop, gaming, YubiKey, virtualization, and
  development tools.
- Create a shared workstation profile instead of maintaining mostly duplicated
  `hosts/default` and `hosts/masterlaptop` configurations.
- Remove or modernize inactive configuration branches, including the stale
  `Europe/Berling` timezone and legacy graphics/font options in `hosts/default`.
- Convert custom driver modules to current NixOS option names and add assertions
  for mutually exclusive driver selections and required PCI bus IDs.

## Desktop services

- Replace Hyprland startup commands using `killall`, sleeps, and background
  processes with supervised systemd user services for Waybar, swaync, awww,
  NetworkManager applet, and the policy-kit agent.
- Decide whether animations are enabled or disabled globally; the Lua config
  currently disables the animation category while retaining individual curves
  and animation declarations.
- Replace placeholder string substitution in `config/hyprland.nix` with a small
  generated Lua host-data module that safely quotes values.
- Review fixed pixel positions in floating-window rules on every monitor layout.

## Authentication and accounts

- Decide whether `users.mutableUsers` should become `false`. Doing so safely
  requires managing the login password hash through agenix first.
- Remove the disabled Nushell SSH-agent bootstrap if Nushell is retired, or
  rewrite it to use the same GnuPG/YubiKey agent strategy as Bash before enabling
  Nushell.
- Review whether both U2F and Yubico challenge-response PAM stacks are needed for
  login and sudo, and document recovery access before simplifying them.

## Network exposure and services

- Keep Steam Remote Play and dedicated-server firewall openings disabled unless
  they are actively used; if enabled later, constrain exposure to trusted
  interfaces or networks where possible.
- Review every enabled daemon and graphical integration, especially libvirt,
  Podman compatibility, Syncthing, printer/scanner discovery, and device rules.

## Maintenance and validation

- Add `nix flake check` jobs for every declared host and formatting checks for
  Nix, Lua, and shell code.
- Add CI that builds each NixOS configuration without activating it.
- Consider retaining NixOS generations for 30 days while the configuration is
  on unstable, then revisit the rollback window based on actual store use.
- Remove unused flake inputs and commented configuration after confirming they
  are not part of near-term work.
