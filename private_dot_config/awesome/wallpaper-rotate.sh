#!/bin/bash

# Wallpaper rotation script for AwesomeWM
# Rotates wallpapers from ~/Pictures/wallpapers/ every 10 minutes

WALLPAPER_DIR="$HOME/Pictures/wallpapers"
INTERVAL=600  # 10 minutes in seconds

# Check if wallpaper directory exists
if [ ! -d "$WALLPAPER_DIR" ]; then
    echo "Wallpaper directory $WALLPAPER_DIR does not exist"
    exit 1
fi

# Function to set random wallpaper
set_random_wallpaper() {
    # Get all image files (handle spaces in filenames)
    # Previous solution:
    # mapfile -t WALLPAPERS < <(find "$WALLPAPER_DIR" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.bmp" \))
    # if [ ${#WALLPAPERS[@]} -eq 0 ]; then
    #     echo "No wallpapers found in $WALLPAPER_DIR"
    #     exit 1
    # fi
    # RANDOM_INDEX=$((RANDOM % ${#WALLPAPERS[@]}))
    # WALLPAPERS=("${WALLPAPERS[$RANDOM_INDEX]}")

    # Improved randomness using shuf
    mapfile -t WALLPAPERS < <(find "$WALLPAPER_DIR" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.bmp" \) -print0 | shuf -z | xargs -0 -n1)
    
    if [ ${#WALLPAPERS[@]} -eq 0 ]; then
        echo "No wallpapers found in $WALLPAPER_DIR"
        exit 1
    fi
    
    # Select random wallpaper
    WALLPAPER="${WALLPAPERS[0]}"
    
    # Set wallpaper using feh
    feh --bg-scale "$WALLPAPER"
    
    echo "Set wallpaper: $WALLPAPER"
}

# Main loop
while true; do
    set_random_wallpaper
    sleep $INTERVAL
done