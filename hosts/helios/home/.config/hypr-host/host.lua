-- helios: monitors and GPU-specific settings, loaded by ~/.config/hypr/hyprland.lua.
-- hyprland-session (~/.local/bin) sets HELIOS_GPU_MODE before starting Hyprland:
--   mobile: Intel renders the laptop panel; Hyprland doesn't use the NVIDIA GPU (apps can, via prime-run)
--   docked: an external monitor is on the NVIDIA GPU, so NVIDIA renders

local mode = os.getenv("HELIOS_GPU_MODE") or "mobile"

if mode == "docked" then
    -- The desk, left to right: laptop | front | right. Monitors are matched by model ("desc:" + the start of the
    -- description `hyprctl monitors` shows), so each keeps its place and settings on whichever port it's plugged into:
    -- the HDMI port (NVIDIA HDMI-A-3) or the mini-DisplayPort port (NVIDIA DP-4).
    local front = "AOC Q27G41ZDF"             -- 27" QD-OLED, 2560x1440: 240 Hz over DisplayPort, 144 over HDMI
    local right = "Acer Technologies VG252Q"  -- 24.5" 1920x1080, 165 Hz (60 through a mini-DP→HDMI adapter)
    -- Modes: each monitor's best. When a connection can't carry it, Hyprland falls back to the same resolution at the
    -- fastest refresh it can (tested: the right monitor through the adapter → 1920x1080@60; the front one over HDMI →
    -- 2560x1440@144). Not "highrr": that picks the fastest refresh at ANY resolution (1024x768@75 through the adapter).
    -- Heights: the front monitor is 1440 pixels tall, the others 1080: the laptop sits lower, so its bottom edge lines
    -- up with the front one's (y 360); the right monitor is centred on it (y 180). The mouse crosses between screens
    -- where their edges overlap.
    hl.monitor({ output = "eDP-1", mode = "1920x1080@144", position = "0x360", scale = 1 })
    hl.monitor({ output = "desc:" .. front, mode = "2560x1440@240", position = "1920x0", scale = 1 })
    hl.monitor({ output = "desc:" .. right, mode = "1920x1080@165", position = "4480x180", scale = 1 })
    -- Any other monitor: preferred mode, placed automatically
    hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1 })

    -- The bars (~/.local/bin/bar): the front monitor is an OLED (burn-in), so its bar hides itself (Super+B)
    hl.env("BAR_FRONT_MONITOR", front)

    -- Which screen each workspace lives on (apps' homes are in hyprland.lua): the main task on the front monitor,
    -- side things (Slack, work notes, WhatsApp) on the laptop screen. Mobile: everything on the laptop screen.
    -- Each screen starts on an empty workspace, 8 in front and 9 on the laptop; the apps opened at login wait in
    -- their homes (hyprland.lua, autostart). The right monitor has no workspaces of its own yet: it shows the next
    -- free number (11).
    for _, ws in ipairs({ "1", "2", "5", "6", "8", "10" }) do
        hl.workspace_rule({ workspace = ws, monitor = "desc:" .. front, default = (ws == "8") })
    end
    for _, ws in ipairs({ "3", "4", "7", "9" }) do
        hl.workspace_rule({ workspace = ws, monitor = "eDP-1", default = (ws == "9") })
    end

    -- From the old config, where external monitors stuttered without the NVIDIA settings.
    hl.config({
        cursor = { no_hardware_cursors = true },
        opengl = { nvidia_anti_flicker = false },
    })
else
    -- Internal 1080p 144 Hz panel (on the Intel GPU)
    hl.monitor({ output = "eDP-1", mode = "1920x1080@144", position = "0x0", scale = 1 })
    -- Anything else that shows up while mobile: use it, to the right of the panel
    hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1 })
    -- Start on an empty workspace, as when docked (1 holds Work projects from login on)
    hl.workspace_rule({ workspace = "9", monitor = "eDP-1", default = true })
end
