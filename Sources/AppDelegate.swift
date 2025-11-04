import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {

    var editWindow: EditWindow?

    // Clipboard monitoring
    private var clipboardTimer: Timer?
    private var lastChangeCount: Int = 0
    private var ignoreNextClipboardChange: Bool = false  // Flag to ignore our own clipboard writes
    private var latestClipboardImage: NSImage?  // Store latest clipboard image

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        print("App starting...")

        // Start as regular dock app
        NSApp.setActivationPolicy(.regular)

        // Get initial clipboard state
        lastChangeCount = NSPasteboard.general.changeCount

        // Start clipboard monitoring (will only be active when minimized)
        startClipboardMonitoring()

        print("App setup complete - clipboard monitoring will activate when minimized")
    }
    
    // MARK: - Clipboard Monitoring

    private func startClipboardMonitoring() {
        // Check clipboard every 0.5 seconds
        clipboardTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.checkClipboard()
        }

        print("Clipboard monitoring timer started")
    }

    private func checkClipboard() {
        let pasteboard = NSPasteboard.general
        let currentChangeCount = pasteboard.changeCount

        // Check if clipboard has changed
        guard currentChangeCount != lastChangeCount else {
            // Uncomment for verbose debugging:
            // print("⏸️ No clipboard change (count: \(currentChangeCount))")
            return
        }

        print("📋 Clipboard changed: \(lastChangeCount) -> \(currentChangeCount)")
        print("📋 ignoreNextClipboardChange: \(ignoreNextClipboardChange)")

        // If we should ignore this change (our own write), skip it
        if ignoreNextClipboardChange {
            print("⏭️ Ignoring clipboard change (our own write)")
            ignoreNextClipboardChange = false
            lastChangeCount = currentChangeCount
            return
        }

        lastChangeCount = currentChangeCount

        // Check if clipboard contains an image
        if let image = NSImage(pasteboard: pasteboard) {
            print("✓ New image detected in clipboard: \(image.size)")
            
            // Check if window is already visible and update it immediately
            if let window = editWindow, window.isVisible && !window.isMiniaturized {
                print("🔄 Auto-updating visible window with new image")
                window.updateImage(image)
                window.makeKeyAndOrderFront(nil)
                NSApp.activate(ignoringOtherApps: true)
            } else {
                // Store the image for later when user clicks dock icon
                latestClipboardImage = image
                print("✓ Image stored - user can restore window from dock to edit")
            }
        } else {
            print("✗ Clipboard changed but no image found")
            // Debug: show what types are available
            print("📋 Available types: \(pasteboard.types ?? [])")
        }
    }

    // Called by EditWindow when it writes to clipboard
    func willWriteToClipboard() {
        print("🚫 App will write to clipboard - ignoring next change")
        ignoreNextClipboardChange = true
    }

    private func showEditWindow(with image: NSImage) {
        print("Showing edit window with image: \(image.size)")

        // Close existing window if any
        editWindow?.close()

        // Create and show edit window directly (no crop view)
        editWindow = EditWindow(image: image)
        editWindow?.editDelegate = self
        editWindow?.makeKeyAndOrderFront(nil)

        // Activate app
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Stop clipboard monitoring
        clipboardTimer?.invalidate()
        clipboardTimer = nil
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // Don't quit when window closes
        return false
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        // When user clicks dock icon, show window with latest clipboard image
        if let image = latestClipboardImage {
            // We have a new clipboard image
            if let window = editWindow {
                // Update existing window with new image
                print("📸 Updating existing window with latest clipboard image: \(image.size)")
                window.updateImage(image)
                window.deminiaturize(nil)
                window.makeKeyAndOrderFront(nil)
            } else {
                // Create new window with the image
                print("📸 Opening new window with latest clipboard image: \(image.size)")
                showEditWindow(with: image)
            }
            latestClipboardImage = nil
        } else if let window = editWindow {
            // No new image, just restore existing window
            print("📸 Restoring existing window (no new clipboard image)")
            window.deminiaturize(nil)
            window.makeKeyAndOrderFront(nil)
        } else {
            // No window exists and no new image - create a new window
            print("📸 No window or clipboard image available")
        }
        return true
    }

}

// MARK: - EditWindowDelegate
extension AppDelegate: EditWindowDelegate {
    func editWindowDidClose(_ window: EditWindow) {
        print("Edit window closed")
    }

    func editWindowDidShow(_ window: EditWindow) {
        print("Edit window shown")
    }

    func editWindowDidMiniaturize(_ window: EditWindow) {
        print("Edit window miniaturized")
    }

    func editWindowDidDeminiaturize(_ window: EditWindow) {
        print("Edit window deminiaturized")
    }
}
