#!/bin/bash

# Build and run SnippingEdit with proper app bundle (for icon display)

echo "Building SnippingEdit app bundle..."

# Kill any running instance
killall SnippingEdit 2>/dev/null

# Quick build of app bundle
swift build

if [ $? -eq 0 ]; then
    echo "Build successful!"
    
    # Create minimal app bundle structure
    APP_DIR="build/SnippingEdit.app"
    mkdir -p "$APP_DIR/Contents/MacOS"
    mkdir -p "$APP_DIR/Contents/Resources"
    
    # Copy files
    cp .build/debug/SnippingEdit "$APP_DIR/Contents/MacOS/"
    cp Sources/Info.plist "$APP_DIR/Contents/"
    if [ -f "AppIcon.icns" ]; then
        cp AppIcon.icns "$APP_DIR/Contents/Resources/"
    fi
    echo -n "APPL????" > "$APP_DIR/Contents/PkgInfo"
    
    # Make executable
    chmod +x "$APP_DIR/Contents/MacOS/SnippingEdit"
    
    echo ""
    echo "Usage:"
    echo "- The app monitors your clipboard for images"
    echo "- Copy any image to clipboard (Cmd+C or screenshot)"
    echo "- The dock icon will pulse when a new image is detected!"
    echo "- Click the dock icon to open the editor"
    echo "- Use the color buttons to draw annotations"
    echo "- Click 'Clipboard' to copy the edited image"
    echo ""
    echo "Starting application..."
    
    # Open the app bundle
    open "$APP_DIR"
else
    echo "Build failed!"
    exit 1
fi

