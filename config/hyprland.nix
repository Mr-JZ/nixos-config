{
  lib,
  username,
  host,
  ...
}:

let
  inherit (import ../hosts/${host}/variables.nix)
    browser
    terminal
    extraHyprlandLua
    ;

  luaConfig =
    builtins.replaceStrings [ "@USERNAME@" "@TERMINAL@" "@BROWSER@" ] [ username terminal browser ]
      (builtins.readFile ./hyprland.lua);
in
{
  wayland.windowManager.hyprland = {
    enable = true;
    configType = "lua";
    xwayland.enable = true;
    systemd.enable = true;

    # Host-specific monitor configuration may append native Hyprland Lua.
    extraConfig = lib.concatStrings [
      luaConfig
      extraHyprlandLua
    ];
  };
}
