-- Omakid owns the session surface. Load Quattro's Lua bootstrap/helpers without
-- starting the adult Omarchy shell, bindings, lock, menus, or first-run UI.
dofile((os.getenv("OMARCHY_PATH") or "/usr/share/omarchy") .. "/default/hypr/bootstrap.lua")
require("default.hypr.helpers")
require("default.hypr.envs")
require("default.hypr.input")
require("default.hypr.windows")

require("hypr.input")
require("hypr.looknfeel")
require("hypr.bindings")
require("hypr.autostart")
