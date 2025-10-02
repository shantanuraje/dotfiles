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

# # Function to set random wallpaper
# set_random_wallpaper() {
#     # Get all image files (handle spaces in filenames)
#     readarray -t WALLPAPERS < <(find "$WALLPAPER_DIR" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.bmp" \) | shuf)
    
#     if [ ${#WALLPAPERS[@]} -eq 0 ]; then
#         echo "No wallpapers found in $WALLPAPER_DIR"
#         exit 1
#     fi
    
#     # Select random wallpaper
#     WALLPAPER="${WALLPAPERS[0]}"
    
#     # Set wallpaper using feh
#     feh --bg-scale "$WALLPAPER"
    
#     echo "Set wallpaper: $WALLPAPER"
# }

set_random_wallpaper() {
    # Get all image files (handle spaces in filenames)
    readarray -t WALLPAPERS < <(find "$WALLPAPER_DIR" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.bmp" \) | shuf)

    if [ ${#WALLPAPERS[@]} -eq 0 ]; then
        echo "No wallpapers found in $WALLPAPER_DIR"
        exit 1
    fi

    # Get connected screens and their resolutions
    mapfile -t SCREENS < <(xrandr --query | awk '/ connected/ {print $1}')
    mapfile -t RESOLUTIONS < <(xrandr --query | awk '/ connected/ {match($0, /[0-9]+x[0-9]+/, a); print a[0]}')

    # Prepare wallpaper list for each screen
    WALLPAPER_ARGS=()
    USED_WALLPAPERS=()

    for i in "${!SCREENS[@]}"; do
        SCREEN="${SCREENS[$i]}"
        RES="${RESOLUTIONS[$i]}"
        WIDTH=${RES%x*}
        HEIGHT=${RES#*x}

        # Find suitable wallpaper
        for WP in "${WALLPAPERS[@]}"; do
            # Skip already used wallpapers
            if [[ " ${USED_WALLPAPERS[*]} " == *" $WP "* ]]; then
                continue
            fi

            # Get image dimensions
            DIM=$(identify -format "%w %h" "$WP" 2>/dev/null)
            IMG_W=${DIM%% *}
            IMG_H=${DIM##* }

            echo "Checking wallpaper $WP with dimensions ${IMG_W}x${IMG_H} for screen $SCREEN (${WIDTH}x${HEIGHT})"

            if [[ -z "$IMG_W" || -z "$IMG_H" ]]; then
                continue
            fi

            if (( HEIGHT > WIDTH )); then
                # Vertical screen: pick vertical image
                if (( IMG_H > IMG_W )); then
                    WALLPAPER_ARGS+=("$WP")
                    USED_WALLPAPERS+=("$WP")
                    break
                fi
            else
                # Horizontal screen: pick horizontal image
                if (( IMG_W >= IMG_H )); then
                    WALLPAPER_ARGS+=("$WP")
                    USED_WALLPAPERS+=("$WP")
                    break
                fi
            fi
        done
    done

    # Fallback: if not enough suitable wallpapers, fill with random
    while [ "${#WALLPAPER_ARGS[@]}" -lt "${#SCREENS[@]}" ]; do
        for WP in "${WALLPAPERS[@]}"; do
            if [[ ! " ${USED_WALLPAPERS[*]} " == *" $WP "* ]]; then
                WALLPAPER_ARGS+=("$WP")
                USED_WALLPAPERS+=("$WP")
                break
            fi
        done
    done

    # Set wallpapers using feh (one per screen)
    feh --no-fehbg --bg-scale "${WALLPAPER_ARGS[@]}"

    echo "Set wallpapers: ${WALLPAPER_ARGS[*]}"
}


# Main loop
while true; do
    set_random_wallpaper
    sleep $INTERVAL
done