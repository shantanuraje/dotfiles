-- AwesomeWM Configuration
-- Replicating Hyprland setup for user shantanu

-- Standard awesome library
local gears = require("gears")
local awful = require("awful")
require("awful.autofocus")
local wibox = require("wibox")
local beautiful = require("beautiful")
-- DON'T load naughty to prevent D-Bus notification service conflict with dunst
-- local naughty = require("naughty")
local lain = require("lain")
local freedesktop = require("freedesktop")
local hotkeys_popup = require("awful.hotkeys_popup")
require("awful.hotkeys_popup.keys")

-- Error handling (using print instead of naughty to avoid D-Bus conflict)
if awesome.startup_errors then
    print("AwesomeWM startup errors: " .. awesome.startup_errors)
end

do
    local in_error = false
    awesome.connect_signal("debug::error", function (err)
        if in_error then return end
        in_error = true
        print("AwesomeWM error: " .. tostring(err))
        in_error = false
    end)
end

-- Variable definitions
local chosen_theme = "catppuccin-macchiato"
local modkey = "Mod4"  -- Super key (matches Hyprland $mainMod)
local altkey = "Mod1"
local terminal = "kitty"  -- Matches Hyprland $terminal
local editor = os.getenv("EDITOR") or "nvim"
local gui_editor = "nvim"
local browser = "google-chrome-stable"
local filemanager = "nautilus"
local scrlocker = "i3lock"

-- Theme
local theme_path = string.format("%s/.config/awesome/themes/%s/theme.lua", os.getenv("HOME"), chosen_theme)
beautiful.init(theme_path)

-- Table of layouts to cover with awful.layout.inc, order matters.
awful.layout.layouts = {
    awful.layout.suit.tile,           -- matches Hyprland dwindle
    awful.layout.suit.tile.left,
    awful.layout.suit.tile.bottom,
    awful.layout.suit.tile.top,
    awful.layout.suit.fair,
    awful.layout.suit.fair.horizontal,
    awful.layout.suit.spiral,
    awful.layout.suit.spiral.dwindle,
    awful.layout.suit.max,
    awful.layout.suit.max.fullscreen,
    awful.layout.suit.magnifier,
    awful.layout.suit.corner.nw,
    awful.layout.suit.floating,
}

-- Autostart applications (matches Hyprland exec-once)
local function autostart()
    -- System services that don't need workspace assignment
    local system_cmds = {
        "picom --config ~/.config/picom/picom.conf",  -- compositor
        "bash ~/.config/awesome/wallpaper-rotate.sh",  -- wallpaper rotation
        "dunst",  -- notifications
        "pkill x11vnc; x11vnc -display :0 -rfbport 5901 -forever -loop -noxdamage -repeat -rfbauth ~/.vnc/passwd",  -- VNC server
    }
    
    -- Launch system services first (always run with singleton checks)
    for _, cmd in ipairs(system_cmds) do
        awful.spawn.with_shell(string.format("pgrep -u $USER -fx '%s' > /dev/null || (%s)", cmd, cmd))
    end

    -- Start Polybar using proper launch script (always run, script handles singleton)
    gears.timer.start_new(2, function()
        awful.spawn.with_shell("~/.config/polybar/launch.sh")
        return false -- run only once
    end)
    
    -- Start intelligent notification services (always run with singleton checks)
    local notification_services = {
        "~/.config/polybar/scripts/power-notifications.sh daemon",
        "~/.config/polybar/scripts/system-notifications.sh daemon",
    }
    
    for _, service in ipairs(notification_services) do
        gears.timer.start_new(6, function()
            awful.spawn.with_shell(service)
            return false -- run only once
        end)
    end
end

-- Applications to launch only on startup (not on reload)
local function startup_applications()
    -- Application definitions with process patterns for detection
    local apps = {
        {cmd = "google-chrome-stable", pattern = "chrome"},
        {cmd = "obsidian", pattern = "obsidian"},
        {cmd = "claude-desktop", pattern = "claude-desktop"},
        {cmd = "kitty --name dev1", pattern = "kitty.*dev1"},
        {cmd = "kitty --name dev2", pattern = "kitty.*dev2"},
        {cmd = "code", pattern = "code.*--no-sandbox"},  -- VSCode specific pattern
        {cmd = "insync start", pattern = "insync"},
        {cmd = "discord", pattern = "discord"},
        {cmd = "synergy", pattern = "synergy"},
    }
    
    -- Launch applications using safe launcher
    local safe_launcher = "~/.config/awesome/scripts/safe-launch.sh"
    for _, app in ipairs(apps) do
        local launch_cmd = string.format("%s '%s' '%s'", safe_launcher, app.pattern, app.cmd)
        awful.spawn.with_shell(launch_cmd)
        -- Small delay between launches to prevent startup conflicts
        gears.timer.start_new(0.5, function() return false end)
    end
