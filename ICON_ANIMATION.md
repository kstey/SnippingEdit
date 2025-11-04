# Icon Animation Feature

The SnippingEdit app includes a dynamic dock icon that provides visual feedback when clipboard changes are detected.

## Features

- **Clipboard-themed icon**: The app icon features a clipboard with an image, representing the app's core functionality
- **Animated feedback**: When a new image is detected in the clipboard, the dock icon animates with a pulsing glow effect for 2 seconds
- **Visual confirmation**: The animation provides immediate visual feedback that the app has detected and captured a new clipboard image

## Icon Animation Behavior

When the app detects a new image in the clipboard:
1. The dock icon begins pulsing with a bright blue glow
2. The animation lasts for 2 seconds with multiple pulse cycles that gradually fade
3. After 2 seconds, the icon returns to its normal state

This visual feedback is especially useful when working with AI tools, as it confirms that your screenshot or image has been captured and is ready for editing.

## Generating the Icon

To regenerate the app icon:

```bash
./generate_icon.sh
```

This will:
1. Run the icon generation script
2. Create PNG files at multiple resolutions
3. Build an .icns file suitable for macOS
4. Place the icon in the project root as `AppIcon.icns`

The icon will be automatically included when you build the app using `./build_app.sh`.
