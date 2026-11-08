-- Hyprland config (Lua, Hyprland 0.57+). Converted from the old hyprland.conf.
-- Wiki: https://wiki.hypr.land/configuring/ (source: github.com/hyprwm/hyprland-wiki)
-- API reference for editors: /usr/share/hypr/stubs/hl.meta.lua


-------------------------
---- MACHINE OVERRIDES ----
-------------------------

-- Monitors and GPU-specific settings live in a per-machine file, deployed from hosts/<hostname>/ in the dotfiles
-- repo. pcall keeps the rest of the config working if it's missing.
local hostOk, hostErr = pcall(require, os.getenv("HOME") .. "/.config/hypr-host/host")
if not hostOk then
    hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "auto" })
    print("hyprland.lua: no host config loaded: " .. tostring(hostErr))
end


---------------------
---- MY PROGRAMS ----
---------------------

local terminal    = "kitty"
local fileManager = "dolphin"
local menu        = "wofi --show drun"
local lock        = "pidof hyprlock || hyprlock"


-------------------
---- AUTOSTART ----
-------------------

hl.on("hyprland.start", function()
    hl.exec_cmd("swaybg -i ~/Pictures/wallpapers/astronaut.jpg -m fill")
    -- hl.exec_cmd("~/.config/hypr/scripts/random_wallpaper.sh")
    hl.exec_cmd("waybar")
    hl.exec_cmd("swaync")                                  -- notifications
    hl.exec_cmd("nm-applet --indicator")                   -- Wi-Fi in the tray
    hl.exec_cmd("blueman-applet")                          -- Bluetooth in the tray
    hl.exec_cmd("hypridle")                                -- lock and suspend when idle
    hl.exec_cmd("systemctl --user start hyprpolkitagent")  -- password dialogs for apps that need root
end)


-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------

hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")
-- Electron apps (VS Code, Discord) run natively on Wayland
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")
-- Lets Dolphin and other KDE apps find installed applications (archlinux-xdg-menu)
hl.env("XDG_MENU_PREFIX", "arch-")


-----------------------
----- PERMISSIONS -----
-----------------------

-- See https://wiki.hypr.land/configuring/core/advanced-configuration/permissions/
-- hl.config({ ecosystem = { enforce_permissions = true } })
-- hl.permission("/usr/(bin|local/bin)/grim", "screencopy", "allow")
-- hl.permission("/usr/(lib|libexec|lib64)/xdg-desktop-portal-hyprland", "screencopy", "allow")


-----------------------
---- LOOK AND FEEL ----
-----------------------

hl.config({
    general = {
        gaps_in  = 5,
        gaps_out = 10,

        border_size = 2,

        col = {
            active_border   = { colors = {"rgba(33ccffee)", "rgba(00ff99ee)"}, angle = 45 },
            inactive_border = "rgba(595959aa)",
        },

        -- Set to true to enable resizing windows by clicking and dragging on borders and gaps
        resize_on_border = false,

        -- See https://wiki.hypr.land/configuring/extra/tearing/
        allow_tearing = true,

        layout = "dwindle",
    },

    decoration = {
        rounding       = 10,
        rounding_power = 2,

        active_opacity   = 1.0,
        inactive_opacity = 1.0,

        shadow = {
            enabled      = true,
            range        = 4,
            render_power = 3,
            color        = 0xee1a1a1a,
        },

        blur = {
            enabled  = true,
            size     = 3,
            passes   = 1,
            vibrancy = 0.1696,
        },
    },

    animations = {
        enabled = true,
    },
})

hl.curve("easeOutQuint",   { type = "bezier", points = { {0.23, 1},    {0.32, 1}    } })
hl.curve("easeInOutCubic", { type = "bezier", points = { {0.65, 0.05}, {0.36, 1}    } })
hl.curve("linear",         { type = "bezier", points = { {0, 0},       {1, 1}       } })
hl.curve("almostLinear",   { type = "bezier", points = { {0.5, 0.5},   {0.75, 1}    } })
hl.curve("quick",          { type = "bezier", points = { {0.15, 0},    {0.1, 1}     } })

