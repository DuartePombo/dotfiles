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
    -- The front monitor is scaled 1.333333 (like Windows' 133%): at scale 1 its text was too small from the desk chair,
    -- 1.25 still a bit small. It stays 2560x1440 and sharp, but lays out like a 1920x1080 screen: the same height as
    -- the other two, so all three sit in one row (y 0), the right monitor after it (x 1920+1920 = 3840). The mouse
    -- crosses between screens along the whole edge.
    hl.monitor({ output = "eDP-1", mode = "1920x1080@144", position = "0x0", scale = 1 })
    hl.monitor({ output = "desc:" .. front, mode = "2560x1440@240", position = "1920x0", scale = 1.333333 })
    hl.monitor({ output = "desc:" .. right, mode = "1920x1080@165", position = "3840x0", scale = 1 })
    -- Any other monitor: preferred mode, placed automatically
    hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1 })

    -- The bars (~/.local/bin/bar): the front monitor is an OLED (burn-in), so its bar hides itself (Super+B)
    hl.env("BAR_FRONT_MONITOR", front)

    -- Which screen each workspace lives on (apps' homes are in hyprland.lua): the main task on the front monitor
    -- (projects, both Chromes), side things (Slack, work notes, WhatsApp) on the laptop screen, extras on the right
    -- monitor: a terminal next to the projects, and the Windows desktop (Excel's bright ribbon stays off the OLED).
    -- Mobile: everything on the laptop screen.
    -- Each screen starts on an empty workspace, 8 in front, 5 on the right and 9 on the laptop; the apps opened at
    -- login wait in their homes (hyprland.lua, autostart).
    local homes = {
        { monitor = "desc:" .. front, default = "8", workspaces = { "1", "2", "6", "8" } },
        { monitor = "desc:" .. right, default = "5", workspaces = { "5", "10" } },
        { monitor = "eDP-1",          default = "9", workspaces = { "3", "4", "7", "9" } },
    }
    for _, screen in ipairs(homes) do
        for _, ws in ipairs(screen.workspaces) do
            hl.workspace_rule({ workspace = ws, monitor = screen.monitor, default = (ws == screen.default) })
        end
    end

    -- Chrome started by a program without a window name of its own (an RPA robot through Selenium: class
    -- "google-chrome"; your own Chromes are chrome-work / chrome-personal): on the right monitor, in whatever
    -- workspace shows there, to watch it next to the code. Laptop alone: it opens where you are.
    hl.window_rule({ name = "plain-chrome-right", match = { class = "^google-chrome$" }, monitor = "desc:" .. right })

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