end

-- Wallpaper
local function set_wallpaper(s)
    -- Start wallpaper rotation script if not already running
    awful.spawn.with_shell("pgrep -f wallpaper-rotate.sh || ~/.config/awesome/wallpaper-rotate.sh")
end

-- Re-set wallpaper when a screen's geometry changes
screen.connect_signal("property::geometry", set_wallpaper)

-- Widgets
local markup = lain.util.markup
local separators = lain.util.separators

-- Textclock (matches waybar clock format)
local clockicon = wibox.widget.imagebox(beautiful.widget_clock)
local clock = awful.widget.watch(
    "date +'%I:%M:%S %p'", 1,
    function(widget, stdout)
        widget:set_markup(markup.font(beautiful.font, markup(beautiful.fg_normal, stdout)))
    end
)

-- Calendar
local cal = lain.widget.cal({
    attach_to = { clock },
    notification_preset = {
        font = beautiful.font,
        fg   = beautiful.fg_normal,
        bg   = beautiful.bg_normal
    }
})

-- Battery widget (clean text-only with icon)
local bat = lain.widget.bat({
    settings = function()
        if bat_now and bat_now.status and bat_now.status ~= "N/A" and bat_now.perc then
            local bat_icon = "󰂄"
            if bat_now.status == "Discharging" then
                local perc = tonumber(bat_now.perc) or 0
                if perc > 90 then bat_icon = "󰁹"
                elseif perc > 80 then bat_icon = "󰂂"
                elseif perc > 70 then bat_icon = "󰂁"
                elseif perc > 60 then bat_icon = "󰂀"
                elseif perc > 50 then bat_icon = "󰁿"
                elseif perc > 40 then bat_icon = "󰁾"
                elseif perc > 30 then bat_icon = "󰁽"
                elseif perc > 20 then bat_icon = "󰁼"
                elseif perc > 10 then bat_icon = "󰁻"
                else bat_icon = "󰂎" end
            end
            widget:set_markup(markup.font(beautiful.font, bat_icon .. " " .. bat_now.perc .. "%"))
        else
            widget:set_markup(markup.font(beautiful.font, "󰂑 N/A"))
        end
    end
})

-- Volume widget (clean text-only with icon)
local volume = lain.widget.pulse({
    settings = function()
        local vol_level = tonumber(volume_now.left) or 0
        local vol_icon = ""
        if volume_now.muted == "yes" then
            vol_icon = "󰝟"
        elseif vol_level == 0 then
            vol_icon = "󰕿"
        elseif vol_level <= 50 then
            vol_icon = "󰖀"
        else
            vol_icon = "󰕾"
        end
        widget:set_markup(markup.font(beautiful.font, vol_icon .. " " .. vol_level .. "%"))
    end
})

-- Temperature widget (using sensors instead of weather API)
local temp = lain.widget.temp({
    settings = function()
        local temperature = temp_now and temp_now .. "°C" or "N/A"
        widget:set_markup(markup.font(beautiful.font, " " .. temperature))
    end
})

-- CPU widget (clean text-only)
local cpu = lain.widget.cpu({
    settings = function()
        local cpu_usage = cpu_now and cpu_now.usage or "N/A"
        widget:set_markup(markup.font(beautiful.font, "󰻠 " .. cpu_usage .. "%"))
    end
})

-- Memory widget (clean text-only)
local mem = lain.widget.mem({
    settings = function()
        local mem_used = mem_now and mem_now.used or "N/A"
        widget:set_markup(markup.font(beautiful.font, " " .. mem_used .. "M"))
    end
})

-- Network widget (clean text-only)
local net = lain.widget.net({
    settings = function()
        local received = net_now and net_now.received or "N/A"
        local sent = net_now and net_now.sent or "N/A"
        widget:set_markup(markup.font(beautiful.font, " " .. received .. " ⇡" .. sent))
    end
})