hl.animation({ leaf = "global",        enabled = true, speed = 10,   bezier = "default" })
hl.animation({ leaf = "border",        enabled = true, speed = 5.39, bezier = "easeOutQuint" })
hl.animation({ leaf = "windows",       enabled = true, speed = 4.79, bezier = "easeOutQuint" })
hl.animation({ leaf = "windowsIn",     enabled = true, speed = 4.1,  bezier = "easeOutQuint", style = "popin 87%" })
hl.animation({ leaf = "windowsOut",    enabled = true, speed = 1.49, bezier = "linear",       style = "popin 87%" })
hl.animation({ leaf = "fadeIn",        enabled = true, speed = 1.73, bezier = "almostLinear" })
hl.animation({ leaf = "fadeOut",       enabled = true, speed = 1.46, bezier = "almostLinear" })
hl.animation({ leaf = "fade",          enabled = true, speed = 3.03, bezier = "quick" })
hl.animation({ leaf = "layers",        enabled = true, speed = 3.81, bezier = "easeOutQuint" })
hl.animation({ leaf = "layersIn",      enabled = true, speed = 4,    bezier = "easeOutQuint", style = "fade" })
hl.animation({ leaf = "layersOut",     enabled = true, speed = 1.5,  bezier = "linear",       style = "fade" })
hl.animation({ leaf = "fadeLayersIn",  enabled = true, speed = 1.79, bezier = "almostLinear" })
hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 1.39, bezier = "almostLinear" })
hl.animation({ leaf = "workspaces",    enabled = true, speed = 1.94, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesIn",  enabled = true, speed = 1.21, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesOut", enabled = true, speed = 1.94, bezier = "almostLinear", style = "fade" })

-- "Smart gaps" / "No gaps when only": see https://wiki.hypr.land/configuring/core/rules/workspace-rules/

hl.config({
    dwindle = {
        preserve_split = true,
    },
    master = {
        new_status = "master",
    },
})


----------------
----  MISC  ----
----------------

hl.config({
    misc = {
        vrr                     = 1,
        force_default_wallpaper = 0,    -- no anime mascot wallpapers
        disable_hyprland_logo   = true,
    },
})


---------------
---- INPUT ----
---------------

hl.config({
    input = {
        kb_layout  = "us",
        kb_variant = "",
        kb_model   = "",
        kb_options = "",
        kb_rules   = "",

        follow_mouse = 1,

        sensitivity = 0, -- -1.0 - 1.0, 0 means no modification.

        touchpad = {
            natural_scroll = false,
        },
    },
})


---------------------
---- KEYBINDINGS ----
---------------------

local mainMod = "ALT" -- Alt is the main modifier

-- Office windows get Alt + letter themselves, like on Windows: Excel's key tips (Alt+H, Alt+M, Alt+F...), Alt+Enter
-- (new line in a cell), Alt+Q (search). Office = Microsoft Office through WinApps (window classes "Microsoft Excel",
-- "Microsoft Word"..., "Microsoft Windows" for the full desktop), OnlyOffice and LibreOffice.
-- Workspaces (Alt+number), lock, screenshots and recording stay the desktop's everywhere (dont_inhibit: even when
-- Remote Desktop grabs the keyboard).
-- Remote Desktop (WinApps) keeps an invisible 0x0 "RemoteApp Marker Window" with the app's class. It's never Office
-- for the keys, and it must never keep the keyboard focus: typing and Alt+D would silently go to Windows.
local function is_rdp_marker(window)
    if not window or not window.class or not window.class:find("^Microsoft ") then return false end
    local size = type(window.size) == "table" and window.size or {}
    return window.title == "RemoteApp Marker Window" or (size.x or 0) < 10 or (size.y or 0) < 10
end
local function is_office(window)
    if is_rdp_marker(window) then return false end
    local class = window and window.class and window.class:lower() or ""
    return class:find("^microsoft ") ~= nil or class:find("onlyoffice", 1, true) ~= nil
        or class:find("libreoffice", 1, true) ~= nil or class == "soffice"
end
-- When the marker gets the focus, give it back to the most recently used real window.
hl.on("window.active", function()
    if not is_rdp_marker(hl.get_active_window()) then return end
    local best
    for _, w in ipairs(hl.get_windows()) do
        if w.mapped and not w.hidden and not is_rdp_marker(w) and (w.focus_history_id or 0) > 0
            and (not best or w.focus_history_id < best.focus_history_id) then
            best = w
        end
    end
    if best then hl.dispatch(hl.dsp.focus({ window = best })) end
end)
local function desktop_or_office(key, dispatcher) -- Alt+key: the desktop's action, or the key itself in office windows
    return function()
        if is_office(hl.get_active_window()) then
            hl.dispatch(hl.dsp.send_shortcut({ mods = "ALT", key = key }))
        else
            hl.dispatch(dispatcher)
        end
    end
end
local always = { dont_inhibit = true }

