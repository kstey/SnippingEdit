#!/bin/bash

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
APP_NAME="SnippingEdit.app"
APP_DIR="build/$APP_NAME"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"
DIST_DIR="build/SnippingEdit-Distribution"

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  Building SnippingEdit for macOS${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Step 1: Build the Swift package
echo -e "${YELLOW}[1/7]${NC} Building Swift package..."
swift build

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Build failed!${NC}"
    exit 1
fi
echo -e "${GREEN}✓${NC} Swift build complete"
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
cp .build/debug/SnippingEdit "$MACOS_DIR/"
echo -e "${GREEN}✓${NC} Executable copied"
echo ""

# Step 4: Copy Info.plist
echo -e "${YELLOW}[4/7]${NC} Copying Info.plist..."
cp Sources/Info.plist "$CONTENTS_DIR/"
echo -e "${GREEN}✓${NC} Info.plist copied"
echo ""

# Step 4.5: Copy app icon
echo -e "${YELLOW}[4.5/7]${NC} Copying app icon..."
if [ -f "AppIcon.icns" ]; then
    cp AppIcon.icns "$RESOURCES_DIR/"
    echo -e "${GREEN}✓${NC} App icon copied"
else
    echo -e "${YELLOW}⚠${NC}  AppIcon.icns not found, skipping (app will use default icon)"
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
2. Grant Screen Recording permission when prompted
3. Click the camera icon in menu bar to take screenshots

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
• Instant selection with memory
• 8 resize handles (corners + edges)
• Real-time dimension display
• Capture and Cancel buttons
• 8-color annotation palette
• One-click clipboard copy
• Keyboard shortcuts

REQUIREMENTS
------------
• macOS 14.0 or later
• Screen Recording permission

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
echo -e "${GREEN}✅ Build Complete!${NC}"
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
echo -e "${GREEN}🔐 Screen Recording Permission:${NC}"
echo "   1. Run the app"
echo "   2. Try to take a screenshot"
echo "   3. Grant permission when prompted"
echo "   4. Or: System Settings > Privacy & Security > Screen Recording"
echo ""

