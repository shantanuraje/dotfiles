#!/bin/bash
# Update MIME database and file associations

echo "🔄 Updating MIME database and file associations..."

# Update MIME database
if command -v update-mime-database >/dev/null 2>&1; then
    update-mime-database ~/.local/share/mime 2>/dev/null || true
    echo "✅ Updated user MIME database"
fi

# Update desktop database  
if command -v update-desktop-database >/dev/null 2>&1; then
    update-desktop-database ~/.local/share/applications 2>/dev/null || true
    echo "✅ Updated desktop database"
fi

# Refresh file associations
if command -v xdg-mime >/dev/null 2>&1; then
    echo "📁 Current default applications:"
    echo "  Text files: $(xdg-mime query default text/plain)"
    echo "  Images: $(xdg-mime query default image/jpeg)"
    echo "  Videos: $(xdg-mime query default video/mp4)"
    echo "  PDFs: $(xdg-mime query default application/pdf)"
fi

echo "✅ MIME database update complete!"
echo "💡 You may need to restart applications or log out/in for changes to take full effect."