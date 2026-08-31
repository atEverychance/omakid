hl.config({
  input = {
    sensitivity = -0.3,
    accel_profile = "flat",
    touchpad = {
      natural_scroll = false,
      clickfinger_behavior = false,
      scroll_factor = 0.4,
      disable_while_typing = false,
      tap_to_click = true,
      tap_and_drag = true,
      drag_lock = 1,
      middle_button_emulation = false,
    },
  },
  misc = {
    middle_click_paste = false,
    key_press_enables_dpms = true,
    mouse_move_enables_dpms = true,
  },
  cursor = {
    no_hardware_cursors = false,
  },
})
