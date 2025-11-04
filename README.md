# SnippingEdit for macOS

A screenshot and annotation tool for macOS with instant selection memory and drawing capabilities.

![macOS](https://img.shields.io/badge/macOS-14.0+-blue.svg)
![Swift](https://img.shields.io/badge/Swift-5.9+-orange.svg)

## Requirements

- macOS 14.0 or later
- Swift 5.9 or later

## Building the Application

### Debug Build

Build and run for development/testing:

```bash
# Build debug version
swift build

# Run the debug executable
./.build/debug/SnippingEdit
```

Or use the convenience script:

```bash
./run.sh
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

- **Instant selection** - Remembers your last selection area
- **8 resize handles** - Corners and edges for precise adjustments
- **Real-time dimensions** - Shows exact pixel size while resizing
- **Annotation tools** - 8-color palette for drawing
- **Keyboard shortcuts** - Enter to confirm, Escape to cancel, Delete to undo
- **Clipboard integration** - One-click copy with annotations

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

