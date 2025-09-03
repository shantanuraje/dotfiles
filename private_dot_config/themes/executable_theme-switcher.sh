#!/bin/bash

#
# Universal Theme Switcher for AwesomeWM + Polybar + Rofi + Kitty
# Manages themes across all desktop components seamlessly
#

set -euo pipefail

# Configuration
THEMES_DIR="$HOME/.config/themes"
THEMES_JSON="$THEMES_DIR/themes.json"
CURRENT_THEME_FILE="$THEMES_DIR/current_theme"
TEMPLATES_DIR="$THEMES_DIR/templates"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Logging
log_info() {
    echo -e "${BLUE}[INFO]${NC} $*"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $*"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $*"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*"
}

# Check dependencies
check_dependencies() {
    local deps=("jq" "awesome" "polybar" "rofi" "kitty")
    local missing_deps=()
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing_deps+=("$dep")
        fi
    done
    
    if [ ${#missing_deps[@]} -ne 0 ]; then
        log_error "Missing dependencies: ${missing_deps[*]}"
        exit 1
    fi
}

# Get available themes
get_themes() {
    if [ ! -f "$THEMES_JSON" ]; then
        log_error "Themes configuration file not found: $THEMES_JSON"
        exit 1
    fi
    
    jq -r '.themes | keys[]' "$THEMES_JSON"
}

# Get current theme
get_current_theme() {
    if [ -f "$CURRENT_THEME_FILE" ]; then
        cat "$CURRENT_THEME_FILE"
    else
        jq -r '.current_theme' "$THEMES_JSON" 2>/dev/null || echo "catppuccin-macchiato"
    fi
}

# Set current theme
set_current_theme() {
    local theme="$1"
    echo "$theme" > "$CURRENT_THEME_FILE"
    jq ".current_theme = \"$theme\"" "$THEMES_JSON" > "${THEMES_JSON}.tmp" && mv "${THEMES_JSON}.tmp" "$THEMES_JSON"
}

# Generate color definitions for templates
generate_color_definitions() {
    local theme="$1"
    local colors
    colors=$(jq -r ".themes[\"$theme\"].colors" "$THEMES_JSON")
    
    if [ "$colors" = "null" ]; then
        log_error "Theme '$theme' not found in themes.json"
        exit 1
    fi
    
    # Generate Lua-style color definitions for AwesomeWM
    local color_defs=""
    while IFS= read -r line; do
        color_defs+="    $line,\n"
    done < <(echo "$colors" | jq -r 'to_entries[] | "\(.key) = \"\(.value)\""')
    
    echo -e "$color_defs"
}

# Apply theme to AwesomeWM
apply_awesome_theme() {
    local theme="$1"
    local theme_name
    theme_name=$(jq -r ".themes[\"$theme\"].name" "$THEMES_JSON")
    local template="$TEMPLATES_DIR/awesome-theme.lua.template"
    local output_dir="$HOME/.config/awesome/themes/$theme"
    local output_file="$output_dir/theme.lua"
    
    log_info "Applying AwesomeWM theme: $theme_name"
    
    # Create theme directory
    mkdir -p "$output_dir"
    
    # Create temporary processed file
    local temp_file=$(mktemp)
    
    # Process theme name first
    sed "s/{{THEME_NAME}}/$theme_name/g" "$template" > "$temp_file"
    
    # Replace color definitions line by line
    local colors
    colors=$(jq -r ".themes[\"$theme\"].colors" "$THEMES_JSON")
    
    # Build the color definitions string
    local color_block=""
    while IFS= read -r key; do
        local value
        value=$(echo "$colors" | jq -r ".[\"$key\"]")
        color_block+="    $key = \"$value\",\n"
    done < <(echo "$colors" | jq -r 'keys[]')
    
    # Replace the placeholder with actual color definitions
    awk -v colors="$color_block" '
    {
        if ($0 ~ /\{\{COLOR_DEFINITIONS\}\}/) {
            printf "%s", colors
        } else {
            print
        }
    }' "$temp_file" > "$output_file"
    
    rm "$temp_file"
    
    log_success "AwesomeWM theme applied to: $output_file"
}

# Apply theme to Polybar
apply_polybar_theme() {
    local theme="$1"
    local theme_name
    theme_name=$(jq -r ".themes[\"$theme\"].name" "$THEMES_JSON")
    local template="$TEMPLATES_DIR/polybar-config.ini.template"
    local output="$HOME/.config/polybar/config.ini"
    local colors
    colors=$(jq -r ".themes[\"$theme\"].colors" "$THEMES_JSON")
    
    log_info "Applying Polybar theme: $theme_name"
    
    # Extract specific colors for template substitution
    local base=$(echo "$colors" | jq -r '.base')
    local surface0=$(echo "$colors" | jq -r '.surface0')
    local text=$(echo "$colors" | jq -r '.text')
    local teal=$(echo "$colors" | jq -r '.teal')
    local red=$(echo "$colors" | jq -r '.red')
    local overlay0=$(echo "$colors" | jq -r '.overlay0')
    local green=$(echo "$colors" | jq -r '.green')
    local yellow=$(echo "$colors" | jq -r '.yellow')
    local peach=$(echo "$colors" | jq -r '.peach // .orange // .yellow')
    local pink=$(echo "$colors" | jq -r '.pink // .mauve')
    local mauve=$(echo "$colors" | jq -r '.mauve // .purple')
    local blue=$(echo "$colors" | jq -r '.blue')
    
    # Process template
    sed "s/{{THEME_NAME}}/$theme_name/g" "$template" | \
    sed "s/{{BASE}}/$base/g" | \
    sed "s/{{SURFACE0}}/$surface0/g" | \
    sed "s/{{TEXT}}/$text/g" | \
    sed "s/{{TEAL}}/$teal/g" | \
    sed "s/{{RED}}/$red/g" | \
    sed "s/{{OVERLAY0}}/$overlay0/g" | \
    sed "s/{{GREEN}}/$green/g" | \
    sed "s/{{YELLOW}}/$yellow/g" | \
    sed "s/{{PEACH}}/$peach/g" | \
    sed "s/{{PINK}}/$pink/g" | \
    sed "s/{{MAUVE}}/$mauve/g" | \
    sed "s/{{BLUE}}/$blue/g" > "$output"
    
    log_success "Polybar theme applied to: $output"
}

# Apply theme to Rofi
apply_rofi_theme() {
    local theme="$1"
    local theme_name
    theme_name=$(jq -r ".themes[\"$theme\"].name" "$THEMES_JSON")
    local colors_template="$TEMPLATES_DIR/rofi-colors.rasi.template"
    local launcher_template="$TEMPLATES_DIR/rofi-app-launcher.rasi.template"
    local window_template="$TEMPLATES_DIR/rofi-window.rasi.template"
    local colors_output="$HOME/.config/rofi/config/colors.rasi"
    local launcher_output="$HOME/.config/rofi/config/app-launcher.rasi"
    local window_output="$HOME/.config/rofi/config/window.rasi"
    local colors
    colors=$(jq -r ".themes[\"$theme\"].colors" "$THEMES_JSON")
    
    log_info "Applying Rofi theme: $theme_name"
    
    # Extract colors for template substitution
    local base=$(echo "$colors" | jq -r '.base')
    local mantle=$(echo "$colors" | jq -r '.mantle // .base')
    local surface0=$(echo "$colors" | jq -r '.surface0')
    local surface1=$(echo "$colors" | jq -r '.surface1 // .surface0')
    local text=$(echo "$colors" | jq -r '.text // .fg // .foreground')
    local subtext1=$(echo "$colors" | jq -r '.subtext1 // .fg1 // .text')
    local subtext0=$(echo "$colors" | jq -r '.subtext0 // .fg2 // .text')
    local teal=$(echo "$colors" | jq -r '.teal // .cyan // .aqua')
    local red=$(echo "$colors" | jq -r '.red')
    local overlay0=$(echo "$colors" | jq -r '.overlay0 // .gray // .comment')
    local green=$(echo "$colors" | jq -r '.green')
    local yellow=$(echo "$colors" | jq -r '.yellow')
    local mauve=$(echo "$colors" | jq -r '.mauve // .purple // .magenta')
    local blue=$(echo "$colors" | jq -r '.blue')
    
    # Process colors template
    sed "s/{{THEME_NAME}}/$theme_name/g" "$colors_template" | \
    sed "s/{{BASE}}/$base/g" | \
    sed "s/{{TEAL}}/$teal/g" | \
    sed "s/{{TEXT}}/$text/g" | \
    sed "s/{{MAUVE}}/$mauve/g" | \
    sed "s/{{BLUE}}/$blue/g" | \
    sed "s/{{SURFACE0}}/$surface0/g" | \
    sed "s/{{RED}}/$red/g" | \
    sed "s/{{YELLOW}}/$yellow/g" | \
    sed "s/{{OVERLAY0}}/$overlay0/g" | \
    sed "s/{{GREEN}}/$green/g" > "$colors_output"
    
    # Process app launcher template
    sed "s/{{THEME_NAME}}/$theme_name/g" "$launcher_template" | \
    sed "s/{{BASE}}/$base/g" | \
    sed "s/{{MANTLE}}/$mantle/g" | \
    sed "s/{{SURFACE0}}/$surface0/g" | \
    sed "s/{{SURFACE1}}/$surface1/g" | \
    sed "s/{{TEXT}}/$text/g" | \
    sed "s/{{SUBTEXT1}}/$subtext1/g" | \
    sed "s/{{SUBTEXT0}}/$subtext0/g" | \
    sed "s/{{TEAL}}/$teal/g" | \
    sed "s/{{RED}}/$red/g" | \
    sed "s/{{OVERLAY0}}/$overlay0/g" | \
    sed "s/{{GREEN}}/$green/g" | \
    sed "s/{{YELLOW}}/$yellow/g" | \
    sed "s/{{MAUVE}}/$mauve/g" | \
    sed "s/{{BLUE}}/$blue/g" > "$launcher_output"
    
    # Process window template
    sed "s/{{THEME_NAME}}/$theme_name/g" "$window_template" | \
    sed "s/{{BASE}}/$base/g" | \
    sed "s/{{MANTLE}}/$mantle/g" | \
    sed "s/{{SURFACE0}}/$surface0/g" | \
    sed "s/{{SURFACE1}}/$surface1/g" | \
    sed "s/{{TEXT}}/$text/g" | \
    sed "s/{{SUBTEXT1}}/$subtext1/g" | \
    sed "s/{{SUBTEXT0}}/$subtext0/g" | \
    sed "s/{{TEAL}}/$teal/g" | \
    sed "s/{{RED}}/$red/g" | \
    sed "s/{{OVERLAY0}}/$overlay0/g" | \
    sed "s/{{GREEN}}/$green/g" | \
    sed "s/{{YELLOW}}/$yellow/g" | \
    sed "s/{{MAUVE}}/$mauve/g" | \
    sed "s/{{BLUE}}/$blue/g" > "$window_output"
    
    log_success "Rofi theme applied to: $colors_output, $launcher_output, and $window_output"
}

# Apply theme to Kitty
apply_kitty_theme() {
    local theme="$1"
    local theme_name
    theme_name=$(jq -r ".themes[\"$theme\"].name" "$THEMES_JSON")
    local kitty_conf="$HOME/.config/kitty/kitty.conf"
    
    log_info "Applying Kitty theme: $theme_name"
    
    # Map themes to existing Kitty theme files
    local kitty_theme_file
    case "$theme" in
        catppuccin-macchiato)
            kitty_theme_file="catppuccin-themes/macchiato.conf"
            ;;
        catppuccin-mocha)
            kitty_theme_file="catppuccin-themes/mocha.conf"
            ;;
        catppuccin-latte)
            kitty_theme_file="catppuccin-themes/latte.conf"
            ;;
        gruvbox-dark)
            kitty_theme_file="kitty-themes/themes/gruvbox_dark.conf"
            ;;
        gruvbox-light)
            kitty_theme_file="kitty-themes/themes/gruvbox_light.conf"
            ;;
        nord)
            kitty_theme_file="themes/nord.conf"
            ;;
        tokyo-night)
            kitty_theme_file="themes/tokyo-night.conf"
            ;;
        dracula)
            kitty_theme_file="kitty-themes/themes/Dracula.conf"
            ;;
        one-light)
            kitty_theme_file="kitty-themes/themes/AtomOneLight.conf"
            ;;
        *)
            log_warn "No specific Kitty theme for '$theme', keeping current"
            return 0
            ;;
    esac
    
    # Update kitty.conf to include the new theme
    # First remove any existing theme includes
    sed -i '/^include.*\.conf$/d' "$kitty_conf"
    # Add the new theme include at the top
    sed -i "1i\\include $kitty_theme_file" "$kitty_conf"
    
    log_success "Kitty theme applied: $kitty_theme_file"
}

