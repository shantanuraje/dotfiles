---------------------------
-- Catppuccin Macchiato AwesomeWM theme
-- Matches Hyprland Catppuccin Macchiato setup
---------------------------

local theme_assets = require("beautiful.theme_assets")
local xresources = require("beautiful.xresources")
local dpi = xresources.apply_dpi
local gfs = require("gears.filesystem")
local themes_path = gfs.get_themes_dir()

local theme = {}

-- Catppuccin Macchiato colors (matches hyprland catppuccin/themes/macchiato.conf)
local colors = {
    rosewater = "#f4dbd6",
    flamingo = "#f0c6c6", 
    pink = "#f5bde6",
    mauve = "#c6a0f6",
    red = "#ed8796",
    maroon = "#ee99a0",
    peach = "#f5a97f",
    yellow = "#eed49f",
    green = "#a6da95",
    teal = "#8bd5ca",
    sky = "#91d7e3",
    sapphire = "#7dc4e4",
    blue = "#8aadf4",
    lavender = "#b7bdf8",
    text = "#cad3f5",
    subtext1 = "#b8c0e0",
    subtext0 = "#a5adcb",
    overlay2 = "#939ab7",
    overlay1 = "#8087a2",
    overlay0 = "#6e738d",
    surface2 = "#5b6078",
    surface1 = "#494d64",
    surface0 = "#363a4f",
    base = "#24273a",
    mantle = "#1e2030",
    crust = "#181926"
}

-- Font (using FiraCode Nerd Font)
theme.font          = "FiraCode Nerd Font Propo 10"
theme.taglist_font  = "FiraCode Nerd Font Propo Bold 10"

-- Background colors
theme.bg_normal     = colors.base     -- #24273a
theme.bg_focus      = colors.surface0 -- #363a4f  
theme.bg_urgent     = colors.red      -- #ed8796
theme.bg_minimize   = colors.surface1 -- #494d64
theme.bg_systray    = colors.base     -- #24273a

-- Foreground colors
theme.fg_normal     = colors.text     -- #cad3f5
theme.fg_focus      = colors.text     -- #cad3f5
theme.fg_urgent     = colors.base     -- #24273a
theme.fg_minimize   = colors.overlay0 -- #6e738d

-- Gaps (matches Hyprland gaps_in=2, gaps_out=4)
theme.useless_gap   = dpi(2)

-- Borders (matches Hyprland border_size=2, rounding=10)
theme.border_width  = dpi(2)
theme.border_normal = colors.overlay0     -- #6e738d (matches inactive border)
theme.border_focus  = colors.teal         -- #8bd5ca (cyan/green like Hyprland active border)
theme.border_marked = colors.red          -- #ed8796

-- Titlebar colors
theme.titlebar_bg_focus  = colors.surface0  -- #363a4f
theme.titlebar_bg_normal = colors.base      -- #24273a
theme.titlebar_fg_focus  = colors.text      -- #cad3f5
theme.titlebar_fg_normal = colors.subtext0  -- #a5adcb

-- Menu colors
theme.menu_submenu_icon = themes_path.."default/submenu.png"
theme.menu_height = dpi(15)
theme.menu_width  = dpi(100)
theme.menu_bg_normal = colors.base       -- #24273a
theme.menu_bg_focus  = colors.surface0   -- #363a4f
theme.menu_fg_normal = colors.text       -- #cad3f5
theme.menu_fg_focus  = colors.text       -- #cad3f5
theme.menu_border_color = colors.overlay0 -- #6e738d
theme.menu_border_width = dpi(1)

-- Hotkeys popup
theme.hotkeys_bg = colors.base           -- #24273a
theme.hotkeys_fg = colors.text           -- #cad3f5
theme.hotkeys_border_width = dpi(2)
theme.hotkeys_border_color = colors.overlay0 -- #6e738d
theme.hotkeys_modifiers_fg = colors.mauve    -- #c6a0f6
theme.hotkeys_label_bg = colors.surface0     -- #363a4f
theme.hotkeys_label_fg = colors.text         -- #cad3f5
theme.hotkeys_group_margin = dpi(20)

-- Notifications
theme.notification_font = theme.font
theme.notification_bg = colors.base           -- #24273a
theme.notification_fg = colors.text           -- #cad3f5
theme.notification_border_color = colors.overlay0 -- #6e738d
theme.notification_border_width = dpi(2)
theme.notification_margin = dpi(10)
theme.notification_opacity = 0.9
theme.notification_max_width = dpi(400)
theme.notification_max_height = dpi(200)

