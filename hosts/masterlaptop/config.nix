{
  config,
  pkgs,
  host,
  username,
  options,
  inputs,
  ...
}:

{
  imports = [
    ./hardware.nix
    ./users.nix
    ../../modules/amd-drivers.nix
    ../../modules/nvidia-drivers.nix
    ../../modules/nvidia-prime-drivers.nix
    ../../modules/intel-drivers.nix
    ../../modules/vm-guest-services.nix
    ../../modules/local-hardware-clock.nix
  ]; 

  boot = {
    # Kernel
    kernelPackages = pkgs.linuxPackages_zen;
    # This is for OBS Virtual Cam Support
    kernelModules = [ "v4l2loopback" ];
    extraModulePackages = [ config.boot.kernelPackages.v4l2loopback ];
    # Needed For Some Steam Games
    kernel.sysctl = {
      "vm.max_map_count" = 2147483642;
    };
    # Bootloader.
    loader.systemd-boot.enable = true;
    loader.efi.canTouchEfiVariables = true;
    # Make /tmp a tmpfs
    tmp = {
      useTmpfs = false;
      tmpfsSize = "30%";
    };
    # Appimage Support
    binfmt.registrations.appimage = {
      wrapInterpreterInShell = false;
      interpreter = "${pkgs.appimage-run}/bin/appimage-run";
      recognitionType = "magic";
      offset = 0;
      mask = ''\xff\xff\xff\xff\x00\x00\x00\x00\xff\xff\xff'';
      magicOrExtension = ''\x7fELF....AI\x02'';
    };
    plymouth.enable = true;
  };

  # Styling Options
  stylix = {
    enable = true;
    image = ../../config/wallpapers/beautifulmountainscape.jpg;
    # base16Scheme = {
    #   base00 = "232136";
    #   base01 = "2a273f";
    #   base02 = "393552";
    #   base03 = "6e6a86";
    #   base04 = "908caa";
    #   base05 = "e0def4";
    #   base06 = "e0def4";
    #   base07 = "56526e";
    #   base08 = "eb6f92";
    #   base09 = "f6c177";
    #   base0A = "ea9a97";
    #   base0B = "3e8fb0";
    #   base0C = "9ccfd8";
    #   base0D = "c4a7e7";
    #   base0E = "f6c177";
    #   base0F = "56526e";
    # };
    polarity = "dark";
    opacity.terminal = 0.8;
    cursor.package = pkgs.bibata-cursors;
    cursor.name = "Bibata-Modern-Ice";
    cursor.size = 24;
    fonts = {
      monospace = {
        package = pkgs.nerdfonts.override { fonts = [ "JetBrainsMono" ]; };
        name = "JetBrainsMono Nerd Font Mono";
      };
      sansSerif = {
        package = pkgs.montserrat;
        name = "Montserrat";
      };
      serif = {
        package = pkgs.montserrat;
        name = "Montserrat";
      };
      sizes = {
        applications = 12;
        terminal = 15;
        desktop = 11;
        popups = 12;
      };
    };
  };

  # Extra Module Options
  drivers.amdgpu.enable = true;
  drivers.nvidia.enable = false;
  drivers.nvidia-prime = {
    enable = false;
    intelBusID = "";
    nvidiaBusID = "";
  };
  drivers.intel.enable = false;
  vm.guest-services.enable = false;
  local.hardware-clock.enable = false;

  # Enable networking
  networking = {
    networkmanager.enable = true;
    hostName = host;
    timeServers = options.networking.timeServers.default ++ [ "pool.ntp.org" ];
    extraHosts = ''
    # Blocked Sites
    # 127.0.0.1 youtube.com
    # 127.0.0.1 www.youtube.com
    # 127.0.0.1 m.youtube.com
    # 127.0.0.1 twitch.tv
    # 127.0.0.1 www.twitch.tv
    127.0.0.1 instagram.com
    127.0.0.1 www.instagram.com
    # 127.0.0.1 reddit.com
    # 127.0.0.1 www.reddit.com
    # 127.0.0.1 old.reddit.com
    127.0.0.1 twitter.com
    127.0.0.1 x.com
    127.0.0.1 tiktok.com
    127.0.0.1 www.tiktok.com
    127.0.0.1 facebook.com
    127.0.0.1 www.facebook.com
    127.0.0.1 pinterest.com
    127.0.0.1 www.pinterest.com
    
    # Block common subdomains
    127.0.0.1 gaming.youtube.com
    127.0.0.1 music.youtube.com
    127.0.0.1 studio.youtube.com
    127.0.0.1 youtu.be
    127.0.0.1 player.twitch.tv
  '';
  };

  # Set your time zone.
  time.timeZone = "Europe/Berlin";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  programs = {
    firefox.enable = true;
    starship = {
      enable = true;
      settings = {
        add_newline = false;
        buf = {
          symbol = " ";
        };
        c = {
          symbol = " ";
        };
        directory = {
          read_only = " 󰌾";
        };
        docker_context = {
          symbol = " ";
        };
        fossil_branch = {
          symbol = " ";
        };
        git_branch = {
          symbol = " ";
        };
        golang = {
          symbol = " ";
        };
        hg_branch = {
          symbol = " ";
        };
        hostname = {
          ssh_symbol = " ";
        };
        lua = {
          symbol = " ";
        };
        memory_usage = {
          symbol = "󰍛 ";
        };
        meson = {
          symbol = "󰔷 ";
        };
        nim = {
          symbol = "󰆥 ";
        };
        nix_shell = {
          symbol = " ";
        };
        nodejs = {
          symbol = " ";
        };
        ocaml = {
          symbol = " ";
        };
        package = {
          symbol = "󰏗 ";
        };
        python = {
          symbol = " ";
        };
        rust = {
          symbol = " ";
        };
        swift = {
          symbol = " ";
        };
        zig = {
          symbol = " ";
        };
      };
    };
    dconf.enable = true;
    seahorse.enable = true;
    fuse.userAllowOther = true;
    mtr.enable = true;
    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
    };
    virt-manager.enable = true;
    steam = {
      enable = true;
      gamescopeSession.enable = true;
      remotePlay.openFirewall = true;
      dedicatedServer.openFirewall = true;
    };
    thunar = {
      enable = true;
      plugins = with pkgs.xfce; [
        thunar-archive-plugin
        thunar-volman
      ];
    };
  };

  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.allowUnsupportedSystem = true;

  users = {
    mutableUsers = true;
  };

  environment.systemPackages = with pkgs; [
    vim
    wget
    killall
    eza
    git
    cmatrix
    lolcat
    fastfetch
    htop
    brave
    google-chrome
    libvirt
    lxqt.lxqt-policykit
    lm_sensors
    unzip
    unrar
    libnotify
    v4l-utils
    ydotool
    duf
    ncdu
    wl-clipboard
    pciutils
    ffmpeg
    socat
    cowsay
    ripgrep
    lshw
    bat
    pkg-config
    meson
    hyprpicker
    ninja
    brightnessctl
    virt-viewer
    swappy
    appimage-run
    networkmanagerapplet
    yad
    inxi
    playerctl
    nh
    nixfmt-rfc-style
    discord
    libvirt
    swww
    grim
    slurp
    pkgs.file-roller
    swaynotificationcenter
    imv
    mpv
    gimp
    pavucontrol
    tree
    spotify
    # neovide
    greetd.tuigreet
    affine
    go_1_22
    tesseract4
    cmake
    python313Full
    corepack_22  # This is for building
    gnumake42  # This is for building
    bitwarden-cli  # This is the bitwarden cli that is a password manager
    sox  # This is for audio editing
    age
    distrobox
    aider-chat
    yubioath-flutter
    nautilus
    wakatime-cli
    via
    python311Packages.playwright
    uair
    yq
    toipe
    insync
    insync-nautilus
    thunderbird
    jq
  ];

  fonts = {
    packages = with pkgs; [
      noto-fonts-emoji
      noto-fonts-cjk-sans
      font-awesome
      symbola
      material-icons
      google-fonts
    ];
  };

  environment.variables = {
    ZANEYOS_VERSION = "2.2";
    ZANEYOS = "true";
    EDITOR = "nvim";
    VISUAL = "nvim";
  };

  # Extra Portal Configuration
  xdg.portal = {
    enable = true;
    wlr.enable = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-gtk
      pkgs.xdg-desktop-portal
    ];
    configPackages = [
      pkgs.xdg-desktop-portal-gtk
      pkgs.xdg-desktop-portal-hyprland
      pkgs.xdg-desktop-portal
    ];
  };

  # Services to start
  services = {
    kanata = {
      enable = true;
      keyboards.default.configFile = ../../config/kanata/default.kbd;
    };
    pcscd.enable = true; # Enable pcscd for smartcards (yubikey)
    udev = {
      packages = [ pkgs.yubikey-personalization pkgs.android-udev-rules ];
      extraRules = ''
      ACTION=="remove",\
       ENV{ID_BUS}=="usb",\
       ENV{ID_MODEL_ID}=="0407",\
       ENV{ID_VENDOR_ID}=="1050",\
       ENV{ID_VENDOR}=="Yubico",\
       RUN+="${pkgs.systemd}/bin/loginctl hyprlock"
    '';
    };
    xserver = {
      enable = false;
      xkb = {
        layout = "us";
        variant = "";
      };
    };
    greetd = {
      enable = true;
      vt = 3;
      settings = {
        default_session = {
          # Wayland Desktop Manager is installed only for user ryan via home-manager!
          user = username;
          # .wayland-session is a script generated by home-manager, which links to the current wayland compositor(sway/hyprland or others).
          # with such a vendor-no-locking script, we can switch to another wayland compositor without modifying greetd's config here.
          # command = "$HOME/.wayland-session"; # start a wayland session directly without a login manager
          command = "${pkgs.greetd.tuigreet}/bin/tuigreet --time --cmd Hyprland"; # start Hyprland with a TUI login manager
        };
      };
    };
    smartd = {
      enable = false;
      autodetect = true;
    };
    libinput.enable = true;
    fstrim.enable = true;
    gvfs.enable = true;
    openssh.enable = true;
    flatpak.enable = false;
    printing = {
      enable = true;
      drivers = [
        # pkgs.hplipWithPlugin 
      ];
    };
    gnome.gnome-keyring.enable = true;
    avahi = {
      enable = true;
      nssmdns4 = true;
      openFirewall = true;
    };
    ipp-usb.enable = true;
    syncthing = {
      enable = false;
      user = "${username}";
      dataDir = "/home/${username}";
      configDir = "/home/${username}/.config/syncthing";
    };
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };
    rpcbind.enable = false;
    nfs.server.enable = false;
  };
  systemd.services.flatpak-repo = {
    path = [ pkgs.flatpak ];
    script = ''
      flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    '';
  };
  hardware.sane = {
    enable = true;
    extraBackends = [ pkgs.sane-airscan ];
    disabledDefaultBackends = [ "escl" ];
  };

  # Extra Logitech Support
  hardware.logitech.wireless.enable = true;
  hardware.logitech.wireless.enableGraphical = true;

  # Bluetooth Support
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;
  services.blueman.enable = true;

  # Enable sound with pipewire.
  hardware.pulseaudio.enable = false;

  # Security / Polkit
  security.rtkit.enable = true;
  security.polkit.enable = true;
  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
      if (
        subject.isInGroup("users")
          && (
            action.id == "org.freedesktop.login1.reboot" ||
            action.id == "org.freedesktop.login1.reboot-multiple-sessions" ||
            action.id == "org.freedesktop.login1.power-off" ||
            action.id == "org.freedesktop.login1.power-off-multiple-sessions"
          )
        )
      {
        return polkit.Result.YES;
      }
    })
  '';
  security.pam = {
    yubico = {
      enable = true;
      debug = true;
      mode = "challenge-response";
      id = [ "25751893" ];
    };
    services.swaylock = {
      text = ''
        auth include login
      '';
    };
  };

  # Optimization settings and garbage collection automation
  nix = {
    settings = {
      auto-optimise-store = true;
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      substituters = [ "https://hyprland.cachix.org" ];
      trusted-public-keys = [ "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc=" ];
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };
  };

  # Virtualization / Containers
  virtualisation.libvirtd.enable = true;
  virtualisation.podman = {
    enable = true;
    defaultNetwork.settings.dns_enabled = true;
  };

  virtualisation.docker = {
    enable = true;
    rootless = {
      enable = true;
      setSocketVariable = true;
    };
  };

  # OpenGL
  # hardware.opengl = {
  #   enable = true;
  #   driSupport = true;
  #   driSupport32Bit = true;
  # };

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.11"; # Did you read the comment?
}
