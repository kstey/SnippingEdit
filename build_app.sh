#!/bin/bash

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default to release mode
BUILD_MODE="${1:-release}"

# Validate build mode
if [[ "$BUILD_MODE" != "debug" && "$BUILD_MODE" != "release" ]]; then
    echo -e "${RED}❌ Invalid build mode: $BUILD_MODE${NC}"
    echo ""
    echo "Usage: $0 [debug|release]"
    echo "  debug   - Build with debug symbols (faster build, larger binary)"
    echo "  release - Build optimized for production (default)"
    echo ""
    exit 1
fi

# Configuration
APP_NAME="SnippingEdit.app"
APP_DIR="build/$APP_NAME"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"
DIST_DIR="build/SnippingEdit-Distribution"

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  Building SnippingEdit for macOS${NC}"
echo -e "${BLUE}  Mode: ${YELLOW}${BUILD_MODE}${BLUE}${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Step 1: Build the Swift package
echo -e "${YELLOW}[1/7]${NC} Building Swift package in ${BUILD_MODE} mode..."
if [ "$BUILD_MODE" == "release" ]; then
    swift build -c release
else
    swift build
fi

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Build failed!${NC}"
    exit 1
fi
echo -e "${GREEN}✓${NC} Swift build complete (${BUILD_MODE})"
echo ""

# Step 2: Create .app bundle structure
echo -e "${YELLOW}[2/7]${NC} Creating app bundle structure..."
rm -rf build
mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"
echo -e "${GREEN}✓${NC} Bundle structure created"
echo ""

# Step 3: Copy the executable
echo -e "${YELLOW}[3/7]${NC} Copying executable..."
cp ".build/${BUILD_MODE}/SnippingEdit" "$MACOS_DIR/"
echo -e "${GREEN}✓${NC} Executable copied (${BUILD_MODE})"
echo ""

# Step 4: Copy Info.plist
echo -e "${YELLOW}[4/7]${NC} Copying Info.plist..."
cp Sources/Info.plist "$CONTENTS_DIR/"
echo -e "${GREEN}✓${NC} Info.plist copied"
echo ""

# Step 4.5: Copy app icon
echo -e "${YELLOW}[4.5/7]${NC} Copying app icon..."

# Check multiple possible locations for the icon
ICON_FOUND=false

# Try SPM resource bundle location first (most likely)
SPM_BUNDLE="arm64-apple-macosx/${BUILD_MODE}/SnippingEdit_SnippingEdit.bundle"
if [ -f "$SPM_BUNDLE/AppIcon.icns" ]; then
    cp "$SPM_BUNDLE/AppIcon.icns" "$RESOURCES_DIR/"
    echo -e "${GREEN}✓${NC} App icon copied from SPM bundle"
    ICON_FOUND=true
# Try root directory
elif [ -f "AppIcon.icns" ]; then
    cp AppIcon.icns "$RESOURCES_DIR/"
    echo -e "${GREEN}✓${NC} App icon copied from root"
    ICON_FOUND=true
# Try Sources directory
elif [ -f "Sources/AppIcon.icns" ]; then
    cp Sources/AppIcon.icns "$RESOURCES_DIR/"
    echo -e "${GREEN}✓${NC} App icon copied from Sources"
    ICON_FOUND=true
fi

if [ "$ICON_FOUND" = false ]; then
    echo -e "${YELLOW}⚠${NC}  AppIcon.icns not found in any location"
    echo "     The app will display with a generic terminal icon."
    echo "     Searched: $SPM_BUNDLE, root, and Sources/"
fi
echo ""

# Step 5: Create PkgInfo file
echo -e "${YELLOW}[5/7]${NC} Creating PkgInfo..."
echo -n "APPL????" > "$CONTENTS_DIR/PkgInfo"
echo -e "${GREEN}✓${NC} PkgInfo created"
echo ""

# Step 6: Apply Gatekeeper fixes
echo -e "${YELLOW}[6/7]${NC} Applying Gatekeeper fixes..."

# Remove all extended attributes (quarantine, etc.)
echo "  → Removing quarantine attributes..."
xattr -cr "$APP_DIR" 2>/dev/null || true

# Make executable actually executable
echo "  → Setting executable permissions..."
chmod +x "$MACOS_DIR/SnippingEdit"