# Update AwesomeWM rc.lua to use new theme
update_awesome_config() {
    local theme="$1"
    local rc_lua="$HOME/.config/awesome/rc.lua"
    
    log_info "Updating AwesomeWM configuration for theme: $theme"
    
    # Update the chosen_theme variable in rc.lua
    sed -i "s/^local chosen_theme = .*/local chosen_theme = \"$theme\"/" "$rc_lua"
    
    log_success "AwesomeWM configuration updated"
}

# Reload applications
reload_applications() {
    log_info "Reloading applications..."
    
    # Reload AwesomeWM (only if running)
    if pgrep awesome > /dev/null; then
        echo 'awesome.restart()' | awesome-client 2>/dev/null || log_warn "Could not reload AwesomeWM (not in session?)"
        log_success "AwesomeWM reload attempted"
    else
        log_info "AwesomeWM not running, skipping reload"
    fi
    
    # Force Polybar reload
    log_info "Reloading Polybar..."
    pkill -9 polybar 2>/dev/null || true
    sleep 1
    
    # Start new Polybar instance
    DISPLAY=${DISPLAY:-:0} nohup bash ~/.config/polybar/launch.sh > /tmp/polybar-theme-reload.log 2>&1 &
    sleep 2
    
    if pgrep polybar > /dev/null; then
        log_success "Polybar reloaded successfully"
    else
        log_warn "Polybar reload failed - check /tmp/polybar-theme-reload.log"
        log_info "You may need to manually run: ~/.config/polybar/launch.sh"
    fi
    
    # Reload Kitty instances (send USR1 signal to reload config)
    if pgrep kitty > /dev/null; then
        pkill -USR1 kitty 2>/dev/null || true
        log_success "Kitty configuration reloaded"
    else
        log_info "Kitty not running, theme will apply on next launch"
    fi
}

