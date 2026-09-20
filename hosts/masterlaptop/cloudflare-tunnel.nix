{ ... }:
let
  tunnelId = "e5053300-9fd5-409a-9dad-62f12aed7611";
  # Update this address when moving the VM from onboarding NAT to Ethernet.
  origin = "http://192.168.124.2:80";
in
{
  services.cloudflared = {
    enable = true;
    tunnels.${tunnelId} = {
      # Runtime secret: never copy the JSON or account certificate into Git.
      credentialsFile = "/var/lib/cloudflared/home-assistant.json";
      ingress."home.zisenis.digital" = origin;
      default = "http_status:404";
    };
  };

  systemd.services."cloudflared-tunnel-${tunnelId}" = {
    wants = [ "home-assistant-vm.service" ];
    after = [ "home-assistant-vm.service" ];
    serviceConfig = {
      NoNewPrivileges = true;
      PrivateTmp = true;
      ProtectHome = true;
      ProtectSystem = "strict";
    };
  };
}
