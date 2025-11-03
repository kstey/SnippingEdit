#!/bin/bash

# Quick fix for "App is damaged" error
# Run this if you downloaded the app and macOS blocks it

echo "🔧 Fixing SnippingEdit.app..."
echo ""

# Find the app
if [ -f "SnippingEdit.app/Contents/MacOS/SnippingEdit" ]; then
    APP_PATH="SnippingEdit.app"
else
    echo "❌ SnippingEdit.app not found in current directory"
    echo ""
    echo "Usage:"
    echo "  1. Open Terminal"
    echo "  2. cd to the folder containing SnippingEdit.app"
    echo "  3. Run: ./FIX_IF_DAMAGED.sh"
    echo ""
    exit 1
fi

# Apply fixes
echo "Removing quarantine attribute..."
xattr -cr "$APP_PATH"

echo "Setting executable permissions..."
chmod +x "$APP_PATH/Contents/MacOS/SnippingEdit"

echo ""
echo "✅ Fixed! You can now open SnippingEdit.app"
echo ""
echo "Double-click the app or run:"
echo "  open SnippingEdit.app"
echo ""