-- Create awesome menu
local awesome_menu = {
   { "hotkeys", function() hotkeys_popup.show_help(nil, awful.screen.focused()) end },
   { "manual", terminal .. " -e man awesome" },
   { "edit config", gui_editor .. " " .. awesome.conffile },
   { "restart", awesome.restart },
   { "quit", function() awesome.quit() end },
}

-- Create menu
local mymainmenu = freedesktop.menu.build({
    before = {
        { "Awesome", beautiful.awesome_icon, awesome_menu },
    },
    after = {
        { "Open terminal", terminal },
    }
})

-- Launcher (with smaller icon)
local mylauncher = awful.widget.launcher({ 
    image = beautiful.awesome_icon,
    menu = mymainmenu 
})
-- Resize the launcher icon
mylauncher.resize = true
mylauncher.forced_height = 16
mylauncher.forced_width = 16

-- Create a wibox for each screen and add it
local taglist_buttons = gears.table.join(
                    awful.button({ }, 1, function(t) t:view_only() end),
                    awful.button({ modkey }, 1, function(t)
                                              if client.focus then
                                                  client.focus:move_to_tag(t)
                                              end
                                          end),
                    awful.button({ }, 3, awful.tag.viewtoggle),
                    awful.button({ modkey }, 3, function(t)
                                              if client.focus then
                                                  client.focus:toggle_tag(t)
                                              end
                                          end),
                    awful.button({ }, 4, function(t) awful.tag.viewnext(t.screen) end),
                    awful.button({ }, 5, function(t) awful.tag.viewprev(t.screen) end)
                )

