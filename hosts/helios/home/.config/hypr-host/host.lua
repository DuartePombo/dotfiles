-- helios: monitors and GPU-specific settings, loaded by ~/.config/hypr/hyprland.lua.
-- hyprland-session (~/.local/bin) sets HELIOS_GPU_MODE before starting Hyprland:
--   mobile: Intel renders the laptop panel; Hyprland doesn't use the NVIDIA GPU (apps can, via prime-run)
--   docked: an external monitor is on the NVIDIA GPU, so NVIDIA renders

local mode = os.getenv("HELIOS_GPU_MODE") or "mobile"

-- Internal 1080p 144 Hz panel (on the Intel GPU)
hl.monitor({ output = "eDP-1", mode = "1920x1080@144", position = "0x0", scale = 1 })

if mode == "docked" then
    -- The laptop's HDMI port is HDMI-A-3 on the NVIDIA GPU (checked 2026-11-01; the old config's HDMI-A-1 was
    -- the name under the previous driver). highrr: the highest refresh rate, e.g. 165 Hz on the VG252Q.
    hl.monitor({ output = "HDMI-A-3", mode = "highrr", position = "1920x0", scale = 1 })
    -- Any other monitor: preferred mode, placed automatically
    hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1 })

    -- Which screen each workspace lives on (apps' homes are in hyprland.lua): the main task on the front monitor,
    -- side things (Slack, work notes, WhatsApp) on the laptop screen. Mobile: everything on the laptop screen.
    for _, ws in ipairs({ "1", "2", "5", "6", "8" }) do
        hl.workspace_rule({ workspace = ws, monitor = "HDMI-A-3", default = (ws == "1") })
    end
    for _, ws in ipairs({ "3", "4", "7", "9", "10" }) do
        hl.workspace_rule({ workspace = ws, monitor = "eDP-1", default = (ws == "3") })
    end

    -- From the old config, where external monitors stuttered without the NVIDIA settings.
    hl.config({
        cursor = { no_hardware_cursors = true },
        opengl = { nvidia_anti_flicker = false },
    })
else
    -- Anything else that shows up while mobile: use it, to the right of the panel
    hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1 })
end
