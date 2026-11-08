{ ... }:
let
  tunnelId = "e5053300-9fd5-409a-9dad-62f12aed7611";
  origin = "http://192.168.178.56:80";
in
{
  services.cloudflared = {
    enable = true;
    tunnels.${tunnelId} = {
      # Runtime secret: never copy the JSON or account certificate into Git.
      credentialsFile = "/var/lib/cloudflared/home-assistant.json";
      ingress."home.zisenis.digital" = origin;
      ingress."music.zisenis.digital" = "http://192.168.178.56:8095";
      ingress."book.zisenis.digital" = "http://127.0.0.1:8080";
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
