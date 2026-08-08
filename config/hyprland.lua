local mainMod = "SUPER"
local terminal = "@TERMINAL@"
local browser = "@BROWSER@"

-- Environment
hl.env("NIXOS_OZONE_WL", "1")
hl.env("NIXPKGS_ALLOW_UNFREE", "1")
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")
hl.env("GDK_BACKEND", "wayland,x11")
hl.env("CLUTTER_BACKEND", "wayland")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")
hl.env("QT_AUTO_SCREEN_SCALE_FACTOR", "1")
hl.env("SDL_VIDEODRIVER", "x11")
hl.env("MOZ_ENABLE_WAYLAND", "1")

-- Monitor defaults
hl.monitor({
	output = "",
	mode = "preferred",
	position = "auto",
	scale = 1,
})

-- Core configuration
hl.config({
	general = {
		gaps_in = 6,
		gaps_out = 8,
		border_size = 2,
		layout = "dwindle",
		resize_on_border = true,
	},
	input = {
		kb_layout = "us",
		kb_options = "grp:alt_shift_toggle,caps:escape",
		follow_mouse = 1,
		sensitivity = 0,
		accel_profile = "flat",
		touchpad = {
			natural_scroll = false,
		},
	},
	misc = {
		initial_workspace_tracking = 0,
		mouse_move_enables_dpms = true,
		key_press_enables_dpms = false,
	},
	animations = {
		enabled = false,
	},
	decoration = {
		rounding = 10,
		blur = {
			enabled = true,
			size = 5,
			passes = 3,
			new_optimizations = true,
			ignore_opacity = false,
		},
	},
	dwindle = {
		preserve_split = true,
	},
})

-- Stylix updates these values at activation time through hyprctl. Keeping the
-- Lua config free of generated color literals avoids duplicating its target.

hl.curve("wind", { type = "bezier", points = { { 0.05, 0.9 }, { 0.1, 1.05 } } })
hl.curve("winIn", { type = "bezier", points = { { 0.1, 1.1 }, { 0.1, 1.1 } } })
hl.curve("winOut", { type = "bezier", points = { { 0.3, -0.3 }, { 0, 1 } } })
hl.curve("liner", { type = "bezier", points = { { 1, 1 }, { 1, 1 } } })

hl.animation({ leaf = "windows", enabled = true, speed = 6, bezier = "wind", style = "slide" })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 6, bezier = "winIn", style = "slide" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 5, bezier = "winOut", style = "slide" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 5, bezier = "wind", style = "slide" })
hl.animation({ leaf = "border", enabled = true, speed = 1, bezier = "liner" })
hl.animation({ leaf = "fade", enabled = true, speed = 10, bezier = "default" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 5, bezier = "wind" })

-- Three-finger workspace swipe (replacement for gestures.workspace_swipe).
hl.gesture({
	fingers = 3,
	direction = "horizontal",
	action = "workspace",
})

-- Window rules
hl.window_rule({
	name = "wofi",
	match = { class = "wofi" },
	border_size = 0,
	center = true,
})
hl.window_rule({ name = "steam", match = { class = "steam" }, center = true, stay_focused = true, min_size = { 1, 1 } })
hl.window_rule({
	name = "network-editor",
	match = { class = "(nm-connection-editor|.blueman-manager-wrapped)" },
	float = true,
})
hl.window_rule({ name = "media-viewers", match = { class = "(swayimg|vlc|Viewnior|pavucontrol)" }, float = true })
hl.window_rule({ name = "appearance-tools", match = { class = "(nwg-look|qt5ct|mpv)" }, float = true })
hl.window_rule({ name = "zoom", match = { class = "zoom" }, float = true })
hl.window_rule({ name = "brave-opacity", match = { class = "Brave" }, opacity = "0.9 0.7" })
hl.window_rule({ name = "thunar-opacity", match = { class = "thunar" }, opacity = "0.9 0.7" })
hl.window_rule({
	name = "picture-in-picture-lowercase",
	match = { title = "Picture in picture" },
	float = true,
	pin = true,
	move = { 1640, 1050 },
	size = { 900, 530 },
})
hl.window_rule({
	name = "picture-in-picture",
	match = { title = "Picture-in-Picture" },
	float = true,
	pin = true,
	move = { 1640, 1050 },
	size = { 900, 530 },
})
hl.window_rule({
	name = "google-meet",
	match = { title = "^Meet – ([a-z]{3}-[a-z]{4}-[a-z]{3}|Call with .*)$" },
	float = true,
	pin = true,
	move = { 840, -3 },
	size = { 830, 520 },
})
hl.window_rule({ name = "flameshot", match = { class = "flameshot" }, float = true })
hl.window_rule({
	name = "yad",
	match = { title = "YAD" },
	float = true,
	pin = true,
	move = { 1950, 60 },
	size = { 590, 200 },
})
hl.window_rule({
	name = "calendar-reminders",
	match = { initial_title = "Calendar Reminders" },
	float = true,
	pin = true,
	move = { 2200, 60 },
	size = { 320, 140 },
})
hl.window_rule({
	name = "edit-item",
	match = { initial_title = "Edit Item" },
	float = true,
	pin = true,
	move = { 650, 405 },
	size = { 1140, 820 },
})
hl.window_rule({ name = "zoom-video", match = { title = "zoom_linux_float_video_window" }, pin = true })
hl.window_rule({ name = "zoom-toolbar", match = { title = "as_toolbar" }, pin = true })
hl.window_rule({ name = "kitty-workspace", match = { class = "kitty" }, workspace = "1" })
hl.window_rule({ name = "obsidian-workspace", match = { class = "obsidian" }, workspace = "2 silent" })
hl.window_rule({ name = "cursor-workspace", match = { class = "(?i)Cursor" }, workspace = "3" })
hl.window_rule({ name = "firefox-workspace", match = { class = "firefox" }, workspace = "4" })
hl.window_rule({ name = "spotify-workspace", match = { class = "spotify" }, workspace = "6" })
hl.window_rule({ name = "slack-workspace", match = { class = "Slack" }, workspace = "7" })
hl.window_rule({ name = "chrome-workspace", match = { class = "google-chrome" }, workspace = "special silent" })