awful.screen.connect_for_each_screen(function(s)
    -- Wallpaper
    set_wallpaper(s)

    -- Each screen has its own tag table (matches Hyprland workspaces 1-10)
    awful.tag({ "1", "2", "3", "4", "5", "6", "7", "8", "9", "10" }, s, awful.layout.layouts[1])

    -- Create a promptbox for each screen
    s.mypromptbox = awful.widget.prompt()
    
    -- Create an imagebox widget which will contain an icon indicating which layout we're using.
    s.mylayoutbox = awful.widget.layoutbox(s)
    s.mylayoutbox:buttons(gears.table.join(
                           awful.button({ }, 1, function () awful.layout.inc( 1) end),
                           awful.button({ }, 3, function () awful.layout.inc(-1) end),
                           awful.button({ }, 4, function () awful.layout.inc( 1) end),
                           awful.button({ }, 5, function () awful.layout.inc(-1) end)))
    -- Resize the layout box icon
    s.mylayoutbox.forced_height = 16
    s.mylayoutbox.forced_width = 16
    
    -- Create a taglist widget
    s.mytaglist = awful.widget.taglist {
        screen  = s,
        filter  = awful.widget.taglist.filter.noempty,
        buttons = taglist_buttons,
        layout   = {
            spacing = 6,
            layout  = wibox.layout.fixed.horizontal
        },
        widget_template = {
            {
                {
                    {
                        id     = 'text_role',
                        widget = wibox.widget.textbox,
                        align  = 'center',
                    },
                    layout = wibox.layout.fixed.horizontal,
                },
                left  = 4,
                right = 4,
                top   = 4,
                bottom = 4,
                widget = wibox.container.margin
            },
            id     = 'background_role',
            widget = wibox.container.background,
            create_callback = function(self, c3, index, objects)
                local text_widget = self:get_children_by_id('text_role')[1]
                local tag = c3
                
                if tag.selected then
                    -- Active workspace - white circle
                    text_widget:set_markup('<span color="#cad3f5">●</span>')
                elseif #tag:clients() > 0 then
                    -- Has windows - light gray circle
                    text_widget:set_markup('<span color="#a5adcb">●</span>')
                else
                    -- Empty workspace - dark gray circle
                    text_widget:set_markup('<span color="#6e738d">●</span>')
                end
            end,
            update_callback = function(self, c3, index, objects)
                local text_widget = self:get_children_by_id('text_role')[1]
                local tag = c3
                
                if tag.selected then
                    -- Active workspace - white circle
                    text_widget:set_markup('<span color="#cad3f5">●</span>')
                elseif #tag:clients() > 0 then
                    -- Has windows - light gray circle
                    text_widget:set_markup('<span color="#a5adcb">●</span>')
                else
                    -- Empty workspace - dark gray circle
                    text_widget:set_markup('<span color="#6e738d">●</span>')
                end
            end,
        },
    }

    -- Create a tasklist widget
    s.mytasklist = awful.widget.tasklist {
        screen  = s,
        filter  = awful.widget.tasklist.filter.currenttags,
        buttons = awful.button({ }, 1, function (c)
                                          if c == client.focus then
                                              c.minimized = true
                                          else
                                              -- Unminimize if it's minimized
                                              c.minimized = false
                                              c:emit_signal(
                                                  "request::activate",
                                                  "tasklist",
                                                  {raise = true}
                                              )
                                          end
                                      end),
        widget_template = {
            {
                {
                    {
                        {
                            id     = 'icon_role',
                            widget = wibox.widget.imagebox,
                        },
                        margins = 4, -- Add padding around the icon
                        widget  = wibox.container.margin,
                    },
                    {
                        id     = 'text_role',
                        widget = wibox.widget.textbox,
                    },
                    layout = wibox.layout.fixed.horizontal,
                },
                left  = 10,
                right = 10,
                widget = wibox.container.margin
            },
            id     = 'background_role',
            widget = wibox.container.background,
        },
    }

    -- Adds an empty wibar under Polybar so that the workarea changes
    awful.wibar {
        position = 'top',
        height   = 23,
    }

    -- Create the wibox (status bar) - DISABLED FOR POLYBAR
    --[[
    s.mywibox = awful.wibar({ 
        position = "top", 
        screen = s, 
        height = 32, 
        bg = beautiful.bg_normal,
        fg = beautiful.fg_normal 
    })

    -- Add widgets to the wibox
    s.mywibox:setup {
        layout = wibox.layout.align.horizontal,
        { -- Left widgets
            layout = wibox.layout.fixed.horizontal,
            {
                widget = wibox.container.margin,
                margins = 8,
                {
                    layout = wibox.layout.fixed.horizontal,
                    spacing = 10,
                    mylauncher,
                    s.mytaglist,
                    s.mypromptbox,
                }
            }
        },
        s.mytasklist, -- Middle widget
        { -- Right widgets
            layout = wibox.layout.fixed.horizontal,
            {
                widget = wibox.container.margin,
                margins = 8,
                {
                    layout = wibox.layout.fixed.horizontal,
                    spacing = 12,
                    cpu.widget,
                    mem.widget,
                    temp.widget,
                    net.widget,
                    volume.widget,
                    bat.widget,
                    clock,
                    s.mylayoutbox,
                }
            }
        },
    }
    --]]
end)

-- Start system services (always run with singleton checks)
autostart()

-- Always test notifications on AwesomeWM load/reload (after delay for dunst)
gears.timer.start_new(4, function()
    if awesome.startup then
        -- Startup notification is handled above
        return false
    else
        -- Reload notification
        awful.spawn.with_shell("notify-send 'AwesomeWM Reloaded' 'Configuration reloaded - Notifications working!' -u low")
    end
    return false -- run only once
end)

-- Launch applications only on actual startup, not on reload
if awesome.startup then
    gears.timer.start_new(3, function()
        startup_applications()
        return false -- run only once
    end)
    
    -- Test notifications on startup (after a delay to ensure dunst is ready)
    gears.timer.start_new(5, function()
        awful.spawn.with_shell("notify-send 'AwesomeWM Started' 'System loaded successfully - Notifications working!' -u normal")
        return false -- run only once
    end)
end

-- Mouse bindings
root.buttons(gears.table.join(
    awful.button({ }, 3, function () mymainmenu:toggle() end),
    awful.button({ }, 4, awful.tag.viewnext),
    awful.button({ }, 5, awful.tag.viewprev)
))

