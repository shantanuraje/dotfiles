-- AwesomeWM Integration for Enhanced Window Switcher
-- Add these keybindings to your rc.lua in the globalkeys section

-- Enhanced Alt+Tab that works with polybar window switcher
awful.key({ "Mod1" }, "Tab",
    function ()
        -- Use the enhanced window switcher for Alt+Tab
        awful.spawn.with_shell("~/.config/polybar/scripts/window-switcher.sh alt-tab")
    end,
    {description = "enhanced window switcher", group = "client"}
),

-- Alternative: Windows key + Tab for the same functionality
awful.key({ "Mod4" }, "Tab",
    function ()
        awful.spawn.with_shell("~/.config/polybar/scripts/window-switcher.sh alt-tab")
    end,
    {description = "enhanced window switcher (Win+Tab)", group = "client"}
),

-- Quick minimize/restore current window (Mod4 + m)
awful.key({ "Mod4" }, "m",
    function (c)
        c = client.focus
        if c then
            c.minimized = true
        end
    end,
    {description = "minimize current window", group = "client"}
),

-- Restore last minimized window (Mod4 + Shift + m)
awful.key({ "Mod4", "Shift" }, "m",
    function ()
        local tag = awful.screen.focused().selected_tag
        if tag then
            for _, c in ipairs(tag:clients()) do
                if c.minimized then
                    c.minimized = false
                    c:raise()
                    client.focus = c
                    break
                end
            end
        end
    end,
    {description = "restore last minimized window", group = "client"}
),

-- Show window menu via keyboard shortcut (Mod4 + w)
awful.key({ "Mod4" }, "w",
    function ()
        awful.spawn.with_shell("~/.config/polybar/scripts/window-switcher.sh click")
    end,
    {description = "show window menu", group = "client"}
),
