local home = os.getenv("HOME") or ""
local config_dir = (os.getenv("XDG_CONFIG_HOME") or (home .. "/.config")) .. "/hypr"
package.path = config_dir .. "/?.lua;" .. config_dir .. "/?/init.lua;" .. package.path

-- Load Wal colors
local function load_wal_colors()
    local colors = {}
    local f = io.open(home .. "/.cache/wal/colors-hyprland.conf", "r")
    if not f then return colors end
    for line in f:lines() do
        local var, val = line:match("%$([%w_]+)%s*=%s*(%S+)")
        if var and val then
            colors[var] = val
        end
    end
    f:close()
    return colors
end

local wal = load_wal_colors()
local active_border = wal.color7 or "rgba(c1c1c0ff)"
local inactive_border = wal.color1 or "rgba(977889ff)"

-- Environment variables
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")
hl.env("TERMINAL", "alacritty")
hl.env("FILEMANAGER", "thunar")
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")

-- Autostart
hl.on("hyprland.start", function()
    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
    hl.exec_cmd("systemctl --user start hyprpolkitagent")
    hl.exec_cmd("hyprctl setcursor Bibata-Modern-Classic 24")
    hl.exec_cmd("waybar & awww-daemon & swaync & hyprsunset & nm-applet --indicator")
    hl.exec_cmd("sleep 1 && waypaper --restore")
    hl.exec_cmd(config_dir .. "/scripts/battery-notify.sh")
    hl.exec_cmd("flatpak run com.discordapp.Discord")
    hl.exec_cmd("firefox")
end)

-- Look and Feel & Config
hl.config({
    debug = {
        disable_logs = false,
    },

    xwayland = {
        force_zero_scaling = true,
    },

    general = {
        gaps_in = 2,
        gaps_out = 4,
        border_size = 1,
        col = {
            active_border = active_border,
            inactive_border = inactive_border,
        },
        resize_on_border = false,
        allow_tearing = true,
        layout = "dwindle",
    },

    decoration = {
        rounding = 0,
        rounding_power = 10,
        active_opacity = 1.0,
        inactive_opacity = 0.9,
        shadow = {
            enabled = false,
        },
        blur = {
            enabled = true,
            size = 4,
            passes = 3,
            vibrancy = 0.1696,
        },
    },

    animations = {
        enabled = true,
    },

    master = {
        new_status = "master",
    },

    misc = {
        force_default_wallpaper = -1,
        disable_hyprland_logo = true,
        vrr = 2,
    },

    input = {
        kb_layout = "br",
        numlock_by_default = true,
        follow_mouse = 1,
        sensitivity = 0,
        accel_profile = "flat",
        force_no_accel = true,
    },
})

-- Animation curves and specs
hl.curve("linear", { type = "bezier", points = { {0, 0}, {1, 1} } })
hl.animation({ leaf = "windows",     enabled = false })
hl.animation({ leaf = "windowsIn",   enabled = false })
hl.animation({ leaf = "windowsOut",  enabled = false })
hl.animation({ leaf = "windowsMove", enabled = false })
hl.animation({ leaf = "workspaces",  enabled = false })
hl.animation({ leaf = "fade",        enabled = true, speed = 0.6, bezier = "linear" })
hl.animation({ leaf = "border",      enabled = false })
hl.animation({ leaf = "borderangle", enabled = false })

-- Workspace rules
hl.workspace_rule({ workspace = "w[tv1]", gaps_out = 0, gaps_in = 0 })
hl.workspace_rule({ workspace = "f[1]",   gaps_out = 0, gaps_in = 0 })

-- Window rules (Smart gaps)
hl.window_rule({
    match = { float = false, workspace = "w[tv1]" },
    border_size = 0,
    rounding = 0,
})
hl.window_rule({
    match = { float = false, workspace = "f[1]" },
    border_size = 0,
    rounding = 0,
})

-- Application Window Rules
hl.window_rule({
    match = { class = "^(spotify)$" },
    workspace = "special:spotify silent",
})
hl.window_rule({
    match = { class = "^(discord)$" },
    workspace = "1 silent",
})
hl.window_rule({
    match = { class = "^(com.gabm.satty)$" },
    workspace = "special:satty",
})
hl.window_rule({
    match = { class = "^(firefox)$" },
    workspace = "2 silent",
})
hl.window_rule({
    match = { class = "^(waypaper)$" },
    float = true,
})
hl.window_rule({
    match = { class = "REAPER", title = "^$" },
    no_focus = true,
})
hl.window_rule({
    match = { class = "firefox", title = "Picture-in-Picture" },
    float = true,
    pin = true,
    no_dim = true,
})
hl.window_rule({
    match = { class = "^(steam_app_\\d+|cs2)$" },
    stay_focused = true,
    float = true,
    render_unfocused = true,
    immediate = true,
    no_blur = true,
})
hl.window_rule({
    match = { class = "^(sys-monitor)$" },
    workspace = "special:monitor",
})
hl.window_rule({
    match = { class = ".*" },
    suppress_event = "maximize",
})
hl.window_rule({
    match = {
        class = "^$",
        title = "^$",
        xwayland = true,
        float = true,
        fullscreen = false,
        pin = false,
    },
    no_focus = true,
})

-- Layer rules
for _, ns in ipairs({ "waybar", "swaync-control-center", "swaync-notification-window" }) do
    hl.layer_rule({
        match = { namespace = ns },
        blur = true,
        xray = true,
        ignore_alpha = 0,
    })
end

-- Keybinds
require("keybinds")

-- Machine overrides (monitors, machine-specific rules)
pcall(require, "machine")
