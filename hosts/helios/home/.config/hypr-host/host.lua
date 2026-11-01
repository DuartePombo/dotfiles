-- helios: monitors and GPU-specific settings, loaded by ~/.config/hypr/hyprland.lua.
-- hyprland-session (~/.local/bin) sets HELIOS_GPU_MODE before starting Hyprland:
--   mobile: Intel renders the laptop panel, the NVIDIA GPU stays asleep (apps can still use it via prime-run)
--   docked: an external monitor is on the NVIDIA GPU, so NVIDIA renders (DRAFT, not tested yet)

local mode = os.getenv("HELIOS_GPU_MODE") or "mobile"

-- Internal 1080p 144 Hz panel (on the Intel GPU)
hl.monitor({ output = "eDP-1", mode = "1920x1080@144", position = "0x0", scale = 1 })

if mode == "docked" then
    -- From the old config, where external monitors stuttered without the NVIDIA settings.
    -- The connector name is from the old setup; confirm it with the port mapping (it may differ under nvidia-drm).
    hl.monitor({ output = "HDMI-A-1", mode = "1920x1080@180", position = "1920x0", scale = 1 })

    hl.config({
        cursor = { no_hardware_cursors = true },
        opengl = { nvidia_anti_flicker = false },
    })
else
    -- Anything else that shows up while mobile: use it, to the right of the panel
    hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1 })
end
