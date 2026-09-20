{
  lib,
  pkgs,
  username,
  ...
}:
let
  # Set this to the USB Ethernet interface reported by `ip -br link` once
  # connected, e.g. "enx001122334455". Wi-Fi cannot be a Linux bridge port.
  ethernetInterface = null;
  # Add the Thread radio's actual USB IDs after connecting it (`lsusb`).
  # Example shape: [ { vendor = "0x1234"; product = "0x5678"; } ]
  usbDevices = [ ];
  bootstrap = ethernetInterface == null;
  disk = "/var/lib/libvirt/images/home-assistant/haos.qcow2";
  mac = "52:54:00:48:41:01";

  # Enforce the lid state even at the text login screen, without a desktop.
  lidBacklight = pkgs.writeShellApplication {
    name = "server-lid-backlight";
    runtimeInputs = [ pkgs.gnugrep ];
    text = ''
      power=0
      if grep -q closed /proc/acpi/button/lid/*/state; then power=4; fi
      for backlight in /sys/class/backlight/*/bl_power; do
        [[ -w "$backlight" ]] && echo "$power" > "$backlight"
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
      <vcpu placement='static'>2</vcpu>
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
    wantedBy = [ "multi-user.target" ];
    after = [ "systemd-backlight@backlight:amdgpu_bl1.service" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = lib.getExe lidBacklight;
    };
  };
  systemd.services.server-power-profile = {
    description = "Select the power-saving profile for the home server";
    wantedBy = [ "multi-user.target" ];
    wants = [ "power-profiles-daemon.service" ];
    after = [ "power-profiles-daemon.service" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.power-profiles-daemon}/bin/powerprofilesctl set power-saver";
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
      ipv4.method = "auto";
      ipv6.method = "auto";
    };
    ha-ethernet = {
      connection = {
        id = "ha-ethernet";
        type = "ethernet";
        interface-name = ethernetInterface;
        controller = "ha-br0";
        port-type = "bridge";
        autoconnect = true;
        autoconnect-priority = 100;
      };
    };
  };
  systemd.services.home-assistant-vm = {
    description = "Define and start Home Assistant OS";
    wantedBy = [ "multi-user.target" ];
    requires = [ "libvirtd.service" ] ++ lib.optional bootstrap "haos-bootstrap-network.service";
    after = [
      "libvirtd.service"
      "NetworkManager-wait-online.service"
    ]
    ++ lib.optional bootstrap "haos-bootstrap-network.service";
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
