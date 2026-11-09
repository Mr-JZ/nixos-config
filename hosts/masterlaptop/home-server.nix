{
  lib,
  pkgs,
  username,
  ...
}:
let
  # null selects the bootstrap network; any other value enables the bridge.
  # The profile itself matches usbEthernetMac, so the name need not stay current.
  ethernetInterface = "enp3s0f3u1u3c2";
  # Add the Thread radio's actual USB IDs after connecting it (`lsusb`).
  # Example shape: [ { vendor = "0x1234"; product = "0x5678"; } ]
  usbDevices = [ { vendor = "0x303a"; product = "0x831a"; } ];
  bootstrap = ethernetInterface == null;
  disk = "/var/lib/libvirt/images/home-assistant/haos.qcow2";
  mac = "52:54:00:48:41:01";
  usbEthernetMac = "f8:e4:3b:55:4c:6a";
  # The VM must not start before its bridge exists, or it comes up detached.
  haBridgeDevice = "sys-subsystem-net-devices-ha\\x2dbr0.device";

  # Enforce the lid state even at the text login screen, without a desktop.
  lidBacklight = pkgs.writeShellApplication {
    name = "server-lid-backlight";
    runtimeInputs = [ pkgs.gnugrep ];
    text = ''
      power=0
      if grep -q closed /proc/acpi/button/lid/*/state; then power=4; fi
      for backlight in /sys/class/backlight/*/bl_power; do
        if [[ -w "$backlight" ]]; then echo "$power" > "$backlight"; fi
      done
    '';
  };
  display = pkgs.writeShellApplication {
    name = "server-display";
    runtimeInputs = [
      pkgs.hyprland
      pkgs.gnugrep
    ];
    text = ''
      # An idle-resume event must never light the closed laptop's panel.
      state=on
      if [[ "''${1:-auto}" == off ]] || grep -q closed /proc/acpi/button/lid/*/state; then
        state=off
      fi
      hyprctl dispatch "hl.dsp.dpms({action='$state', monitor='eDP-1'})"
    '';
  };
  networkXML = pkgs.writeText "haos-bootstrap.xml" ''
    <network>
      <name>haos-bootstrap</name>
      <forward mode='nat'/>
      <bridge name='virbr-ha' stp='on' delay='0'/>
      <ip address='192.168.124.1' netmask='255.255.255.0'>
        <dhcp>
          <range start='192.168.124.2' end='192.168.124.254'/>
          <host mac='${mac}' name='homeassistant' ip='192.168.124.2'/>
        </dhcp>
      </ip>
    </network>
  '';
  domainXML = pkgs.writeText "home-assistant.xml" ''
    <domain type='kvm'>
      <name>home-assistant</name>
      <uuid>caa5e5ae-e967-4bad-82e3-ce4c6d8d786e</uuid>
      <memory unit='MiB'>4096</memory>
      <vcpu placement='static'>4</vcpu>
      <os firmware='efi'>
        <type arch='x86_64' machine='q35'>hvm</type>
        <firmware><feature enabled='no' name='secure-boot'/></firmware>
        <boot dev='hd'/>
      </os>
      <features><acpi/><apic/></features>
      <cpu mode='host-passthrough'/>
      <clock offset='utc'/>
      <on_poweroff>destroy</on_poweroff>
      <on_reboot>restart</on_reboot>
      <on_crash>restart</on_crash>
      <devices>
        <emulator>/run/libvirt/nix-emulators/qemu-system-x86_64</emulator>
        <disk type='file' device='disk'>
          <driver name='qemu' type='qcow2' cache='none' discard='unmap'/>
          <source file='${disk}'/>
          <target dev='vda' bus='virtio'/>
        </disk>
        <controller type='usb' model='qemu-xhci'/>
        ${lib.concatMapStringsSep "\n" (device: ''
          <hostdev mode='subsystem' type='usb' managed='yes'>
            <source startupPolicy='optional'>
              <vendor id='${device.vendor}'/><product id='${device.product}'/>
            </source>
          </hostdev>
        '') usbDevices}
        <interface type='${if bootstrap then "network" else "bridge"}'>
          <mac address='${mac}'/>
          <source ${if bootstrap then "network='haos-bootstrap'" else "bridge='ha-br0'"}/>
          <model type='virtio'/>
        </interface>
        <serial type='pty'><target port='0'/></serial>
        <console type='pty'><target type='serial' port='0'/></console>
        <channel type='unix'>
          <target type='virtio' name='org.qemu.guest_agent.0'/>
        </channel>
        <rng model='virtio'><backend model='random'>/dev/urandom</backend></rng>
        <memballoon model='none'/>
      </devices>
    </domain>
  '';
  installer = pkgs.writeShellApplication {
    name = "haos-install";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.curl
      pkgs.xz
      pkgs.qemu_kvm
      pkgs.systemd
      pkgs.util-linux
    ];
    text = ''
      if (( EUID != 0 )); then echo "Run with sudo or run0." >&2; exit 1; fi
      install -d -m 0750 -o qemu-libvirtd -g qemu-libvirtd "$(dirname '${disk}')"
      exec 9>/run/haos-install.lock
      flock -n 9
      if [[ -e '${disk}' ]]; then
        echo "Existing Home Assistant disk preserved."
      else
        image="''${1:-/var/cache/haos/haos_ova-18.3.qcow2.xz}"
        if [[ ! -f "$image" ]]; then
          if (( $# > 0 )); then echo "Image not found: $image" >&2; exit 1; fi
          install -d -m 0700 /var/cache/haos
          curl --fail --location --retry 3 --output "$image.part" \
            https://github.com/home-assistant/operating-system/releases/download/18.3/haos_ova-18.3.qcow2.xz
          mv "$image.part" "$image"
        fi
        printf '%s  %s\n' fae6a728768cc10aff60d4820bfcd40d64cd77fab82c8bd92af13b3d9d414090 "$image" | sha256sum --check
        partial=$(mktemp '${disk}.XXXXXX')
        trap 'rm -f "$partial"' EXIT
        xz --decompress --stdout "$image" | dd of="$partial" bs=4M conv=sparse status=none
        qemu-img check -f qcow2 "$partial"
        qemu-img resize -f qcow2 "$partial" 64G
        chown qemu-libvirtd:qemu-libvirtd "$partial"
        chmod 0600 "$partial"
        mv "$partial" '${disk}'
        trap - EXIT
      fi
      systemctl restart home-assistant-vm.service
      echo 'Home Assistant is starting. First boot can take several minutes.'
    '';
  };
in
{
  services.logind.settings.Login = {
    HandleLidSwitch = "ignore";
    HandleLidSwitchExternalPower = "ignore";
    HandleLidSwitchDocked = "ignore";
    HandleSuspendKey = "ignore";
    IdleAction = "ignore";
  };
  systemd.sleep.settings.Sleep = {
    AllowSuspend = false;
    AllowHibernation = false;
    AllowHybridSleep = false;
    AllowSuspendThenHibernate = false;
  };
  services.acpid = {
    enable = true;
    lidEventCommands = lib.getExe lidBacklight;
  };
  systemd.services.server-lid-backlight = {
    description = "Apply laptop lid state to the internal backlight";
    # The panel's backlight can register after multi-user.target is reached.
    wantedBy = [
      "multi-user.target"
      "systemd-backlight@backlight:amdgpu_bl1.service"
    ];
    after = [ "systemd-backlight@backlight:amdgpu_bl1.service" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = lib.getExe lidBacklight;
    };
  };
  systemd.services.server-power-profile = {
    description = "Select the performance profile for the home server";
    wantedBy = [ "multi-user.target" ];
    wants = [ "power-profiles-daemon.service" ];
    after = [ "power-profiles-daemon.service" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.power-profiles-daemon}/bin/powerprofilesctl set performance";
    };
  };

  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      package = pkgs.qemu_kvm;
      runAsRoot = false;
    };
    onShutdown = "shutdown";
    onBoot = "ignore";
  };
  users.users.${username}.extraGroups = [ "libvirtd" ];
  environment.systemPackages = [
    installer
    display
    pkgs.sccache
    pkgs.mold
    pkgs.virt-manager
  ];
  networking.enableIPv6 = true;

  # Onboarding over existing Wi-Fi until a wired bridge is available. NAT
  # does NOT provide the LAN IPv6/multicast required for Matter and Thread.
  systemd.services.haos-bootstrap-network = lib.mkIf bootstrap {
    description = "Home Assistant temporary onboarding network";
    wantedBy = [ "multi-user.target" ];
    requires = [ "libvirtd.service" ];
    after = [ "libvirtd.service" ];
    path = [
      pkgs.libvirt
      pkgs.gnugrep
    ];
    script = ''
      virsh -c qemu:///system net-define ${networkXML}
      virsh -c qemu:///system net-autostart haos-bootstrap
      if ! virsh -c qemu:///system net-list --name | grep -qx haos-bootstrap; then
        virsh -c qemu:///system net-start haos-bootstrap
      fi
    '';
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
  };
  networking.firewall.interfaces.virbr-ha = lib.mkIf bootstrap {
    allowedUDPPorts = [
      53
      67
    ];
    allowedTCPPorts = [ 53 ];
  };
  systemd.sockets.home-assistant-web = lib.mkIf bootstrap {
    description = "Home Assistant onboarding web access";
    wantedBy = [ "sockets.target" ];
    listenStreams = [ "0.0.0.0:8123" ];
  };
  systemd.services.home-assistant-web = lib.mkIf bootstrap {
    serviceConfig = {
      # Current HAOS serves its frontend on port 80; port 8123 redirects there.
      ExecStart = "${pkgs.systemd}/lib/systemd/systemd-socket-proxyd 192.168.124.2:80";
      DynamicUser = true;
      NoNewPrivileges = true;
      ProtectSystem = "strict";
      ProtectHome = true;
      PrivateTmp = true;
    };
  };
  networking.firewall.interfaces.wlp1s0.allowedTCPPorts = lib.mkIf bootstrap [ 8123 ];

  networking.networkmanager.ensureProfiles.profiles = lib.mkIf (!bootstrap) {
    ha-bridge = {
      connection = {
        id = "ha-bridge";
        type = "bridge";
        interface-name = "ha-br0";
        autoconnect = true;
      };
      bridge.stp = false;
      bridge.mac-address = "F8:E4:3B:55:4C:6A";
      ipv4.method = "auto";
      ipv6.method = "auto";
    };
    ha-ethernet = {
      connection = {
        id = "ha-ethernet";
        type = "ethernet";
        controller = "ha-br0";
        port-type = "bridge";
        autoconnect = true;
        autoconnect-priority = 100;
      };
      # Matched by MAC: the USB adapter's interface name changes with its bus path.
      ethernet.mac-address = lib.toUpper usbEthernetMac;
    };
  };

  # The adapter ignores frames for the VM's MAC until its RX filter is
  # reprogrammed after joining the bridge.
  networking.networkmanager.dispatcherScripts = lib.mkIf (!bootstrap) [
    {
      type = "basic";
      source = pkgs.writeShellScript "ha-usb-rx-filter" ''
        [ "$2" = up ] || exit 0
        [ "$(${pkgs.coreutils}/bin/cat "/sys/class/net/$1/address")" = "${usbEthernetMac}" ] || exit 0
        # ha-br0 shares this MAC, so only act on the real bridge port.
        [ -e "/sys/class/net/$1/brport" ] || exit 0
        ${pkgs.iproute2}/bin/ip link set "$1" multicast off
        ${pkgs.iproute2}/bin/ip link set "$1" multicast on
      '';
    }
  ];

  # Tuned for zram-backed swap: compressed RAM is far cheaper than dropping cache.
  boot.kernel.sysctl = {
    "vm.swappiness" = 150;
    "vm.page-cluster" = 0;
  };

  fileSystems."/".options = [ "noatime" ];

  # A full root disk pauses the Home Assistant VM, so keep headroom automatically.
  nix.settings.min-free = 10 * 1024 * 1024 * 1024;
  nix.settings.max-free = 30 * 1024 * 1024 * 1024;

  # External SSD holding all media. nofail: a missing disk must not block boot.
  fileSystems."/mnt/media" = {
    device = "/dev/disk/by-label/media";
    fsType = "ext4";
    options = [ "nofail" "noatime" "x-systemd.device-timeout=10s" ];
  };

  # NFSv4 share for the Home Assistant apps, reachable only from the VM.
  services.nfs.server = lib.mkIf (!bootstrap) {
    enable = lib.mkForce true;
    exports = "/mnt/media 192.168.178.56(rw,async,no_subtree_check,no_root_squash)";
  };
  # Required by the NFS module; stays firewalled, only 2049 is opened below.
  services.rpcbind.enable = lib.mkIf (!bootstrap) (lib.mkForce true);
  networking.firewall.extraCommands = lib.mkIf (!bootstrap) ''
    iptables -I nixos-fw 1 -i ha-br0 -s 192.168.178.56 -p tcp --dport 2049 -j nixos-fw-accept
  '';

  # A full disk pauses the VM; resume it once there is room again.
  systemd.services.home-assistant-vm-resume = {
    description = "Resume Home Assistant after a disk-full pause";
    path = [ pkgs.libvirt pkgs.coreutils pkgs.gnugrep ];
    script = ''
      virsh -c qemu:///system domstate home-assistant --reason | grep -q 'paused (I/O error)' || exit 0
      free=$(df -BG --output=avail '${disk}' | tail -1 | tr -dc 0-9)
      if [ "$free" -lt 20 ]; then
        echo "Home Assistant paused by I/O error, only ''${free}G free: not resuming" >&2
        exit 1
      fi
      virsh -c qemu:///system resume home-assistant
    '';
    serviceConfig.Type = "oneshot";
  };
  systemd.timers.home-assistant-vm-resume = {
    wantedBy = [ "timers.target" ];
    timerConfig.OnUnitActiveSec = "2min";
    timerConfig.OnBootSec = "5min";
  };

  systemd.services.home-assistant-vm = {
    description = "Define and start Home Assistant OS";
    wantedBy = [ "multi-user.target" ];
    requires = [
      "libvirtd.service"
    ]
    ++ lib.optional bootstrap "haos-bootstrap-network.service"
    ++ lib.optional (!bootstrap) haBridgeDevice;
    after = [
      "libvirtd.service"
      "NetworkManager-wait-online.service"
    ]
    ++ lib.optional bootstrap "haos-bootstrap-network.service"
    ++ lib.optional (!bootstrap) haBridgeDevice;
    wants = [ "network-online.target" ];
    unitConfig.ConditionPathExists = disk;
    path = [
      pkgs.libvirt
      pkgs.gnugrep
    ];
    script = ''
      virsh -c qemu:///system define ${domainXML}
      # This service owns boot ordering; libvirtd must not race the bridge.
      virsh -c qemu:///system autostart home-assistant --disable
      if ! virsh -c qemu:///system list --name | grep -qx home-assistant; then
        virsh -c qemu:///system start home-assistant
      fi
    '';
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
  };
}