# Set proper permissions for the entire bundle
echo "  → Setting bundle permissions..."
chmod -R u+rw "$APP_DIR"
chmod -R go+r "$APP_DIR"
chmod +x "$APP_DIR"
chmod +x "$CONTENTS_DIR"

# Remove any .DS_Store files
find "$APP_DIR" -name ".DS_Store" -delete 2>/dev/null || true

echo -e "${GREEN}✓${NC} Gatekeeper fixes applied"
echo ""

# Step 7: Create distribution package
echo -e "${YELLOW}[7/7]${NC} Creating distribution package..."
mkdir -p "$DIST_DIR"

# Copy the app
cp -R "$APP_DIR" "$DIST_DIR/"

# Create fix script in distribution
cat > "$DIST_DIR/FIX_IF_DAMAGED.sh" << 'FIXSCRIPT'
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
FIXSCRIPT

chmod +x "$DIST_DIR/FIX_IF_DAMAGED.sh"

# Create README for distribution
cat > "$DIST_DIR/README.txt" << 'README'
SnippingEdit for macOS
======================

A professional screenshot and annotation tool with instant selection,
resize handles, and smart capture features.

QUICK START
-----------
1. Double-click SnippingEdit.app to launch
2. Minimize the app to dock
3. Copy any image to clipboard (e.g., Cmd+Shift+4 + Control)
4. Click dock icon to open and edit the image

IF APP WON'T OPEN ("damaged" error)
------------------------------------
This is a macOS security feature for unsigned apps.

Quick Fix:
  1. Open Terminal (Applications > Utilities > Terminal)
  2. Type: cd
  3. Drag this folder into Terminal window
  4. Press Enter
  5. Type: ./FIX_IF_DAMAGED.sh
  6. Press Enter
  7. Try opening the app again

Alternative Fix:
  - Right-click SnippingEdit.app
  - Select "Open"
  - Click "Open" in the dialog

FEATURES
--------
• Automatic clipboard monitoring
• Image editing and annotation
• 8-color drawing palette
• One-click clipboard copy
• Keyboard shortcuts (Delete to undo, Cmd+R to clear)

REQUIREMENTS
------------
• macOS 14.0 or later
• No special permissions required (clipboard access only)

SUPPORT
-------
For issues or questions, see GATEKEEPER_FIX.md
or visit the project repository.

Enjoy! 🎉
README

# Copy documentation
cp GATEKEEPER_FIX.md "$DIST_DIR/" 2>/dev/null || echo "Note: GATEKEEPER_FIX.md not found, skipping"

# Create a ZIP for easy distribution
echo "  → Creating ZIP archive..."
cd build
zip -r -q SnippingEdit-Distribution.zip SnippingEdit-Distribution
cd ..

echo -e "${GREEN}✓${NC} Distribution package created"
echo ""

# Final summary
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✅ Build Complete! (${BUILD_MODE} mode)${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${GREEN}📦 App Location:${NC}"
echo "   $APP_DIR"
echo ""
echo -e "${GREEN}📦 Distribution Package:${NC}"
echo "   $DIST_DIR/"
echo "   build/SnippingEdit-Distribution.zip"
echo ""
echo -e "${GREEN}🚀 To Run Locally:${NC}"
echo "   open $APP_DIR"
echo ""
echo -e "${GREEN}📤 To Share:${NC}"
echo "   1. Share: build/SnippingEdit-Distribution.zip"
echo "   2. Recipients run: ./FIX_IF_DAMAGED.sh (if needed)"
echo ""
echo -e "${YELLOW}⚠️  Gatekeeper Protection:${NC}"
echo "   • App is NOT code-signed (requires Apple Developer account)"
echo "   • Recipients may see \"damaged\" error when downloaded"
echo "   • FIX_IF_DAMAGED.sh script included in distribution"
echo "   • See GATEKEEPER_FIX.md for detailed solutions"
echo ""
echo -e "${BLUE}Build Info:${NC}"
echo "   Build Mode: ${BUILD_MODE}"
echo "   Binary: .build/${BUILD_MODE}/SnippingEdit"
if [ "$BUILD_MODE" == "release" ]; then
    echo "   Optimizations: Enabled"
else
    echo "   Debug Symbols: Included"
fi
echo ""
