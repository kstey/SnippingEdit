#!/bin/bash

# Build and run the SnippingEdit

echo "Building SnippingEdit..."
swift build

if [ $? -eq 0 ]; then
    echo "Build successful! Starting SnippingEdit..."
    echo ""
    echo "Usage:"
    echo "- The app will appear in your menu bar with a camera icon"
    echo "- Click the camera icon to take a screenshot"
    echo "- Drag to select the area you want to capture"
    echo "- Use the color buttons to draw on the screenshot"
    echo "- Click 'Clipboard' to copy the annotated image"
    echo "- Press Escape to cancel at any time"
    echo ""
    echo "Starting application..."
    
    # Run the built executable
    ./.build/debug/SnippingEdit
else
    echo "Build failed!"
    exit 1
fi
