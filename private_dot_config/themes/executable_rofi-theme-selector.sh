#!/bin/bash

#
# Rofi Theme Selector
# Beautiful interface for selecting themes
#

set -euo pipefail

THEMES_DIR="$HOME/.config/themes"
THEMES_JSON="$THEMES_DIR/themes.json"

# Get current theme
get_current_theme() {
    if [ -f "$THEMES_DIR/current_theme" ]; then
        cat "$THEMES_DIR/current_theme"
    else
        jq -r '.current_theme' "$THEMES_JSON" 2>/dev/null || echo "catppuccin-macchiato"
    fi
}

# Generate theme list for Rofi with color previews
generate_theme_list() {
    local current_theme
    current_theme=$(get_current_theme)
    
    while IFS= read -r theme; do
        local theme_name
        local description
        local colors
        theme_name=$(jq -r ".themes[\"$theme\"].name" "$THEMES_JSON")
        description=$(jq -r ".themes[\"$theme\"].description" "$THEMES_JSON")
        colors=$(jq -r ".themes[\"$theme\"].colors" "$THEMES_JSON")
        
        # Get main colors for preview
        local red=$(echo "$colors" | jq -r '.red')
        local green=$(echo "$colors" | jq -r '.green') 
        local blue=$(echo "$colors" | jq -r '.blue')
        local yellow=$(echo "$colors" | jq -r '.yellow')
        local purple=$(echo "$colors" | jq -r '.mauve // .purple')
        local teal=$(echo "$colors" | jq -r '.teal // .cyan')
        
        # Create color preview using colored circles
        local color_preview="<span color='$red'>●</span><span color='$green'>●</span><span color='$blue'>●</span><span color='$yellow'>●</span><span color='$purple'>●</span><span color='$teal'>●</span>"
        
        if [ "$theme" = "$current_theme" ]; then
            echo "● $theme_name - $description $color_preview (current)"
        else
            echo "○ $theme_name - $description $color_preview"
        fi
    done < <(jq -r '.themes | keys[]' "$THEMES_JSON")
}

# Custom Rofi theme for theme selector
create_rofi_theme() {
    cat << 'EOF'
configuration {
    show-icons: true;
    icon-theme: "Papirus";
    display-drun: "🎨 Themes";
    display-dmenu: "🎨 Select Theme";
    font: "JetBrains Mono Nerd Font 12";
}

* {
    bg0: #24273aff;
    bg1: #1e2030ff;
    bg2: #363a4fff;
    fg0: #cad3f5ff;
    fg1: #b8c0e0ff;
    accent: #8bd5caff;
    urgent: #ed8796ff;
    transparent: #00000000;
}

window {
    transparency: "real";
    background-color: @bg0;
    text-color: @fg0;
    border: 3px solid;
    border-color: @accent;
    border-radius: 15px;
    width: 50%;
    height: 60%;
    location: center;
    anchor: center;
}

mainbox {
    background-color: transparent;
    children: [ inputbar, message, listview ];
    spacing: 20px;
    padding: 30px;
}

inputbar {
    children: [ prompt, entry ];
    background-color: @bg1;
    border-radius: 10px;
    padding: 12px 15px;
    border: 2px solid;
    border-color: @bg2;
}

prompt {
    background-color: transparent;
    text-color: @accent;
    font: "JetBrains Mono Nerd Font Bold 14";
    margin: 0px 10px 0px 0px;
}

entry {
    background-color: transparent;
    text-color: @fg0;
    placeholder-color: @fg1;
    expand: true;
    placeholder: "Search themes...";
}

message {
    background-color: @bg1;
    text-color: @fg0;
    border-radius: 8px;
    padding: 15px;
    border: 2px solid;
    border-color: @bg2;
}

textbox {
    background-color: transparent;
    text-color: @fg0;
    font: "JetBrains Mono Nerd Font 11";
    vertical-align: 0.5;
}

listview {
    background-color: transparent;
    columns: 1;
    lines: 6;
    spacing: 8px;
    cycle: true;
    dynamic: true;
    scrollbar: true;
    layout: vertical;
    reverse: false;
    fixed-height: true;
}

scrollbar {
    width: 6px;
    border: 0px;
    border-radius: 3px;
    background-color: @bg2;
    handle-color: @accent;
    handle-width: 6px;
    padding: 0px;
}

element {
    background-color: @bg1;
    text-color: @fg0;
    orientation: horizontal;
    border-radius: 10px;
    padding: 12px 20px;
    margin: 2px;
    border: 2px solid;
    border-color: transparent;
}

element.selected {
    background-color: @accent;
    text-color: @bg0;
    border-color: @accent;
    font: "JetBrains Mono Nerd Font Bold 12";
}

element.alternate {
    background-color: @bg1;
}

element-text {
    background-color: transparent;
    text-color: inherit;
    expand: true;
    horizontal-align: 0;
    vertical-align: 0.5;
    margin: 0px;
    font: "JetBrains Mono Nerd Font 11";
}
EOF
}

