# Build Guide for SnippingEdit

## Quick Build Commands

### Release Build (Production)
```bash
./build_app.sh release
# or simply:
./build_app.sh
```
**Use for:** Distribution, final releases, performance testing
- Optimized for speed and size
- No debug symbols
- Smaller binary (~152K)

### Debug Build (Development)
```bash
./build_app.sh debug
```
**Use for:** Development, debugging, testing
- Includes debug symbols
- Faster compile time
- Larger binary (~321K)

## Build Output

Both builds create the same structure:
```
build/
├── SnippingEdit.app                    # Ready-to-run app
├── SnippingEdit-Distribution/          # Distribution folder
│   ├── SnippingEdit.app
│   ├── FIX_IF_DAMAGED.sh               # Gatekeeper fix script
│   ├── README.txt                      # User guide
│   └── GATEKEEPER_FIX.md              # Detailed troubleshooting
└── SnippingEdit-Distribution.zip       # Ready to share
```

## Binary Comparison

| Build Type | Size  | Speed | Debug Info | Use Case |
|------------|-------|-------|------------|----------|
| Debug      | ~321K | Fast build | ✅ Yes | Development |
| Release    | ~152K | Optimized  | ❌ No  | Production |

## Common Workflows

### Development Cycle
```bash
# Quick iteration during development
./build_app.sh debug
open build/SnippingEdit.app
```

### Pre-Release Testing
```bash
# Test the optimized build before distribution
./build_app.sh release
open build/SnippingEdit.app
```

### Distribution
```bash
# Create optimized build
./build_app.sh release

# Share the ZIP file
# File location: build/SnippingEdit-Distribution.zip
```

## What the Build Script Does

1. **Compiles** Swift code (debug or release mode)
2. **Creates** `.app` bundle structure
3. **Copies** executable, Info.plist, and app icon (AppIcon.icns)
4. **Sets** proper permissions and removes quarantine
5. **Creates** distribution package with helper scripts
6. **Generates** ZIP archive for easy sharing

### Icon Handling
The build script automatically locates and copies `AppIcon.icns` from:
1. SPM resource bundle (primary location)
2. Project root directory
3. Sources directory

The icon must be named `AppIcon.icns` and the app will show a custom icon instead of the generic terminal icon.

## Troubleshooting

### Build Fails
```bash
# Clean build artifacts and try again
rm -rf .build build
./build_app.sh release
```

### App Won't Open
```bash
# Remove quarantine (for downloaded apps)
xattr -cr build/SnippingEdit.app
chmod +x build/SnippingEdit.app/Contents/MacOS/SnippingEdit
```

### Need More Info
```bash
# Check build details
swift build --help
```

## Tips

- **Default:** Running `./build_app.sh` without arguments builds in **release** mode
- **Clean builds:** Delete `.build` and `build` folders before building
- **Faster debug:** Debug mode compiles ~30x faster than release
- **Distribution:** Always use release builds for distribution