-- Key bindings (matching Hyprland keybinds exactly)
globalkeys = gears.table.join(
    -- System controls
    awful.key({ modkey,           }, "s",      hotkeys_popup.show_help,
              {description="show help", group="awesome"}),
    awful.key({ modkey,           }, "Left",   awful.tag.viewprev,
              {description = "view previous", group = "tag"}),
    awful.key({ modkey,           }, "Right",  awful.tag.viewnext,
              {description = "view next", group = "tag"}),
    awful.key({ modkey,           }, "Escape", awful.tag.history.restore,
              {description = "go back", group = "tag"}),

    -- Focus movement (vim-like, matches Hyprland hjkl)
    awful.key({ modkey,           }, "h",
        function ()
            awful.client.focus.bydirection("left")
        end,
        {description = "focus left", group = "client"}),
    awful.key({ modkey,           }, "j",
        function ()
            awful.client.focus.bydirection("down")
        end,
        {description = "focus down", group = "client"}),
    awful.key({ modkey,           }, "k",
        function ()
            awful.client.focus.bydirection("up")
        end,
        {description = "focus up", group = "client"}),
    awful.key({ modkey,           }, "l",
        function ()
            awful.client.focus.bydirection("right")
        end,
        {description = "focus right", group = "client"}),

    -- Layout manipulation
    awful.key({ modkey, "Shift"   }, "j", function () awful.client.swap.byidx(  1)    end,
              {description = "swap with next client by index", group = "client"}),
    awful.key({ modkey, "Shift"   }, "k", function () awful.client.swap.byidx( -1)    end,
              {description = "swap with previous client by index", group = "client"}),
    awful.key({ modkey, "Control" }, "j", function () awful.screen.focus_relative( 1) end,
              {description = "focus the next screen", group = "screen"}),
    awful.key({ modkey, "Control" }, "k", function () awful.screen.focus_relative(-1) end,
              {description = "focus the previous screen", group = "screen"}),
    awful.key({ modkey,           }, "u", awful.client.urgent.jumpto,
              {description = "jump to urgent client", group = "client"}),
    awful.key({ modkey,           }, "Tab",
        function ()
            awful.client.focus.history.previous()
            if client.focus then
                client.focus:raise()
            end
        end,
        {description = "go back", group = "client"}),

    -- Standard program launching (matches Hyprland exactly)
    awful.key({ modkey,           }, "Return", function () awful.spawn(terminal) end,
              {description = "open a terminal", group = "launcher"}),
    awful.key({ modkey, "Control" }, "r", awesome.restart,
              {description = "reload awesome", group = "awesome"}),
    awful.key({ modkey, "Control", "Shift" }, "r", function()
        startup_applications()
        print("AwesomeWM: Manually launched startup applications")
    end, {description = "manually launch startup apps", group = "awesome"}),
    awful.key({ modkey, "Shift"   }, "m", awesome.quit,
              {description = "quit awesome", group = "awesome"}),
    awful.key({ modkey,           }, "e", function () awful.spawn(filemanager) end,
              {description = "file manager", group = "launcher"}),
    
    -- Custom file type launchers
    awful.key({ modkey, "Shift"   }, "m", function () 
        awful.spawn.with_shell("rofi -dmenu -p 'Open markdown file:' | xargs -I {} kitty -e glow '{}'") 
    end, {description = "open markdown with glow", group = "launcher"}),

    -- Layout controls (using period/comma to avoid conflict with window focus)
    awful.key({ modkey,           }, "period", function () awful.layout.inc( 1)                end,
              {description = "select next", group = "layout"}),
    awful.key({ modkey,           }, "comma", function () awful.layout.inc(-1)                end,
              {description = "select previous", group = "layout"}),

    -- Application launcher (rofi - matches Hyprland)
    awful.key({ modkey }, "space",
        function()
            awful.spawn("rofi -show drun -theme ~/.config/rofi/config/app-launcher.rasi")
        end,
        {description = "show rofi launcher", group = "launcher"}),
    
    -- Window switcher keybindings
    awful.key({ "Mod1" }, "Tab",
        function()
            awful.spawn.with_shell("bash ~/.config/rofi/bin/window-switcher-advanced.sh all")
        end,
        {description = "show all windows", group = "window switcher"}),
    
    awful.key({ modkey }, "Tab",
        function()
            awful.spawn.with_shell("bash ~/.config/rofi/bin/window-switcher-advanced.sh current")
        end,
        {description = "show current workspace windows", group = "window switcher"}),
    
    awful.key({ modkey, "Shift" }, "Tab",
        function()
            awful.spawn.with_shell("bash ~/.config/rofi/bin/window-switcher-advanced.sh minimized")
        end,
        {description = "show minimized windows", group = "window switcher"}),
    
    awful.key({ modkey }, "w",
        function()
            mymainmenu:toggle()
        end,
        {description = "open context menu", group = "launcher"}),

    -- Volume controls (matches Hyprland)
    awful.key({ }, "XF86AudioRaiseVolume",
        function ()
            awful.spawn("pamixer -i 5")
            volume.update()
        end,
        {description = "volume up", group = "hotkeys"}),
    awful.key({ }, "XF86AudioLowerVolume",
        function ()
            awful.spawn("pamixer -d 5")
            volume.update()
        end,
        {description = "volume down", group = "hotkeys"}),
    awful.key({ }, "XF86AudioMute",
        function ()
            awful.spawn("pamixer -t")
            volume.update()
        end,
        {description = "toggle mute", group = "hotkeys"}),

    -- Brightness controls (matches Hyprland)
    awful.key({ }, "XF86MonBrightnessUp",
        function () awful.spawn("brightnessctl s 10%+") end,
        {description = "brightness up", group = "hotkeys"}),
    awful.key({ }, "XF86MonBrightnessDown",
        function () awful.spawn("brightnessctl s 10%-") end,
        {description = "brightness down", group = "hotkeys"}),

    -- Media controls (matches Hyprland)
    awful.key({ }, "XF86AudioPlay",
        function () awful.spawn("playerctl play-pause") end,
        {description = "play/pause", group = "hotkeys"}),
    awful.key({ }, "XF86AudioNext",
        function () awful.spawn("playerctl next") end,
        {description = "next track", group = "hotkeys"}),
    awful.key({ }, "XF86AudioPrev",
        function () awful.spawn("playerctl previous") end,
        {description = "previous track", group = "hotkeys"}),

    -- Screenshot (matches Hyprland hyprshot)
    awful.key({ }, "Print",
        function () awful.spawn.with_shell("scrot ~/Pictures/$(date +%Y-%m-%d-%H%M%S)-screenshot.png") end,
        {description = "screenshot", group = "hotkeys"}),
    awful.key({ modkey }, "Print",
        function () awful.spawn.with_shell("scrot -s ~/Pictures/$(date +%Y-%m-%d-%H%M%S)-screenshot-selection.png") end,
        {description = "screenshot selection", group = "hotkeys"}),

    -- Lock screen (matches Hyprland)
    awful.key({ modkey,           }, "l",
        function () awful.spawn("i3lock -c 000000") end,
        {description = "lock screen", group = "hotkeys"}),

    -- Theme switcher (using p for preferences/palette)
    awful.key({ modkey,           }, "p",
        function () awful.spawn.with_shell("bash ~/.config/themes/rofi-theme-selector.sh") end,
        {description = "theme switcher", group = "system"})

    -- Toggle bar visibility - DISABLED FOR POLYBAR
    --[[
    awful.key({ modkey,           }, "b",
        function ()
            for s in screen do
                s.mywibox.visible = not s.mywibox.visible
            end
        end,
        {description = "toggle bar", group = "awesome"})
    --]]
)

