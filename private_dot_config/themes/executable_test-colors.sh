#!/bin/bash

# Test script to show color previews for themes

THEMES_JSON="$HOME/.config/themes/themes.json"

echo "🎨 Available Themes with Color Previews:"
echo

while IFS= read -r theme; do
    theme_name=$(jq -r ".themes[\"$theme\"].name" "$THEMES_JSON")
    description=$(jq -r ".themes[\"$theme\"].description" "$THEMES_JSON")
    colors=$(jq -r ".themes[\"$theme\"].colors" "$THEMES_JSON")
    
    # Get main colors
    red=$(echo "$colors" | jq -r '.red')
    green=$(echo "$colors" | jq -r '.green') 
    blue=$(echo "$colors" | jq -r '.blue')
    yellow=$(echo "$colors" | jq -r '.yellow')
    purple=$(echo "$colors" | jq -r '.mauve // .purple')
    teal=$(echo "$colors" | jq -r '.teal // .cyan')
    
    echo "○ $theme_name"
    echo "  $description"
    echo -e "  Colors: \033[31m●\033[32m●\033[34m●\033[33m●\033[35m●\033[36m●\033[0m ($red $green $blue $yellow $purple $teal)"
    echo
done < <(jq -r '.themes | keys[]' "$THEMES_JSON")

echo "Usage:"
echo "  ~/.config/themes/theme-switcher.sh interactive"
echo "  Super+P (in AwesomeWM)"