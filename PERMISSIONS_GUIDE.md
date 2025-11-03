# Screen Recording Permissions Guide

## Quick Start

Run this single command to build, launch, and set up permissions:

```bash
./setup_and_run.sh
```

This will:
1. Build the app as a proper .app bundle
2. Launch the app
3. Open System Settings to the Screen Recording permissions page

---

## Why Permissions Are Needed

SnippingTool needs **Screen Recording** permission to capture screenshots of your screen. This is a macOS security feature that requires explicit user consent.

---

## How to Grant Permission

### Method 1: Automatic (Easiest)

1. **Build and run the app:**
   ```bash
   ./build_app.sh
   open build/SnippingTool.app
   ```

2. **Try to take a screenshot:**
   - Click the 📷 icon in your menu bar (or dock/corner widget)
   - macOS will show a permission dialog

3. **Grant permission:**
   - Click "Open System Settings"
   - Enable the toggle next to "SnippingTool"
   - Restart the app

### Method 2: Manual

1. **Open System Settings:**
   ```bash
   ./open_permissions.sh
   ```
   Or manually: **System Settings > Privacy & Security > Screen Recording**

2. **Find SnippingTool in the list:**
   - If it's not there, run the app first: `open build/SnippingTool.app`
   - Try taking a screenshot to trigger macOS to add it

3. **Enable the permission:**
   - Toggle the switch next to "SnippingTool"
   - Restart the app if it was running

---

## Troubleshooting

### ❌ App doesn't appear in System Settings

**Problem:** SnippingTool is not listed in Screen Recording permissions.

**Solutions:**
1. Make sure you built using `./build_app.sh` (creates a proper .app bundle)
2. Run the app at least once: `open build/SnippingTool.app`
3. Try taking a screenshot - this triggers macOS to add the app
4. Check if you're looking in the right place: **System Settings > Privacy & Security > Screen Recording**

### ❌ Screenshot capture fails

**Problem:** Black screen or "Failed to capture screenshot" error.

**Solutions:**
1. Check System Settings > Privacy & Security > Screen Recording
2. Make sure SnippingTool is enabled (toggle is ON)
3. Restart the app after granting permission
4. If still failing, try revoking and re-granting permission

### ❌ Permission dialog doesn't appear

**Problem:** macOS doesn't show the permission prompt.

**Solutions:**
1. The app must be a proper .app bundle - use `./build_app.sh`
2. Running `.build/debug/SnippingTool` directly may not trigger the prompt
3. Try manually opening System Settings: `./open_permissions.sh`

### ❌ App crashes when taking screenshot

**Problem:** App crashes with "message sent to deallocated instance" error.

**Solution:** This has been fixed in the latest version. Rebuild:
```bash
./build_app.sh
```

---

## Technical Details

### Info.plist Configuration

The app includes the required permission key in `Sources/Info.plist`:

```xml
<key>NSScreenCaptureUsageDescription</key>
<string>SnippingTool needs permission to capture your screen to take screenshots. This allows you to select and annotate areas of your screen.</string>
```

### Bundle Identifier

The app uses the bundle identifier: `com.chartnexus.SnippingTool`

This is how macOS identifies the app in System Settings.

### App Bundle Structure

```
build/SnippingTool.app/
├── Contents/
│   ├── Info.plist          # Contains permission descriptions
│   ├── PkgInfo             # App type identifier
│   ├── MacOS/
│   │   └── SnippingTool    # Executable
│   └── Resources/          # (empty for now)
```

---

## Verification

To verify the app is properly configured:

```bash
# Check if Info.plist contains the permission key
plutil -p build/SnippingTool.app/Contents/Info.plist | grep NSScreenCapture

# Expected output:
# "NSScreenCaptureUsageDescription" => "SnippingTool needs permission..."
```

---

## Additional Resources

- [Apple Documentation: Requesting Permission to Capture Screen Content](https://developer.apple.com/documentation/avfoundation/capture_setup/requesting_authorization_to_capture_and_save_media)
- [macOS Privacy Settings](https://support.apple.com/guide/mac-help/control-access-to-screen-recording-mchld6aa7d23/mac)

---

## Quick Commands Reference

| Command | Description |
|---------|-------------|
| `./setup_and_run.sh` | Build, launch, and open permissions (all-in-one) |
| `./build_app.sh` | Build the .app bundle |
| `open build/SnippingTool.app` | Launch the app |
| `./open_permissions.sh` | Open System Settings to Screen Recording |
| `swift build` | Build executable only (no .app bundle) |

---

**Note:** Always use `./build_app.sh` to create a proper .app bundle. This ensures the app appears correctly in System Settings and can request permissions properly.