# Apply theme
apply_theme() {
    local theme="$1"
    
    if [ -z "$theme" ]; then
        log_error "No theme specified"
        exit 1
    fi
    
    # Verify theme exists
    if ! echo "$theme" | grep -qx "$(get_themes)"; then
        log_error "Theme '$theme' not found. Available themes: $(get_themes | tr '\n' ' ')"
        exit 1
    fi
    
    local theme_name
    theme_name=$(jq -r ".themes[\"$theme\"].name" "$THEMES_JSON")
    
    log_info "Switching to theme: $theme_name"
    
    # Apply to each component
    apply_awesome_theme "$theme"
    apply_polybar_theme "$theme"
    apply_rofi_theme "$theme"
    apply_kitty_theme "$theme"
    
    # Update AwesomeWM config
    update_awesome_config "$theme"
    
    # Save current theme
    set_current_theme "$theme"
    
    # Reload applications
    reload_applications
    
    # Send notification
    if command -v notify-send &> /dev/null; then
        notify-send "Theme Switcher" "Switched to $theme_name" --urgency=normal --app-name=theme-switcher --icon=preferences-color
    fi
    
    log_success "Theme switched successfully to: $theme_name"
}

# List themes
list_themes() {
    echo -e "${PURPLE}Available Themes:${NC}"
    local current_theme
    current_theme=$(get_current_theme)
    
    while IFS= read -r theme; do
        local theme_name
        local description
        theme_name=$(jq -r ".themes[\"$theme\"].name" "$THEMES_JSON")
        description=$(jq -r ".themes[\"$theme\"].description" "$THEMES_JSON")
        
        if [ "$theme" = "$current_theme" ]; then
            echo -e "  ${GREEN}● $theme_name${NC} - $description ${CYAN}(current)${NC}"
        else
            echo -e "  ○ $theme_name - $description"
        fi
    done < <(get_themes)
}

