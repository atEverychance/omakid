-- Omarchy defaults are never loaded by hyprland.lua. These are the complete
-- Omakid bindings: a lone Super release goes home, plus locked hardware keys.
o.bind("SUPER_L", "Omakid home", "omakid-home", { release = true, locked = true })
o.bind("SUPER_R", "Omakid home", "omakid-home", { release = true, locked = true })

o.bind("XF86AudioRaiseVolume", "Volume up", "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+ -l 0.85", { locked = true, repeating = true })
o.bind("XF86AudioLowerVolume", "Volume down", "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-", { locked = true, repeating = true })
o.bind("XF86AudioMute", "Mute", "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle", { locked = true })
o.bind("XF86MonBrightnessUp", "Brightness up", "brightnessctl set 10%+", { locked = true, repeating = true })
o.bind("XF86MonBrightnessDown", "Brightness down", "brightnessctl set 10%-", { locked = true, repeating = true })