clientkeys = gears.table.join(
    awful.key({ modkey,           }, "f",
        function (c)
            c.fullscreen = not c.fullscreen
            c:raise()
        end,
        {description = "toggle fullscreen", group = "client"}),
    awful.key({ modkey,           }, "q",      function (c) c:kill()                         end,
              {description = "close", group = "client"}),
    awful.key({ modkey,           }, "v",  awful.client.floating.toggle                     ,
              {description = "toggle floating", group = "client"}),
    awful.key({ modkey, "Control" }, "Return", function (c) c:swap(awful.client.getmaster()) end,
              {description = "move to master", group = "client"}),
    awful.key({ modkey,           }, "o",      function (c) c:move_to_screen()               end,
              {description = "move to screen", group = "client"}),
    awful.key({ modkey,           }, "t",      function (c) c.ontop = not c.ontop            end,
              {description = "toggle keep on top", group = "client"}),
    awful.key({ modkey,           }, "n",
        function (c)
            c.minimized = true
        end ,
        {description = "minimize", group = "client"}),
    awful.key({ modkey, "Ctrl"    }, "n",
        function ()
            local c = awful.client.restore()
            -- Focus restored client
            if c then
                c:emit_signal(
                    "request::activate", "key.unminimize", {raise = true}
                )
            end
        end,
        {description = "restore minimized", group = "client"}),
    awful.key({ modkey,           }, "m",
        function (c)
            c.maximized = not c.maximized
            c:raise()
        end ,
        {description = "(un)maximize", group = "client"}),
    awful.key({ modkey, "Control" }, "m",
        function (c)
            c.maximized_vertical = not c.maximized_vertical
            c:raise()
        end ,
        {description = "(un)maximize vertically", group = "client"}),
    awful.key({ modkey, "Shift"   }, "m",
        function (c)
            c.maximized_horizontal = not c.maximized_horizontal
            c:raise()
        end ,
        {description = "(un)maximize horizontally", group = "client"})
)

