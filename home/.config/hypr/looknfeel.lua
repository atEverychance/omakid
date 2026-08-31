hl.config({
  general = {
    gaps_in = 0,
    gaps_out = 0,
    border_size = 0,
  },
  decoration = {
    rounding = 0,
    shadow = { enabled = false },
    blur = { enabled = false },
  },
  animations = { enabled = false },
  misc = {
    disable_hyprland_logo = true,
    disable_splash_rendering = true,
    focus_on_activate = true,
  },
})

-- Applications own the complete display. The layer-shell home is separately
-- hidden before launch, so this does not leave the launcher above an app.
o.window(".*", { fullscreen = true, border_size = 0 })
