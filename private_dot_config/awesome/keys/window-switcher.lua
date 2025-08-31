-- Window Switcher Keybindings for Rofi Integration
-- Add this to your rc.lua or include it in your keybindings

local awful = require("awful")
local gears = require("gears")

-- Define window switcher keybindings
local window_switcher_keys = gears.table.join(
    -- Alt+Tab: Show all windows
    awful.key({ "Mod1" }, "Tab",
        function()
            awful.spawn.with_shell("~/.config/rofi/bin/window-switcher-advanced.sh all")
        end,
        {description = "show all windows", group = "window switcher"}
    ),
    
    -- Super+Tab: Show windows from current workspace
    awful.key({ "Mod4" }, "Tab",
        function()
            awful.spawn.with_shell("~/.config/rofi/bin/window-switcher-advanced.sh current")
        end,
        {description = "show current workspace windows", group = "window switcher"}
    ),
    
    -- Super+Shift+Tab: Show minimized windows
    awful.key({ "Mod4", "Shift" }, "Tab",
        function()
            awful.spawn.with_shell("~/.config/rofi/bin/window-switcher-advanced.sh minimized")
        end,
        {description = "show minimized windows", group = "window switcher"}
    ),
    
    -- Super+w: Quick window switcher (simple version)
    awful.key({ "Mod4" }, "w",
        function()
            awful.spawn.with_shell("~/.config/rofi/bin/window-switcher.sh")
        end,
        {description = "quick window switcher", group = "window switcher"}
    )
)

return window_switcher_keys