# Show theme preview
show_theme_preview() {
    local theme="$1"
    local theme_name
    local description
    local colors
    
    theme_name=$(jq -r ".themes[\"$theme\"].name" "$THEMES_JSON")
    description=$(jq -r ".themes[\"$theme\"].description" "$THEMES_JSON")
    colors=$(jq -r ".themes[\"$theme\"].colors" "$THEMES_JSON")
    
    # Create color preview
    local preview_text="🎨 $theme_name\n\n$description\n\nColor Preview:"
    preview_text+="\n🔴 Red: $(echo "$colors" | jq -r '.red')"
    preview_text+="\n🟢 Green: $(echo "$colors" | jq -r '.green')"
    preview_text+="\n🔵 Blue: $(echo "$colors" | jq -r '.blue')"
    preview_text+="\n🟡 Yellow: $(echo "$colors" | jq -r '.yellow')"
    preview_text+="\n🟣 Purple: $(echo "$colors" | jq -r '.mauve // .purple')"
    preview_text+="\n🟦 Teal: $(echo "$colors" | jq -r '.teal // .cyan')"
    preview_text+="\n⚫ Background: $(echo "$colors" | jq -r '.base // .background')"
    preview_text+="\n⚪ Text: $(echo "$colors" | jq -r '.text // .foreground')"
    
    echo -e "$preview_text" | rofi -dmenu -p "🎨 Theme Preview" \
        -mesg "Press Enter to apply this theme, Escape to cancel" \
        -theme-str 'window {width: 400px; height: 500px;}' \
        -theme-str 'listview {lines: 1;}' \
        -theme-str 'element {padding: 10px;}' \
        -no-custom > /dev/null
    
    if [ $? -eq 0 ]; then
        bash "$THEMES_DIR/theme-switcher.sh" apply "$theme"
    fi
}

# Main execution
main() {
    case "${1:-interactive}" in
        preview)
            show_theme_preview "${2:-}"
            ;;
        *)
            # Generate themes list with better formatting
            local themes_list
            themes_list=$(generate_theme_list)
            
            # Create temporary Rofi theme
            local temp_theme_file="/tmp/rofi-theme-selector.rasi"
            create_rofi_theme > "$temp_theme_file"
            
            # Show selection with custom styling
            local selection
            selection=$(echo "$themes_list" | rofi -dmenu -i -p "🎨 Select Theme" \
                -theme "$temp_theme_file" \
                -mesg "Select a theme to apply across all applications" \
                -markup-rows \
                -no-custom)
            
            # Clean up temporary theme file
            rm -f "$temp_theme_file"
            
            if [ -n "$selection" ]; then
                # Extract theme key from selection
                local selected_theme=""
                
                case "$selection" in
                    *"Catppuccin Macchiato"*) selected_theme="catppuccin-macchiato" ;;
                    *"Catppuccin Mocha"*) selected_theme="catppuccin-mocha" ;;
                    *"Catppuccin Latte"*) selected_theme="catppuccin-latte" ;;
                    *"Gruvbox Dark"*) selected_theme="gruvbox-dark" ;;
                    *"Gruvbox Light"*) selected_theme="gruvbox-light" ;;
                    *"Nord"*) selected_theme="nord" ;;
                    *"Tokyo Night"*) selected_theme="tokyo-night" ;;
                    *"Dracula"*) selected_theme="dracula" ;;
                    *"One Light"*) selected_theme="one-light" ;;
                esac
                
                if [ -n "$selected_theme" ]; then
                    bash "$THEMES_DIR/theme-switcher.sh" apply "$selected_theme"
                fi
            fi
            ;;
    esac
}

main "$@"