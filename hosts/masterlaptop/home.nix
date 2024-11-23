{
  pkgs,
  username,
  host,
  ...
}:
let
  inherit (import ./variables.nix) gitUsername gitEmail;
in
{
  # Home Manager Settings
  home.username = "${username}";
  home.homeDirectory = "/home/${username}";
  home.stateVersion = "23.11";

  # Import Program Configurations
  imports = [
    ../../config/emoji.nix
    ../../config/hyprland.nix
    ../../config/neovim.nix
    ../../config/rofi/rofi.nix
    ../../config/rofi/config-emoji.nix
    ../../config/rofi/config-long.nix
    ../../config/swaync.nix
    ../../config/waybar.nix
    ../../config/wlogout.nix
  ];

  # Place Files Inside Home Directory
  home.file."Pictures/Wallpapers" = {
    source = ../../config/wallpapers;
    recursive = true;
  };
  home.file.".config/fastfetch" = {
    source = ../../config/fastfetch;
    recursive = true;
  };
  home.file.".config/wlogout/icons" = {
    source = ../../config/wlogout;
    recursive = true;
  };
  home.file.".face.icon".source = ../../config/face.jpg;
  home.file.".config/face.jpg".source = ../../config/face.jpg;
  home.file.".config/swappy/config".text = ''
    [Default]
    save_dir=/home/${username}/Pictures/Screenshots
    save_filename_format=swappy-%Y%m%d-%H%M%S.png
    show_panel=false
    line_size=5
    text_size=20
    text_font=Ubuntu
    paint_mode=brush
    early_exit=true
    fill_shape=false
  '';

  # Install & Configure Git
  programs.git = {
    enable = true;
    userName = "${gitUsername}";
    userEmail = "${gitEmail}";
  };

  programs.obs-studio = {
    enable = true;
    plugins = with pkgs.obs-studio-plugins; [
      wlrobs
      obs-backgroundremoval
      obs-pipewire-audio-capture
    ];
  };

  # Create XDG Dirs
  xdg = {
    userDirs = {
      enable = true;
      createDirectories = true;
    };
  };

  dconf.settings = {
    "org/virt-manager/virt-manager/connections" = {
      autoconnect = [ "qemu:///system" ];
      uris = [ "qemu:///system" ];
    };
  };

  # Styling Options
  stylix.targets.waybar.enable = false;
  stylix.targets.rofi.enable = false;
  stylix.targets.hyprland.enable = false;
  gtk = {
    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
    };
    gtk3.extraConfig = {
      gtk-application-prefer-dark-theme = 1;
    };
    gtk4.extraConfig = {
      gtk-application-prefer-dark-theme = 1;
    };
  };
  qt = {
    enable = true;
    style.name = "adwaita-dark";
    platformTheme.name = "gtk3";
  };


  # Scripts
  home.packages = [
    (import ../../scripts/emopicker9000.nix { inherit pkgs; })
    (import ../../scripts/task-waybar.nix { inherit pkgs; })
    (import ../../scripts/squirtle.nix { inherit pkgs; })
    (import ../../scripts/nvidia-offload.nix { inherit pkgs; })
    (import ../../scripts/wallsetter.nix {
      inherit pkgs;
      inherit username;
    })
    (import ../../scripts/web-search.nix { inherit pkgs; })
    (import ../../scripts/rofi-launcher.nix { inherit pkgs; })
    (import ../../scripts/screenshootin.nix { inherit pkgs; })
    (import ../../scripts/list-hypr-bindings.nix {
      inherit pkgs;
      inherit host;
    })
    # TODO: clean up this part 
    pkgs.tmux
    pkgs.neovim
    # pkgs.vimPlugins.telescope-fzf-native-nvim
    # pkgs.vimPlugins.vim-tmux-navigator
    # pkgs.lua-language-server
    pkgs.gopls
    pkgs.xclip
    pkgs.wl-clipboard
    # pkgs.luajitPackages.lua-lsp
    pkgs.nil
    pkgs.rust-analyzer
    #nodePackages.bash-language-server
    pkgs.yaml-language-server
    pkgs.pyright
    pkgs.marksman
    pkgs.fzf
    pkgs.gcc
    pkgs.fd
    pkgs.lazygit
    pkgs.cargo
    pkgs.php83
    pkgs.php83Packages.composer
    pkgs.luarocks
    pkgs.julia
    pkgs.zulu17
    pkgs.libreoffice
    # pkgs.clang
    pkgs.zoxide
    pkgs.obsidian
    # BA
    pkgs.zathura
    pkgs.zotero_7
    pkgs.plantuml
    pkgs.texliveFull
    # Devolopment
    pkgs.devpod
    pkgs.vscode
    pkgs.ticktick
    pkgs.jellyfin-media-player
    pkgs.zoom-us
    pkgs.slack
    pkgs.gum
  ];

  services = {
    hypridle = {
      settings = {
        general = {
          after_sleep_cmd = "hyprctl dispatch dpms on";
          ignore_dbus_inhibit = false;
          lock_cmd = "hyprlock";
          starship = {
            enable = true;
            package = pkgs.starship;
          };
        };
        listener = [
          {
            timeout = 900;
            on-timeout = "hyprlock";
          }
          {
            timeout = 1200;
            on-timeout = "hyprctl dispatch dpms off";
            on-resume = "hyprctl dispatch dpms on";
          }
        ];
      };
    };
  };

  programs = {
    gh.enable = true;
    btop = {
      enable = true;
      settings = {
        vim_keys = true;
      };
    };
    kitty = {
      enable = true;
      package = pkgs.kitty;
      settings = {
        scrollback_lines = 2000;
        wheel_scroll_min_lines = 1;
        window_padding_width = 4;
        confirm_os_window_close = 0;
      };
      keybindings = {
        "alt+g" = "send_key ctrl+b g";
        "alt+d" = "send_text all \\x02G";
        "alt+c" = "send_key ctrl+b c";
        "alt+x" = "send_key ctrl+b x";
        "alt+n" = "send_key ctrl+b n";
        "alt+p" = "send_key ctrl+b p";
        "alt+e" = "send_key ctrl+b e";
        "alt+z" = "send_key ctrl+b z";
        "alt+f" = "send_key ctrl+b m";
        "alt+'" = "send_key ctrl+b \"";
        # "alt+t" = "send_key ctrl+b %";
        "f1" = "send_key ctrl+b R";
        "f2" = "send_key ctrl+b K";
        "f3" = "send_key ctrl+b A";
        "f4" = "send_key ctrl+b J";
      };
      extraConfig = ''
        tab_bar_style fade
        tab_fade 1
        active_tab_font_style   bold
        inactive_tab_font_style bold
      '';
    };
    bash = {
      enable = true;
      enableCompletion = true;
      profileExtra = ''
        #if [ -z "$DISPLAY" ] && [ "$XDG_VTNR" = 1 ]; then
        #  exec Hyprland
        #fi
        if [ -f $HOME/.bashrc-personal ]; then
          source $HOME/.bashrc-personal
        fi
        eval "$(zoxide init bash)" 
        # include path to PATH
        export PATH=$PATH:$HOME/go/bin

        if command -v fzf-share >/dev/null; then
          source "$(fzf-share)/key-bindings.bash"
          source "$(fzf-share)/completion.bash"
        fi
        # SSH agent setup
        eval "$(ssh-agent -s)"
        ssh-add ~/github/github_mr-jz

        # Cache file for API keys
        API_CACHE_FILE="$HOME/.cache/api_keys"
        API_CACHE_TIMEOUT=86400  # 24 hours in seconds

        # Function to update API keys cache
        update_api_keys() {
          mkdir -p "$(dirname "$API_CACHE_FILE")"
          {
            echo "export OPENAI_API_KEY=\"$(bw get password OPENAI_API_KEY)\""
            echo "export ANTHROPIC_API_KEY=\"$(bw get password e64fda39-be64-420a-b76a-b231013cd92b)\""
            echo "export GEMINI_API_KEY=\"$(bw get password GEMINI_API_KEY)\""
            echo "export GROQ_API_KEY=\"$(bw get password GROQ_API_KEY)\""
            echo "export OPENROUTER_API_KEY=\"$(bw get password OPENROUTER_API_KEY)\""
            echo "export API_CACHE_TIMESTAMP=$(date +%s)"
          } > "$API_CACHE_FILE"
        }

        # Load or update cache
        if [ -f "$API_CACHE_FILE" ]; then
          . "$API_CACHE_FILE"
          current_time=$(date +%s)
          cache_age=$((current_time - API_CACHE_TIMESTAMP))
          
          if [ $cache_age -gt $API_CACHE_TIMEOUT ]; then
            update_api_keys
            . "$API_CACHE_FILE"
          fi
        else
          update_api_keys
          . "$API_CACHE_FILE"
        fi
      '';
      initExtra = ''
      '';
      shellAliases = {
        ai = "aider --model gemini/gemini-1.5-pro-latest --dark-mode --auto-commits $(find . -type f | fzf --multi | tr '\n' ' ')";
        sv = "sudo nvim";
        fr = "nh os switch --hostname ${host} /home/${username}/zaneyos";
        fu = "nh os switch --hostname ${host} --update /home/${username}/zaneyos";
        zu = "sh <(curl -L https://gitlab.com/Zaney/zaneyos/-/raw/main/install-zaneyos.sh)";
        ncg = "nix-collect-garbage --delete-old && sudo nix-collect-garbage -d && sudo /run/current-system/bin/switch-to-configuration boot";
        v = "nvim";
        cat = "bat";
        ls = "eza --icons";
        ll = "eza -lh --icons --grid --group-directories-first";
        la = "eza -lah --icons --grid --group-directories-first";
        ghc="gh repo clone $(gh repo list | fzf | awk '{print $1}') -- --bare";
        git-hash-copy="printf %s \"$(git rev-parse HEAD)\" | wl-copy";
        z="zoxide";
        ghd="gh dash";
        s = "sesh connect $(sesh list | fzf --height 24)";
        ".." = "cd ..";
      };
    };
    nushell = { 
          enable = false;
          extraConfig = ''
            $env.config = {
              show_banner: false
              completions: {
                case_sensitive: false
                quick: true
                partial: true
                algorithm: "fuzzy"
                external: {
                  enable: true
                  max_results: 100
                  completer: $carapace_completer
                }
              }
            }

            # Initialize zoxide
            zoxide init nushell | save -f ~/.zoxide.nu
            source ~/.zoxide.nu

            # Start SSH agent and add key
            def setup_ssh_agent [] {
                # Ensure SSH directory exists with correct permissions
                ^mkdir -p ~/.ssh
                ^chmod 700 ~/.ssh

                # Ensure GitHub key directory exists
                ^mkdir -p ~/github

                # Kill any existing ssh-agent processes
                ps | where name == 'ssh-agent' | each { |p| kill $p.pid }

                # Start new ssh-agent
                let ssh_output = (^ssh-agent -c | lines)
                
                # Parse and load SSH environment variables
                let ssh_env = ($ssh_output 
                    | first 2 
                    | parse "setenv {name} {value};" 
                    | transpose --header-row 
                    | into record)
                
                # Load the SSH environment variables
                load-env $ssh_env

                # Add SSH key if it exists
                let ssh_key = ($env.HOME + "/github/github_mr-jz")
                if ($ssh_key | path exists) {
                    # Set correct permissions for the key
                    ^chmod 600 $ssh_key
                    try {
                        ^ssh-add $ssh_key
                        # Test GitHub SSH connection
                        ^ssh -T git@github.com -o StrictHostKeyChecking=no
                    } catch {
                        print $"Failed to add SSH key: ($env.LAST_ERROR)"
                    }
                } else {
                    print $"SSH key not found at ($ssh_key)"
                }
            }

            # Run SSH agent setup
            setup_ssh_agent

            # Add Go binaries to PATH
            $env.PATH = ($env.PATH | append ($env.HOME + "/go/bin"))

            # Check if flake.nix with nix shell is in the folder and run it
            if ("flake.nix" | path exists) and (open flake.nix | str contains "devShells") {
              ^nix develop
            }
          '';
          shellAliases = {
            vi = "nvim";
            vim = "nvim";
            nano = "nvim";
            sv = "sudo nvim";
            fr = "do { nh os switch --hostname ${host} /home/${username}/zaneyos }";
            fu = "do { nh os switch --hostname ${host} --update /home/${username}/zaneyos }";
            zu = "do { curl -L https://gitlab.com/Zaney/zaneyos/-/raw/main/install-zaneyos.sh | sh }";
            ncg = "do { nix-collect-garbage --delete-old; sudo nix-collect-garbage -d; sudo /run/current-system/bin/switch-to-configuration boot }";
            v = "nvim";
            cat = "bat";
            ghc = "do { gh repo clone (gh repo list | fzf | split row --regex '\\s+' | get 0) -- --bare }";
            git-hash-copy = "do { git rev-parse HEAD | save --raw | pbcopy }";
            z = "zoxide";
            ghd = "gh dash";
            s = "do { sesh connect (sesh list | fzf --height 24) }";
            ".." = "cd ..";
          };
        };
    carapace.enable = true;
    carapace.enableNushellIntegration = true;

    starship = { enable = true;
        settings = {
          add_newline = true;
          character = { 
          success_symbol = "[➜](bold green)";
          error_symbol = "[➜](bold red)";
        };
      };
    };
    home-manager.enable = true;
    hyprlock = {
      enable = true;
      settings = let
        lib = pkgs.lib;
      in {
        general = {
          disable_loading_bar = true;
          grace = 10;
          hide_cursor = true;
          no_fade_in = false;
        };
        background = lib.mkForce [
          {
            path = "/home/${username}/Pictures/Wallpapers/mountainscapedark.jpg";
            blur_passes = 3;
            blur_size = 8;
          }
        ];
        image = [
          {
            path = "/home/${username}/.config/face.jpg";
            size = 150;
            border_size = 4;
            border_color = "rgb(0C96F9)";
            rounding = -1; # Negative means circle
            position = "0, 200";
            halign = "center";
            valign = "center";
          }
        ];
        input-field = lib.mkForce [
          {
            size = "200, 50";
            position = "0, -80";
            monitor = "";
            dots_center = true;
            fade_on_empty = false;
            font_color = "rgb(CFE6F4)";
            inner_color = "rgb(657DC2)";
            outer_color = "rgb(0D0E15)";
            outline_thickness = 5;
            placeholder_text = "Password...";
            shadow_passes = 2;
          }
        ];
      };
    };
  };
}
