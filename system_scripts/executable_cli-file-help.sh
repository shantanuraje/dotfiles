#!/bin/bash
# Enhanced File Management Workflow Guide

cat << 'EOF'
🗂️  Enhanced File Management Setup

FILE MANAGERS:
  fm       → nnn      (CLI: fastest, plugins, bookmarks)
  fmr      → ranger   (CLI: preview, vi-like)  
  fml      → lf       (CLI: miller columns, fast)
  fmg      → nautilus (GUI: full-featured GNOME)

SMART FILE OPENING HIERARCHY:
CLI file managers (nnn/lf/ranger) try tools in this order:

📝 TEXT FILES:
  1. $EDITOR (vim/nvim)  2. VS Code  3. GNOME Text Editor

🖼️  IMAGES:
  1. chafa (terminal)  2. viu (terminal)  3. feh  4. eog (GNOME)

🎬 VIDEO/AUDIO:
  1. mpv (terminal-capable)  2. vlc  3. GNOME defaults

📄 PDF DOCUMENTS:
  1. termpdf (terminal)  2. zathura  3. mupdf  4. evince (GNOME)

📦 ARCHIVES:
  1. CLI listing (unzip -l, tar -tf, 7z l)  2. file-roller (GNOME)

QUICK CLI ALIASES:
  img file.jpg       → View image in terminal with chafa
  imgv file.jpg      → View image with viu  
  pdf file.pdf       → Open PDF with zathura
  pdfterm file.pdf   → View PDF in terminal
  zipls archive.zip  → List zip contents
  tarls archive.tar  → List tar contents
  video file.mp4     → Play video with mpv
  
FILE MANAGER FEATURES:
  nnn:     Press ; for plugins, g+key for bookmarks, smart opener
  ranger:  Enter to open, r for rifle menu (already has CLI priority)
  lf:      l to open files, uses CLI-first hierarchy
  nautilus: Full GNOME integration, right-click context menus

WORKFLOW:
1. Use CLI file managers (fm/fmr/fml) for enhanced terminal experience
2. Use GUI file manager (fmg) for full desktop integration
3. CLI managers prefer terminal tools, fallback to GUI programs
4. All GNOME programs work as defaults when no CLI tool available

Best of both worlds: Enhanced CLI experience + full GUI integration!
EOF