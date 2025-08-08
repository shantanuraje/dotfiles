#!/bin/bash
# lf Preview Script - Enhanced preview for all file types
# Optimized for performance and comprehensive file support

file="$1"
w="$2"
h="$3"
x="$4"
y="$5"

# Exit if file doesn't exist
[ ! -f "$file" ] && exit 1

# File info cache for performance
filetype="$(file --dereference --brief --mime-type -- "$file")"
filename="$(basename "$file")"
fileext="${filename##*.}"

case "$filetype" in
    # Text files with enhanced previews
    text/*)
        case "$fileext" in
            csv)
                if command -v bat >/dev/null 2>&1; then
                    bat --color=always --style=numbers,grid --line-range=":$h" --paging=never "$file"
                else
                    echo "CSV file: $filename"
                    echo "Columns: $(head -1 "$file")"
                    echo "Rows: $(wc -l < "$file")"
                    echo ""
                    head -"$((h-5))" "$file" | column -t -s ','
                fi
                ;;
            tsv)
                if command -v bat >/dev/null 2>&1; then
                    bat --color=always --style=numbers,grid --line-range=":$h" --paging=never "$file"
                else
                    echo "TSV file: $filename"
                    head -"$h" "$file" | column -t -s $'\t'
                fi
                ;;
            log)
                if command -v bat >/dev/null 2>&1; then
                    bat --color=always --style=numbers --line-range=":$h" --paging=never --language=log "$file"
                else
                    echo "Log file: $filename (showing last $h lines)"
                    tail -"$h" "$file"
                fi
                ;;
            md|markdown)
                if command -v glow >/dev/null 2>&1; then
                    glow --style dark --width="$w" "$file"
                elif command -v bat >/dev/null 2>&1; then
                    bat --color=always --style=numbers --line-range=":$h" --paging=never --language=markdown "$file"
                else
                    head -"$h" "$file"
                fi
                ;;
            *)
                if command -v bat >/dev/null 2>&1; then
                    bat --color=always --style=numbers --line-range=":$h" --paging=never "$file"
                elif command -v highlight >/dev/null 2>&1; then
                    highlight --out-format=ansi --style=base16/monokai "$file" | head -"$h"
                else
                    head -"$h" "$file"
                fi
                ;;
        esac
        ;;
    
    # Source code (additional patterns)
    application/json|application/javascript|application/x-shellscript)
        if command -v bat >/dev/null 2>&1; then
            bat --color=always --style=numbers --line-range=":$h" --paging=never "$file"
        else
            head -"$h" "$file"
        fi
        ;;
    
    # Images
    image/*)
        if command -v chafa >/dev/null 2>&1; then
            chafa --fill=block --symbols=block -c 256 -s "${w}x${h}" "$file"
        elif command -v img2txt >/dev/null 2>&1; then
            img2txt --gamma=0.6 --width="$w" "$file"
        elif command -v exiftool >/dev/null 2>&1; then
            exiftool "$file"
        else
            echo "Image file: $filename"
            file --brief "$file"
        fi
        ;;
    
    # Videos
    video/*)
        if command -v ffmpegthumbnailer >/dev/null 2>&1; then
            # Generate thumbnail and show with chafa if available
            thumb="/tmp/lf_thumb_$(basename "$file").jpg"
            ffmpegthumbnailer -i "$file" -o "$thumb" -s 512 2>/dev/null
            if [ -f "$thumb" ] && command -v chafa >/dev/null 2>&1; then
                chafa --fill=block --symbols=block -c 256 -s "${w}x${h}" "$thumb"
                rm "$thumb"
            else
                mediainfo "$file" 2>/dev/null || file --brief "$file"
            fi
        elif command -v mediainfo >/dev/null 2>&1; then
            mediainfo "$file"
        else
            echo "Video file: $filename"
            file --brief "$file"
        fi
        ;;
    
    # Audio files
    audio/*)
        if command -v mediainfo >/dev/null 2>&1; then
            mediainfo "$file"
        elif command -v exiftool >/dev/null 2>&1; then
            exiftool "$file"
        else
            echo "Audio file: $filename"
            file --brief "$file"
        fi
        ;;
    
    # PDF files
    application/pdf)
        if command -v pdftotext >/dev/null 2>&1; then
            pdftotext -l 10 -nopgbrk -q "$file" - | head -"$h"
        elif command -v mutool >/dev/null 2>&1; then
            mutool draw -F txt -o - "$file" 1-10 | head -"$h"
        else
            echo "PDF file: $filename"
            file --brief "$file"
        fi
        ;;
    
    # Office documents
    application/vnd.openxmlformats-officedocument.wordprocessingml.document|\
    application/vnd.oasis.opendocument.text)
        if command -v odt2txt >/dev/null 2>&1; then
            odt2txt "$file" | head -"$h"
        elif command -v catdoc >/dev/null 2>&1; then
            catdoc "$file" | head -"$h"
        else
            echo "Office document: $filename"
            file --brief "$file"
        fi
        ;;
    
    # Spreadsheets
    application/vnd.openxmlformats-officedocument.spreadsheetml.sheet|\
    application/vnd.oasis.opendocument.spreadsheet)
        if command -v xlsx2csv >/dev/null 2>&1; then
            xlsx2csv "$file" | head -"$h"
        else
            echo "Spreadsheet: $filename"
            file --brief "$file"
        fi
        ;;
    
    # Archives
    application/zip|application/x-rar|application/x-tar|application/x-7z-compressed|\
    application/gzip|application/x-bzip2)
        if command -v atool >/dev/null 2>&1; then
            atool --list -- "$file"
        elif command -v unzip >/dev/null 2>&1 && [[ "$filetype" == *zip* ]]; then
            unzip -l "$file"
        elif command -v tar >/dev/null 2>&1 && [[ "$filetype" == *tar* ]]; then
            tar -tf "$file"
        else
            echo "Archive: $filename"
            file --brief "$file"
        fi
        ;;
    
    # Binary files
    application/octet-stream|application/x-executable)
        if command -v hexdump >/dev/null 2>&1; then
            echo "Binary file: $filename"
            echo "$(file --brief "$file")"
            echo ""
            echo "Hex dump (first 256 bytes):"
            hexdump -C "$file" | head -16
        else
            echo "Binary file: $filename"
            file --brief "$file"
        fi
        ;;
    
    # HTML files
    text/html)
        if command -v w3m >/dev/null 2>&1; then
            w3m -dump "$file" | head -"$h"
        elif command -v lynx >/dev/null 2>&1; then
            lynx -dump "$file" | head -"$h"
        else
            head -"$h" "$file"
        fi
        ;;
    
    # Markdown files
    text/markdown|text/x-markdown)
        if command -v glow >/dev/null 2>&1; then
            glow --style dark "$file"
        elif command -v bat >/dev/null 2>&1; then
            bat --color=always --style=numbers --line-range=":$h" --paging=never "$file"
        else
            head -"$h" "$file"
        fi
        ;;
    
    # Default case
    *)
        # Try to detect by file extension if MIME type detection failed
        case "$fileext" in
            md|markdown)
                if command -v glow >/dev/null 2>&1; then
                    glow --style dark "$file"
                elif command -v bat >/dev/null 2>&1; then
                    bat --color=always --style=numbers --line-range=":$h" --paging=never "$file"
                else
                    head -"$h" "$file"
                fi
                ;;
            log)
                if command -v bat >/dev/null 2>&1; then
                    bat --color=always --style=numbers --line-range=":$h" --paging=never "$file"
                else
                    tail -"$h" "$file"
                fi
                ;;
            *)
                echo "File: $filename"
                echo "Type: $(file --brief "$file")"
                echo "Size: $(du -h "$file" | cut -f1)"
                echo "Modified: $(stat -c %y "$file" 2>/dev/null || stat -f %Sm "$file" 2>/dev/null)"
                echo ""
                # Try to show as text if it's small and looks like text
                if [ "$(wc -c < "$file")" -lt 1048576 ]; then
                    if file --mime-encoding "$file" | grep -q "us-ascii\|utf-8"; then
                        echo "Content preview:"
                        head -"$((h-10))" "$file"
                    fi
                fi
                ;;
        esac
        ;;
esac