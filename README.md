# SnippingEdit for macOS

A screenshot and annotation tool for macOS with instant selection memory and drawing capabilities. Inspired by Windows Snipping Tool for ease of editing clipboard images during AI-assisted work.

![macOS](https://img.shields.io/badge/macOS-14.0+-blue.svg)
![Swift](https://img.shields.io/badge/Swift-5.9+-orange.svg)

## Download

- Direct link to the latest packaged app (zip):
	- [Download SnippingEdit-Distribution.zip](build/SnippingEdit-Distribution.zip?raw=1)

How to install/run after download:

1) Unzip the file and open `SnippingEdit.app`.
2) If macOS warns the app is “damaged” or “cannot be opened”, run the included script in the unzipped folder:

```bash
./FIX_IF_DAMAGED.sh
```

More details are in `build/SnippingEdit-Distribution/GATEKEEPER_FIX.md`.

Note: The app in this repository isn’t code-signed. The script removes quarantine and sets the proper permissions for local usage.

## App Icon

![SnippingEdit Icon in Dock](images/SnippingEditIcon.png)

*The SnippingEdit icon as it appears in your macOS dock*

## Edit View

![Edit View Sample](images/editView.png)

*Edit view displaying an image detected from clipboard, ready for annotation*

> **Note:** This is an AI-assisted project. The creator has no prior experience in Swift.

## Requirements

- macOS 14.0 or later
- Swift 5.9 or later

## Building the Application

### Debug Build

Build and run for development/testing:

```bash
# Quick build and run with icon support
./run.sh
```

Or manually:

```bash
# Build debug version
swift build

# Run as app bundle (recommended - shows proper icon)
open build/SnippingEdit.app

# Or run executable directly (no icon displayed)
./.build/debug/SnippingEdit
```

### Release Build

Build optimized .app bundle for distribution:

```bash
# Build release .app bundle
./build_app.sh

# Run the app
open build/SnippingEdit.app
```

The release build creates:
- `build/SnippingEdit.app` - The application bundle
- `build/SnippingEdit-Distribution.zip` - Distribution package with fix scripts

## Features

- **Clipboard monitoring** - Automatically detects clipboard image updates and captures them for editing
- **Animated dock icon** - Provides visual feedback with a 2-second pulsing animation when clipboard images are detected
- **Annotation tools** - 8-color palette for drawing on captured images
- **Easy clipboard saving** - One-click save edited images back to clipboard for seamless AI workflow integration
- **Keyboard shortcuts** - Enter to confirm, Escape to cancel, Delete to undo
- **Screenshot capture** - Quickly capture and edit any part of your screen

## Usage

### Configuring macOS Screenshot Tool

To use SnippingEdit with macOS's native screenshot tool, configure it to save screenshots to the clipboard:

1. **Press `⌘ + Shift + 5`** to open the Screenshot toolbar
2. Click on **Options** in the toolbar
3. Under "Save to", select **Clipboard**
4. Close the Screenshot toolbar

Alternatively, you can use:
- **`⌘ + Shift + 4`** - Capture a selection directly to clipboard (after configuring as above)
- **`⌘ + Control + Shift + 4`** - Always captures to clipboard (no configuration needed)

Once configured, any screenshot you take will be automatically detected by SnippingEdit and opened in the edit view for annotation.

## Troubleshooting

### "App is damaged" error (downloaded builds)
```bash
# Remove quarantine attribute
xattr -cr build/SnippingEdit.app
chmod +x build/SnippingEdit.app/Contents/MacOS/SnippingEdit
```

Or use the included fix script:
```bash
./fix_downloaded_app.sh build/SnippingEdit.app
```

## License

This project is provided as-is for educational and personal use.

