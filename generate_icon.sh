#!/bin/bash

# Script to generate the clipboard icon

echo "Generating clipboard icon..."

# Run the Swift icon generator
swift create_clipboard_icon.swift

# Create iconset directory
mkdir -p AppIcon.iconset

# Copy and resize icons to proper iconset structure
echo "Creating iconset..."
sips -s format png /tmp/icon_16x16.png --out AppIcon.iconset/icon_16x16.png > /dev/null 2>&1
cp AppIcon.iconset/icon_16x16.png AppIcon.iconset/icon_16x16@2x.png
sips -s format png /tmp/icon_32x32.png --out AppIcon.iconset/icon_32x32.png > /dev/null 2>&1
cp AppIcon.iconset/icon_32x32.png AppIcon.iconset/icon_32x32@2x.png
sips -s format png /tmp/icon_128x128.png --out AppIcon.iconset/icon_128x128.png > /dev/null 2>&1
sips -s format png /tmp/icon_256x256.png --out AppIcon.iconset/icon_256x256.png > /dev/null 2>&1
cp AppIcon.iconset/icon_256x256.png AppIcon.iconset/icon_128x128@2x.png
sips -s format png /tmp/icon_512x512.png --out AppIcon.iconset/icon_512x512.png > /dev/null 2>&1
cp AppIcon.iconset/icon_512x512.png AppIcon.iconset/icon_256x256@2x.png
sips -s format png /tmp/icon_1024x1024.png --out AppIcon.iconset/icon_512x512@2x.png > /dev/null 2>&1

# Create .icns file
echo "Creating .icns file..."
iconutil -c icns AppIcon.iconset -o AppIcon.icns

# Clean up
rm -rf AppIcon.iconset

echo "✓ Icon created: AppIcon.icns"
