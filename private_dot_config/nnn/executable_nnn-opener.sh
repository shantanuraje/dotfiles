#!/bin/bash
# nnn file opener with CLI tools first, GUI programs as fallback
# Prioritizes CLI/terminal applications when available

file_path="$1"
mime_type=$(file --mime-type -b "$file_path")

case "$mime_type" in
    text/*|application/json|application/xml|application/javascript)
        # Text files - use editor
        "$EDITOR" "$file_path"
        ;;
    image/*)
        # Images - CLI viewers first, fallback to GUI
        if command -v chafa >/dev/null 2>&1; then
            chafa "$file_path" | less -R
        elif command -v viu >/dev/null 2>&1; then
            viu "$file_path"
        elif command -v feh >/dev/null 2>&1; then
            feh "$file_path" &
        elif command -v eog >/dev/null 2>&1; then
            eog "$file_path" &
        else
            xdg-open "$file_path" &
        fi
        ;;
    video/*|audio/*)
        # Media files - mpv first (terminal capable), fallback to vlc
        if command -v mpv >/dev/null 2>&1; then
            mpv "$file_path"
        elif command -v vlc >/dev/null 2>&1; then
            vlc "$file_path" &
        else
            xdg-open "$file_path" &
        fi
        ;;
    application/pdf)
        # PDFs - CLI viewers first, fallback to GUI
        if command -v termpdf >/dev/null 2>&1; then
            termpdf "$file_path"
        elif command -v zathura >/dev/null 2>&1; then
            zathura "$file_path" &
        elif command -v mupdf >/dev/null 2>&1; then
            mupdf "$file_path" &
        elif command -v evince >/dev/null 2>&1; then
            evince "$file_path" &
        else
            # Extract text and view, or fallback to xdg-open
            pdftotext "$file_path" - | less 2>/dev/null || xdg-open "$file_path" &
        fi
        ;;
    application/zip|application/x-tar|application/x-7z-compressed|application/x-rar|application/gzip)
        # Archives - CLI listing first, fallback to GUI archive manager
        case "$file_path" in
            *.zip) 
                if command -v unzip >/dev/null 2>&1; then
                    unzip -l "$file_path" | less
                else
                    xdg-open "$file_path" &
                fi;;
            *.tar.gz|*.tgz) tar -tzf "$file_path" | less;;
            *.tar.bz2|*.tbz2) tar -tjf "$file_path" | less;;
            *.tar.xz|*.txz) tar -tJf "$file_path" | less;;
            *.tar) tar -tf "$file_path" | less;;
            *.7z) 
                if command -v 7z >/dev/null 2>&1; then
                    7z l "$file_path" | less
                else
                    xdg-open "$file_path" &
                fi;;
            *.rar) 
                if command -v unrar >/dev/null 2>&1; then
                    unrar l "$file_path" | less
                else
                    xdg-open "$file_path" &
                fi;;
            *) xdg-open "$file_path" &;;
        esac
        ;;
    application/x-executable|application/x-sharedlib)
        # Executables - show info
        echo "Executable: $file_path"
        file "$file_path"
        ldd "$file_path" 2>/dev/null | head -10
        ;;
    *)
        # Unknown types - fallback to xdg-open (will use GNOME defaults)
        xdg-open "$file_path" &
        ;;
esac