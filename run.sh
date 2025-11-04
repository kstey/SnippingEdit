#!/bin/bash

# Build and run SnippingEdit

echo "Building SnippingEdit..."
swift build

if [ $? -eq 0 ]; then
    echo "Build successful! Starting SnippingEdit..."
    echo ""
    echo "Usage:"
    echo "- The app monitors your clipboard for images"
    echo "- Copy any image to clipboard (Cmd+C or screenshot)"
    echo "- Click the dock icon to open the editor"
    echo "- Use the color buttons to draw annotations"
    echo "- Click 'Clipboard' to copy the edited image"
    echo ""
    echo "Starting application..."

    # Run the built executable
    ./.build/debug/SnippingEdit
else
    echo "Build failed!"
    exit 1
fi
