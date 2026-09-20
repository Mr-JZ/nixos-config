# Home Assistant on masterlaptop

This branch keeps NixOS and the optional Hyprland desktop, and runs Home Assistant
OS in KVM: 2 vCPUs, 4 GiB RAM, and a sparse 64 GiB disk. Home Assistant starts at
boot without a desktop login and shuts down gracefully with the host.

The lid no longer suspends the laptop. ACPI controls the internal backlight even
at the login screen; Hyprland also follows the lid and blanks the display after
five minutes idle. Opening the lid restores the display. Automatic sleep is
disabled and the power profile is `power-saver`. Chrome, Obsidian, Insync and the
Handy background service no longer start automatically. Log out of the desktop
when it is not needed for lower idle power.

## Installation

Build and activate this branch with `fr`, then run:

```sh
sudo haos-install
```

The installer verifies the SHA-256 of the official HAOS 18.3 image. It never
overwrites an existing VM disk. Updates after installation belong in Home
Assistant's Settings; changing the installer version does not update a running VM.
The disk lives at `/var/lib/libvirt/images/home-assistant/haos.qcow2`.

While `ethernetInterface = null` in `hosts/masterlaptop/home-server.nix`, a
temporary NAT network provides internet access through the laptop's current
connection. Open `http://<laptop-Wi-Fi-IP>:8123` (currently
`http://192.168.178.25:8123`), or `http://192.168.124.2` on the laptop itself.
First boot downloads Home Assistant and can take several minutes. Create your
owner account in the browser; no account or password is stored in this repository.

**This temporary NAT network is for onboarding. It is not ready for Matter,
Thread, or general multicast discovery.**

## Finish wired networking

1. Connect a USB Ethernet adapter to the laptop and router. Find its name with
   `ip -br link` (usually `enx...`).
2. Set `ethernetInterface` in `hosts/masterlaptop/home-server.nix` to that name.
3. Gracefully stop the VM: `sudo virsh -c qemu:///system shutdown home-assistant`.
   Wait until `sudo virsh -c qemu:///system domstate home-assistant` says `shut off`.
4. Run `fr`. NetworkManager creates `ha-br0` and connects that Ethernet interface
   to it. The VM service defines and starts the VM on this bridge. No disk is
   replaced. Keep Wi-Fi connected during this transition.
5. Find the VM's new LAN address using your router's device list or
   `sudo virsh -c qemu:///system domifaddr home-assistant --source agent`.
   Open `http://<VM-IP>` or `http://homeassistant.local`.
6. Reserve the VM's DHCP address in your router. Its MAC is `52:54:00:48:41:01`.
7. Once wired access works, disable Wi-Fi with `nmcli radio wifi off` to save power.
   Retire the unused onboarding network with
   `sudo virsh -c qemu:///system net-autostart haos-bootstrap --disable` and
   `sudo virsh -c qemu:///system net-destroy haos-bootstrap`.

Keep IPv6 and multicast enabled on the local network, and put the phone, VM and
Thread border router on the same LAN during setup. No internet port forwarding
is needed. The host's temporary port-8123 proxy is removed in wired mode; clients
connect directly to the VM.

## Matter and Thread

Matter-over-Wi-Fi devices need no Thread radio. Matter-over-Thread needs a Thread
border router. The Aeotec Z-Stick 10 Pro is officially a Zigbee/Z-Wave adapter;
choose a Home Assistant Connect ZBT-2 configured for Thread for this setup.

After connecting a ZBT-2:

1. Read its actual vendor/product IDs with `lsusb` and put them in `usbDevices`
   in `home-server.nix`. This declaratively passes the radio through to HAOS.
   Shut down the VM, rebuild, and let the VM service start it again.
2. Follow Home Assistant's detected-device setup to use it for Thread and install
   the OpenThread Border Router app. A ZBT-2 serves either Zigbee or Thread;
   use another radio if you want both networks.
3. Add the Matter integration under Settings → Devices & services, which installs
   the Matter Server app. Use the Companion phone app to sync Thread credentials
   and scan devices' Matter QR codes.

The VM definition is managed by NixOS. Put permanent USB changes in the Nix file;
edits made only in virt-manager may be replaced at the next rebuild.

## Maintenance and checks

```sh
systemctl status home-assistant-vm server-power-profile acpid
sudo virsh -c qemu:///system list --all
sudo virsh -c qemu:///system console home-assistant  # exit: Ctrl+]
powerprofilesctl get
hyprctl configerrors
```

Keep Home Assistant backups on another device using its backup settings. Git
tracks the host configuration, not Home Assistant accounts, devices, history or
the VM disk. A NixOS rollback also does not roll back that disk. Keep ventilation
clear with the lid closed. Measure wall power after the battery is charged;
the VM's allocated CPU count is not a measurement of electricity consumption.

References:
- https://www.home-assistant.io/installation/linux/
- https://www.home-assistant.io/integrations/matter/
- https://www.home-assistant.io/integrations/thread/
- https://www.home-assistant.io/connect/zbt-2/
- https://aeotec.com/products/aeotec-z-stick-10-pro/