-- Taglist
theme.taglist_bg_focus    = colors.surface0  -- #363a4f
theme.taglist_bg_urgent   = colors.red       -- #ed8796
theme.taglist_bg_occupied = colors.surface1  -- #494d64
theme.taglist_bg_empty    = "transparent"
theme.taglist_fg_focus    = colors.text      -- #cad3f5
theme.taglist_fg_urgent   = colors.base      -- #24273a
theme.taglist_fg_occupied = colors.subtext0  -- #a5adcb
theme.taglist_fg_empty    = colors.overlay0  -- #6e738d

-- Taglist shapes and spacing
theme.taglist_spacing = 4
theme.taglist_shape = function(cr, width, height)
    return require("gears").shape.rounded_rect(cr, width, height, 8)
end

-- Tasklist
theme.tasklist_bg_focus  = colors.surface0   -- #363a4f
theme.tasklist_bg_normal = "transparent"
theme.tasklist_fg_focus  = colors.text       -- #cad3f5
theme.tasklist_fg_normal = colors.subtext0   -- #a5adcb

-- Systray
theme.systray_icon_spacing = dpi(5)

-- Wibar (status bar)
theme.wibar_bg = "transparent"       -- Transparent background for modular look
theme.wibar_fg = colors.text         -- #cad3f5
theme.wibar_border_color = colors.overlay0 -- #6e738d
theme.wibar_border_width = dpi(0)
theme.wibar_height = dpi(40)

-- Module backgrounds (for individual widget groups)
theme.module_bg = colors.base .. "dd" -- Semi-transparent module background
theme.module_shape = function(cr, width, height)
    return require("gears").shape.rounded_rect(cr, width, height, 10)
end

-- Widget icons (placeholder paths - you may need to adjust these)
theme.widget_ac                     = themes_path.."default/icons/ac.png"
theme.widget_battery                = themes_path.."default/icons/battery.png"
theme.widget_battery_low            = themes_path.."default/icons/battery_low.png"
theme.widget_battery_empty          = themes_path.."default/icons/battery_empty.png"
theme.widget_brightness             = themes_path.."default/icons/brightness.png"
theme.widget_clock                  = themes_path.."default/icons/clock.png"
theme.widget_cpu                    = themes_path.."default/icons/cpu.png"
theme.widget_mem                    = themes_path.."default/icons/mem.png"
theme.widget_net                    = themes_path.."default/icons/net.png"
theme.widget_temp                   = themes_path.."default/icons/temp.png"
theme.widget_vol                    = themes_path.."default/icons/vol.png"
theme.widget_vol_low                = themes_path.."default/icons/vol_low.png"
theme.widget_vol_no                 = themes_path.."default/icons/vol_no.png"
theme.widget_vol_mute               = themes_path.."default/icons/vol_mute.png"

-- Layout icons
theme.layout_fairh      = themes_path.."default/layouts/fairhw.png"
theme.layout_fairv      = themes_path.."default/layouts/fairvw.png"
theme.layout_floating   = themes_path.."default/layouts/floatingw.png"
theme.layout_magnifier  = themes_path.."default/layouts/magnifierw.png"
theme.layout_max        = themes_path.."default/layouts/maxw.png"
theme.layout_fullscreen = themes_path.."default/layouts/fullscreenw.png"
theme.layout_tilebottom = themes_path.."default/layouts/tilebottomw.png"
theme.layout_tileleft   = themes_path.."default/layouts/tileleftw.png"
theme.layout_tile       = themes_path.."default/layouts/tilew.png"
theme.layout_tiletop    = themes_path.."default/layouts/tiletopw.png"
theme.layout_spiral     = themes_path.."default/layouts/spiralw.png"
theme.layout_dwindle    = themes_path.."default/layouts/dwindlew.png"
theme.layout_cornernw   = themes_path.."default/layouts/cornernww.png"
theme.layout_cornerne   = themes_path.."default/layouts/cornernew.png"
theme.layout_cornersw   = themes_path.."default/layouts/cornersww.png"
theme.layout_cornerse   = themes_path.."default/layouts/cornersew.png"

-- Generate Awesome icon using beautiful
theme.awesome_icon = theme_assets.awesome_icon(
    theme.menu_height, theme.bg_focus, theme.fg_focus
)

-- Define the icon theme for application icons
theme.icon_theme = nil

-- Wallpaper (matches Hyprland wallpaper)
theme.wallpaper = os.getenv("HOME") .. "/Pictures/wallpapers/forest_bridge.jpg"

return theme