-- Autostart
hl.on("hyprland.start", function()
	hl.exec_cmd("dbus-update-activation-environment --systemd --all")
	hl.exec_cmd("systemctl --user import-environment QT_QPA_PLATFORMTHEME WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
	hl.exec_cmd("killall -q awww-daemon; sleep .5; awww-daemon")
	hl.exec_cmd("killall -q waybar; sleep .5; waybar")
	hl.exec_cmd("killall -q swaync; sleep .5; swaync")
	hl.exec_cmd("nm-applet --indicator")
	hl.exec_cmd("lxqt-policykit-agent")
	hl.exec_cmd("sleep 1.5; awww img /home/@USERNAME@/Pictures/Background/Cyborg/cyborg.jpg")
	hl.exec_cmd(terminal)
	hl.exec_cmd("obsidian")
	hl.exec_cmd("google-chrome")
	hl.exec_cmd("insync start")
end)

local function exec(keys, command, options)
	hl.bind(keys, hl.dsp.exec_cmd(command), options)
end

-- Application and utility bindings
exec(mainMod .. " + Return", terminal)
exec(mainMod .. " + SHIFT + Return", "rofi-launcher")
exec(mainMod .. " + SHIFT + W", "web-search")
exec(mainMod .. " + ALT + W", "wallsetter")
exec(mainMod .. " + SHIFT + N", "swaync-client -rs")
exec(mainMod .. " + W", browser)
exec(mainMod .. " + E", "emopicker9000")
exec(mainMod .. " + S", "flameshot gui")
exec(mainMod .. " + SHIFT + S", 'grim -g "$(slurp)" - | tesseract - - | wl-copy')
exec(mainMod .. " + D", "discord")
exec(mainMod .. " + O", "obs")
exec(mainMod .. " + SHIFT + O", "obsidian")
exec(mainMod .. " + C", "hyprpicker")
exec(mainMod .. " + G", "ai-spellcheck")
exec(mainMod .. " + SHIFT + G", "godot4")
exec(mainMod .. " + T", "nautilus")
exec(mainMod .. " + SHIFT + T", "ai-translate-en")
exec(mainMod .. " + R", "set-recording-window")
exec(mainMod .. " + SHIFT + R", "set-recording-presentation-window")
exec(mainMod .. " + M", "spotify")
exec(mainMod .. " + P", 'uair | yad --progress --no-buttons --css="* { font-size: 80px; }"')
exec(mainMod .. " + SHIFT + P", "uairctl toggle")
exec(mainMod .. " + N", "uairctl next")
exec(mainMod .. " + CTRL + W", "distrobox enter windsurf -e windsurf")

-- Window and compositor bindings
hl.bind(mainMod .. " + Q", hl.dsp.window.close())
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen({ action = "toggle" }))
hl.bind(mainMod .. " + SHIFT + F", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + SHIFT + C", hl.dsp.exit())
hl.bind(mainMod .. " + SHIFT + I", hl.dsp.layout("togglesplit"))

local directions = {
	left = "left",
	right = "right",
	up = "up",
	down = "down",
	h = "left",
	l = "right",
	k = "up",
	j = "down",
}

for key, direction in pairs(directions) do
	hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ direction = direction }))
	hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ direction = direction }))
end

for i = 1, 10 do
	local key = i % 10
	hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = i }))
	hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

hl.bind(mainMod .. " + CTRL + right", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + CTRL + left", hl.dsp.focus({ workspace = "e-1" }))
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))
hl.bind(mainMod .. " + SHIFT + SPACE", hl.dsp.window.move({ workspace = "special" }))
hl.bind(mainMod .. " + SPACE", hl.dsp.workspace.toggle_special(""))
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })
hl.bind("ALT + Tab", hl.dsp.window.cycle_next())
hl.bind("ALT + Tab", hl.dsp.window.bring_to_top())

-- Media keys
exec("XF86AudioRaiseVolume", "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+", { locked = true })
exec("XF86AudioLowerVolume", "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-", { locked = true })
exec("XF86AudioMute", "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle", { locked = true, repeating = true })
exec("XF86AudioPlay", "playerctl play-pause", { locked = true })
exec("XF86AudioPause", "playerctl play-pause", { locked = true })
exec("XF86AudioNext", "playerctl next", { locked = true })
exec("XF86AudioPrev", "playerctl previous", { locked = true })
exec("XF86MonBrightnessDown", "brightnessctl set 5%-", { locked = true })
exec("XF86MonBrightnessUp", "brightnessctl set +5%", { locked = true })