-- Bind all key numbers to tags (matches Hyprland workspaces 1-10)
for i = 1, 10 do
    local descr_view, descr_toggle, descr_move, descr_toggle_focus
    if i == 10 then
        descr_view = {description = "view tag #10", group = "tag"}
        descr_toggle = {description = "toggle tag #10", group = "tag"}
        descr_move = {description = "move focused client to tag #10", group = "tag"}
        descr_toggle_focus = {description = "toggle focused client on tag #10", group = "tag"}
    else
        descr_view = {description = "view tag #"..i, group = "tag"}
        descr_toggle = {description = "toggle tag #"..i, group = "tag"}
        descr_move = {description = "move focused client to tag #"..i, group = "tag"}
        descr_toggle_focus = {description = "toggle focused client on tag #"..i, group = "tag"}
    end
    
    local key = i == 10 and "0" or tostring(i)
    
    globalkeys = gears.table.join(globalkeys,
        -- View tag only.
        awful.key({ modkey }, key,
                  function ()
                        local screen = awful.screen.focused()
                        local tag = screen.tags[i]
                        if tag then
                           tag:view_only()
                        end
                  end,
                  descr_view),
        -- Toggle tag display.
        awful.key({ modkey, "Control" }, key,
                  function ()
                      local screen = awful.screen.focused()
                      local tag = screen.tags[i]
                      if tag then
                         awful.tag.viewtoggle(tag)
                      end
                  end,
                  descr_toggle),
        -- Move client to tag.
        awful.key({ modkey, "Shift" }, key,
                  function ()
                      if client.focus then
                          local tag = client.focus.screen.tags[i]
                          if tag then
                              client.focus:move_to_tag(tag)
                          end
                     end
                  end,
                  descr_move),
        -- Toggle tag on focused client.
        awful.key({ modkey, "Control", "Shift" }, key,
                  function ()
                      if client.focus then
                          local tag = client.focus.screen.tags[i]
                          if tag then
                              client.focus:toggle_tag(tag)
                          end
                      end
                  end,
                  descr_toggle_focus)
    )
end

clientbuttons = gears.table.join(
    awful.button({ }, 1, function (c)
        c:emit_signal("request::activate", "mouse_click", {raise = true})
    end),
    awful.button({ modkey }, 1, function (c)
        c:emit_signal("request::activate", "mouse_click", {raise = true})
        awful.mouse.client.move(c)
    end),
    awful.button({ modkey }, 3, function (c)
        c:emit_signal("request::activate", "mouse_click", {raise = true})
        awful.mouse.client.resize(c)
    end)
)

-- Set keys
root.keys(globalkeys)

