{ pkgs, username, ... }:

let
  inherit (import ./variables.nix) gitUsername;
in
{
  users.users = {
    "${username}" = {
      homeMode = "0700";
      isNormalUser = true;
      description = "${gitUsername}";
      extraGroups = [
        "networkmanager"
        "wheel"
        "scanner"
        "uinput"
        "input"
        "adbusers"
      ];
      shell = pkgs.bash;
      ignoreShellProgramCheck = true;
      packages = with pkgs; [ ];
    };
    # "newuser" = {
    #   homeMode = "0700";
    #   isNormalUser = true;
    #   description = "New user account";
    #   extraGroups = [ "networkmanager" "wheel" "libvirtd" ];
    #   shell = pkgs.bash;
    #   ignoreShellProgramCheck = true;
    #   packages = with pkgs; [];
    # };
  };
}
