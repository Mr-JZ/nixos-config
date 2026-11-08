{ username, ... }:
let
  # Runs as the desktop user so the Calibre GUI and SSH tooling share the library.
  home = "/home/${username}";
in
{
  services.calibre-server = {
    enable = true;
    user = username;
    group = "users";
    host = "127.0.0.1"; # Reached only through the Cloudflare Tunnel.
    port = 8080;
    libraries = [ "${home}/Calibre Library" ];
    auth = {
      enable = true;
      mode = "basic"; # KOReader OPDS supports basic auth; TLS is terminated by Cloudflare.
      userDb = "${home}/.config/calibre/server-users.sqlite";
    };
  };
}
