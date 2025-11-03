#!/bin/bash

# Fix for "SnippingEdit.app is damaged and can't be opened" error
# This happens when the app is downloaded from the internet

APP_PATH="$1"

# If no path provided, try to find it in common locations
if [ -z "$APP_PATH" ]; then
    if [ -f "build/SnippingEdit.app/Contents/MacOS/SnippingEdit" ]; then
        APP_PATH="build/SnippingEdit.app"
    elif [ -f "SnippingEdit.app/Contents/MacOS/SnippingEdit" ]; then
        APP_PATH="SnippingEdit.app"
    elif [ -f "$HOME/Downloads/SnippingEdit.app/Contents/MacOS/SnippingEdit" ]; then
        APP_PATH="$HOME/Downloads/SnippingEdit.app"
    else
        echo "❌ Could not find SnippingEdit.app"
        echo ""
        echo "Usage: $0 [path/to/SnippingEdit.app]"
        echo ""
        echo "Example:"
        echo "  $0 ~/Downloads/SnippingEdit.app"
        echo ""
        exit 1
    fi
fi

# Check if app exists
if [ ! -d "$APP_PATH" ]; then
    echo "❌ App not found at: $APP_PATH"
    exit 1
fi

echo "🔧 Fixing SnippingEdit.app..."
echo "   Path: $APP_PATH"
echo ""

# Remove quarantine attribute
echo "1. Removing quarantine attribute..."
xattr -cr "$APP_PATH"

# Make executable
echo "2. Making executable..."
chmod +x "$APP_PATH/Contents/MacOS/SnippingEdit"

# Verify
echo "3. Verifying..."
if [ -x "$APP_PATH/Contents/MacOS/SnippingEdit" ]; then
    echo ""
    echo "✅ App fixed successfully!"
    echo ""
    echo "You can now run the app:"
    echo "  open \"$APP_PATH\""
    echo ""
    echo "Or double-click it in Finder."
    echo ""
else
    echo ""
    echo "❌ Failed to fix app. Try running with sudo:"
    echo "  sudo $0 \"$APP_PATH\""
    echo ""
    exit 1
fi