hl.bind(mainMod .. " + RETURN", desktop_or_office("Return", hl.dsp.exec_cmd(terminal)))
hl.bind(mainMod .. " + Q",      desktop_or_office("Q", hl.dsp.window.close()))
hl.bind(mainMod .. " + M",      desktop_or_office("M", hl.dsp.exit()))
hl.bind(mainMod .. " + E",      desktop_or_office("E", hl.dsp.exec_cmd(fileManager)))
hl.bind(mainMod .. " + V",      desktop_or_office("V", hl.dsp.window.float({ action = "toggle" })))
hl.bind(mainMod .. " + D",      desktop_or_office("D", hl.dsp.exec_cmd(menu)))
hl.bind(mainMod .. " + P",      desktop_or_office("P", hl.dsp.window.pseudo()))          -- dwindle
hl.bind(mainMod .. " + T",      desktop_or_office("T", hl.dsp.layout("togglesplit")))    -- dwindle
-- Fullscreen like F11 on Windows, for any window: Alt+F covers the whole screen (bar too),
-- Alt+Shift+F maximizes (fills the screen, keeps the bar). Same key again to go back.
hl.bind(mainMod .. " + F",         desktop_or_office("F", hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" })))
hl.bind(mainMod .. " + SHIFT + F", hl.dsp.window.fullscreen({ mode = "maximized",  action = "toggle" }), always)
hl.bind(mainMod .. " + F9",     hl.dsp.exec_cmd("~/.config/hypr/scripts/random_wallpaper.sh"))
hl.bind(mainMod .. " + period", hl.dsp.exec_cmd(lock), always)

-- Move focus with mainMod + h/j/k/l
hl.bind(mainMod .. " + H", desktop_or_office("H", hl.dsp.focus({ direction = "left" })))
hl.bind(mainMod .. " + L", desktop_or_office("L", hl.dsp.focus({ direction = "right" })))
hl.bind(mainMod .. " + K", desktop_or_office("K", hl.dsp.focus({ direction = "up" })))
hl.bind(mainMod .. " + J", desktop_or_office("J", hl.dsp.focus({ direction = "down" })))

-- Switch workspaces with mainMod + [0-9]
-- Move active window to a workspace with mainMod + SHIFT + [0-9]
for i = 1, 10 do
    local key = i % 10 -- 10 maps to key 0
    hl.bind(mainMod .. " + " .. key,         hl.dsp.focus({ workspace = i }), always)
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }), always)
end

-- Special workspace (scratchpad)
hl.bind(mainMod .. " + S",         desktop_or_office("S", hl.dsp.workspace.toggle_special("magic")))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }), always)

-- Scroll through existing workspaces with mainMod + scroll
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

-- Move/resize windows with mainMod + LMB/RMB and dragging
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Laptop multimedia keys for volume and LCD brightness
hl.bind("XF86AudioRaiseVolume",  hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume",  hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),      { locked = true, repeating = true })
hl.bind("XF86AudioMute",         hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),     { locked = true, repeating = true })
hl.bind("XF86AudioMicMute",      hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),   { locked = true, repeating = true })
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"),                  { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"),                  { locked = true, repeating = true })

-- Media keys (playerctl)
hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),       { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),   { locked = true })

-- Screenshots like Windows' Snipping Tool (scripts/screenshot.sh): the screen freezes, drag an area or click a
-- window; it's copied and saved in ~/Pictures/Screenshots, and clicking the notification opens an editor.
local screenshot = "~/.config/hypr/scripts/screenshot.sh"
hl.bind("SUPER + SHIFT + S", hl.dsp.exec_cmd(screenshot), always)
hl.bind("Print",             hl.dsp.exec_cmd(screenshot), always)
hl.bind("SHIFT + Print",     hl.dsp.exec_cmd(screenshot .. " screen"), always)
-- Screen recording, like the Snipping Tool's (scripts/screenrecord.sh): press to pick an area and start,
-- press again to stop (waybar shows ● REC meanwhile). Saved as MP4 in ~/Videos/Recordings.
hl.bind("SUPER + SHIFT + R", hl.dsp.exec_cmd("~/.config/hypr/scripts/screenrecord.sh"), always)


--------------------------------
---- WINDOWS AND WORKSPACES ----
--------------------------------

-- See https://wiki.hypr.land/configuring/core/rules/

hl.window_rule({
    -- The screenshot editor (satty) opens floating and centred, like a dialog
    name   = "screenshot-editor",
    match  = { class = "com.gabm.satty" },
    float  = true,
    center = true,
})
