#!/bin/bash

# Build script for SnippingEdit macOS app

echo "Building SnippingEdit..."

# Check if Xcode command line tools are installed
if ! command -v xcodebuild &> /dev/null; then
    echo "Error: Xcode command line tools not found. Please install Xcode."
    exit 1
fi

# Build the project
xcodebuild -project SnippingTool.xcodeproj -scheme SnippingEdit -configuration Release build

if [ $? -eq 0 ]; then
    echo "Build successful!"
    echo "The app is located at: build/Release/SnippingEdit.app"
    echo ""
    echo "To install the app:"
    echo "1. Copy SnippingEdit.app to your Applications folder"
    echo "2. Launch it from Applications or Spotlight"
    echo "3. The app will appear in your menu bar with a camera icon"
    echo ""
    echo "Usage:"
    echo "- Click the camera icon in the menu bar to take a screenshot"
    echo "- Drag to select the area you want to capture"
    echo "- Use the color buttons to draw on the screenshot"
    echo "- Click 'Clipboard' to copy the annotated image"
    echo "- Press Escape to cancel at any time"
else
    echo "Build failed!"
    exit 1
fi