# Interactive theme selection using Rofi
interactive_select() {
    local themes_list=""
    local current_theme
    current_theme=$(get_current_theme)
    
    while IFS= read -r theme; do
        local theme_name
        local description
        theme_name=$(jq -r ".themes[\"$theme\"].name" "$THEMES_JSON")
        description=$(jq -r ".themes[\"$theme\"].description" "$THEMES_JSON")
        
        if [ "$theme" = "$current_theme" ]; then
            themes_list+="● $theme_name - $description (current)\n"
        else
            themes_list+="○ $theme_name - $description\n"
        fi
    done < <(get_themes)
    
    local selection
    selection=$(echo -e "$themes_list" | rofi -dmenu -i -p "🎨 Select Theme" \
        -theme-str 'window {width: 60%; height: 50%;}' \
        -theme-str 'listview {lines: 8;}' \
        -theme-str 'element {padding: 12px;}' \
        -no-custom -format 'i')
    
    if [ -n "$selection" ]; then
        # Extract theme name from selection
        local selected_theme_name
        selected_theme_name=$(echo -e "$themes_list" | sed -n "$((selection + 1))p" | sed 's/^[●○] \([^-]*\) -.*/\1/')
        
        # Find corresponding theme key
        local selected_theme
        selected_theme=$(jq -r ".themes | to_entries[] | select(.value.name == \"$selected_theme_name\") | .key" "$THEMES_JSON")
        
        if [ -n "$selected_theme" ]; then
            apply_theme "$selected_theme"
        else
            log_error "Could not find theme: $selected_theme_name"
            exit 1
        fi
    fi
}

# Show help
show_help() {
    cat << EOF
Universal Theme Switcher for AwesomeWM + Polybar + Rofi + Kitty

USAGE:
    theme-switcher.sh [COMMAND] [THEME]

COMMANDS:
    apply <theme>    Apply specified theme
    list            List available themes
    current         Show current theme
    interactive     Interactive theme selection with Rofi
    help            Show this help message

EXAMPLES:
    theme-switcher.sh apply catppuccin-mocha
    theme-switcher.sh list
    theme-switcher.sh interactive

AVAILABLE THEMES:
$(get_themes | sed 's/^/    /')

EOF
}

# Main function
main() {
    # Ensure themes directory exists
    mkdir -p "$THEMES_DIR"
    
    case "${1:-help}" in
        apply)
            check_dependencies
            apply_theme "${2:-}"
            ;;
        list)
            list_themes
            ;;
        current)
            echo "Current theme: $(get_current_theme)"
            ;;
        interactive)
            check_dependencies
            interactive_select
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            log_error "Unknown command: $1"
            show_help
            exit 1
            ;;
    esac
}

main "$@"