-- Rules to control window behavior
awful.rules.rules = {
    -- All clients will match this rule.
    { rule = { },
      properties = { border_width = beautiful.border_width,
                     border_color = beautiful.border_normal,
                     focus = awful.client.focus.filter,
                     raise = true,
                     keys = clientkeys,
                     buttons = clientbuttons,
                     screen = awful.screen.preferred,
                     placement = awful.placement.no_overlap+awful.placement.no_offscreen,
                     size_hints_honor = false
     }
    },

    -- Workspace assignments (matches Hyprland workspace rules)
    { rule = { class = "Google-chrome" },
      callback = function(c)
          c:move_to_tag(awful.screen.focused().tags[1])
      end },
    { rule = { class = "obsidian" },
      callback = function(c)
          c:move_to_tag(awful.screen.focused().tags[2])
      end },
    { rule_any = { class = { "Claude", "claude-desktop" } },
      callback = function(c)
          c:move_to_tag(awful.screen.focused().tags[2])
          gears.timer.start_new(0.1, function()
              c.minimized = true
              return false
          end)
      end },
    { rule = { instance = "dev1" },
      callback = function(c)
          c:move_to_tag(awful.screen.focused().tags[3])
      end },
    { rule = { instance = "dev2" },
      callback = function(c)
          c:move_to_tag(awful.screen.focused().tags[3])
      end },
    { rule = { class = "Code" },
      callback = function(c)
          c:move_to_tag(awful.screen.focused().tags[4])
      end },
    { rule_any = { class = { "Insync", "insync" }, name = { "Insync" } },
      callback = function(c)
          c:move_to_tag(awful.screen.focused().tags[5])
      end },
    { rule_any = { class = { "discord", "Discord" }, name = { "Discord" } },
      callback = function(c)
          c:move_to_tag(awful.screen.focused().tags[5])
          gears.timer.start_new(0.1, function()
              c.minimized = true
              return false
          end)
      end },
    { rule_any = { class = { "synergy", "Synergy", "synergys", "synergyc" }, name = { "Synergy" } },
      callback = function(c)
          c:move_to_tag(awful.screen.focused().tags[5])
          gears.timer.start_new(0.1, function()
              c.minimized = true
              return false
          end)
      end },

    -- Floating clients (matches some Hyprland window rules)
    { rule_any = {
        instance = {
          "DTA",  
          "copyq",  
          "pinentry",
        },
        class = {
          "Arandr",
          "Blueman-manager",
          "Gpick",
          "Kruler",
          "MessageWin",  
          "Sxiv",
          "Tor Browser", 
          "Wpa_gui",
          "veromix",
          "xtightvncviewer"
        },
        name = {
          "Event Tester",  
        },
        role = {
          "AlarmWindow",  
          "ConfigManager",  
          "pop-up",       
        }
      }, properties = { floating = true }},

    -- Add titlebars to normal clients and dialogs
    { rule_any = {type = { "normal", "dialog" }
      }, properties = { titlebars_enabled = false }
    },
}

-- Debug function to identify window properties
client.connect_signal("manage", function(c)
    -- Debug: print window class and instance for identification
    if c.class then
        print(string.format("New Window - Class: %s, Instance: %s, Name: %s", 
                   c.class or "nil", 
                   c.instance or "nil", 
                   c.name or "nil"))
    end
    
    if awesome.startup
      and not c.size_hints.user_position
      and not c.size_hints.program_position then
        awful.placement.no_offscreen(c)
    end
end)

-- Add a titlebar if titlebars_enabled is set to true in the rules.
client.connect_signal("request::titlebars", function(c)
    local buttons = gears.table.join(
        awful.button({ }, 1, function()
            c:emit_signal("request::activate", "titlebar", {raise = true})
            awful.mouse.client.move(c)
        end),
        awful.button({ }, 3, function()
            c:emit_signal("request::activate", "titlebar", {raise = true})
            awful.mouse.client.resize(c)
        end)
    )

    awful.titlebar(c) : setup {
        { 
            awful.titlebar.widget.iconwidget(c),
            buttons = buttons,
            layout  = wibox.layout.fixed.horizontal
        },
        { 
            { 
                align  = "center",
                widget = awful.titlebar.widget.titlewidget(c)
            },
            buttons = buttons,
            layout  = wibox.layout.flex.horizontal
        },
        { 
            awful.titlebar.widget.floatingbutton (c),
            awful.titlebar.widget.maximizedbutton(c),
            awful.titlebar.widget.stickybutton   (c),
            awful.titlebar.widget.ontopbutton    (c),
            awful.titlebar.widget.closebutton    (c),
            layout = wibox.layout.fixed.horizontal()
        },
        layout = wibox.layout.align.horizontal
    }
end)

-- Focus behavior
client.connect_signal("mouse::enter", function(c)
    c:emit_signal("request::activate", "mouse_enter", {raise = false})
end)

client.connect_signal("focus", function(c) c.border_color = beautiful.border_focus end)
client.connect_signal("unfocus", function(c) c.border_color = beautiful.border_normal end)

-- Restart Polybar when AwesomeWM restarts/reloads
awesome.connect_signal("startup", function()
    gears.timer.start_new(2, function()
        awful.spawn.with_shell("~/.config/polybar/launch.sh")
        return false -- run only once
    end)
end)
