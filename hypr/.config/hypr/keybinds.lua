local home = os.getenv("HOME") or ""
local terminal = "alacritty"
local fileManager = "thunar"
local menu = "rofi -show drun"
local mainMod = "SUPER"

-- Core application and window management
hl.bind(mainMod .. " + Q", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + C", hl.dsp.window.close())
hl.bind(mainMod .. " + M", hl.dsp.exit())
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + SHIFT + V", function()
    hl.dispatch(hl.dsp.window.float({ action = "toggle" }))
    hl.dispatch(hl.dsp.window.pin())
end)
hl.bind(mainMod .. " + R", hl.dsp.exec_cmd(menu))
hl.bind(mainMod .. " + G", hl.dsp.exec_cmd("firefox"))
hl.bind(mainMod .. " + L", hl.dsp.exec_cmd("hyprlock"))
hl.bind(mainMod .. " + N", hl.dsp.exec_cmd("swaync-client -t"))
hl.bind(mainMod .. " + H", hl.dsp.exec_cmd(home .. "/.config/waybar/restart_waybar.sh"))
hl.bind(mainMod .. " + U", hl.dsp.exec_cmd("systemctl suspend"), { locked = true })
hl.bind("Print", hl.dsp.exec_cmd("grim - | satty --filename -"))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.exec_cmd('grim -g "$(slurp)" - | satty --filename -'))
hl.bind(mainMod .. " + T", hl.dsp.exec_cmd("waypaper"))
hl.bind(mainMod .. " + comma", hl.dsp.exec_cmd("rofi -modi emoji -show emoji"))

-- Trap Alt+Tab (anti coworker curiosity)
local noAltTab = home .. "/.config/hypr/scripts/no-alttab.sh"
hl.bind("ALT + Tab", hl.dsp.exec_cmd(noAltTab))
hl.bind("ALT + SHIFT + Tab", hl.dsp.exec_cmd(noAltTab))

-- Move focus with mainMod + arrow keys
hl.bind(mainMod .. " + left",  hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up",    hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down",  hl.dsp.focus({ direction = "down" }))

-- Special workspaces state & multi-scratchpad (Super + S)
local last_special = "s1"

local function is_multi_special(sp)
    if not sp then return false end
    return sp.name:match("^special:s%d+$") ~= nil or sp.name == "special:magic"
end

-- Super + S: Toggle special workspace (remembers last visited slot)
hl.bind(mainMod .. " + S", function()
    local sp = hl.get_active_special_workspace()
    if is_multi_special(sp) then
        local name = sp.name:gsub("^special:", "")
        last_special = name
        hl.dispatch(hl.dsp.workspace.toggle_special(name))
    elseif sp then
        local name = sp.name:gsub("^special:", "")
        hl.dispatch(hl.dsp.workspace.toggle_special(name))
        hl.dispatch(hl.dsp.workspace.toggle_special(last_special))
    else
        hl.dispatch(hl.dsp.workspace.toggle_special(last_special))
    end
end)

-- Workspaces & Dynamic Special Workspace Slots (Super + [0-9])
for i = 1, 10 do
    local key = i % 10

    -- Super + [0-9]: Switch workspace (or switch special slot if already in special workspace)
    hl.bind(mainMod .. " + " .. key, function()
        local sp = hl.get_active_special_workspace()
        if is_multi_special(sp) then
            local target = "s" .. i
            last_special = target
            hl.dispatch(hl.dsp.focus({ workspace = "special:" .. target }))
        else
            hl.dispatch(hl.dsp.focus({ workspace = i }))
        end
    end)

    -- Super + SHIFT + [0-9]: Move window to workspace (or between special slots if in special)
    hl.bind(mainMod .. " + SHIFT + " .. key, function()
        local sp = hl.get_active_special_workspace()
        if is_multi_special(sp) then
            hl.dispatch(hl.dsp.window.move({ workspace = "special:s" .. i }))
        else
            hl.dispatch(hl.dsp.window.move({ workspace = i }))
        end
    end)

    -- Super + CTRL + SHIFT + [0-9]: Send window directly to special slot special:s[i]
    hl.bind(mainMod .. " + CTRL + SHIFT + " .. key, hl.dsp.window.move({ workspace = "special:s" .. i }))

    -- Super + CTRL + [0-9]: Send window from special workspace back to regular workspace [i]
    hl.bind(mainMod .. " + CTRL + " .. key, hl.dsp.window.move({ workspace = i }))
end

-- Dedicated & extra scratchpads
hl.bind(mainMod .. " + CTRL + SHIFT + S", function()
    hl.dispatch(hl.dsp.window.move({ workspace = "special:" .. last_special }))
end)
hl.bind(mainMod .. " + P", hl.dsp.workspace.toggle_special("spotify"))
hl.bind(mainMod .. " + I", hl.dsp.workspace.toggle_special("satty"))
hl.bind(mainMod .. " + CTRL + SHIFT + P", hl.dsp.window.move({ workspace = "special:spotify" }))
hl.bind(mainMod .. " + CTRL + SHIFT + I", hl.dsp.window.move({ workspace = "special:satty" }))

-- Scroll through existing workspaces with mainMod + scroll
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

-- Move/resize windows with mainMod + LMB/RMB and dragging
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Multimedia keys (audio & brightness)
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),      { locked = true, repeating = true })
hl.bind("XF86AudioMute",        hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),     { locked = true, repeating = true })
hl.bind("XF86AudioMicMute",     hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),   { locked = true, repeating = true })
hl.bind("XF86MonBrightnessUp",  hl.dsp.exec_cmd("brightnessctl s 10%+"),                           { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown",hl.dsp.exec_cmd("brightnessctl s 10%-"),                           { locked = true, repeating = true })

-- Player controls
hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),       { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),   { locked = true })
