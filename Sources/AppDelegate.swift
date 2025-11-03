import Cocoa
import AVFoundation

class AppDelegate: NSObject, NSApplicationDelegate {
    
    var statusItem: NSStatusItem?
    var screenshotWindow: ScreenshotWindow?
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        print("App starting...")

        // Create status bar item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem?.button {
            // Use a more visible text-based icon
            button.title = "📷"
            button.font = NSFont.systemFont(ofSize: 16)
            print("Using emoji camera icon in menu bar")

            button.action = #selector(takeScreenshot)
            button.target = self

            // Add right-click menu
            let menu = NSMenu()
            menu.addItem(NSMenuItem(title: "Take Screenshot", action: #selector(takeScreenshot), keyEquivalent: ""))
            menu.addItem(NSMenuItem.separator())
            menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
            statusItem?.menu = menu

            print("Status bar item created successfully")
        } else {
            print("Failed to create status bar button")
        }

        // Keep dock icon visible initially so user can see the app is running
        NSApp.setActivationPolicy(.regular)

        // Force the status item to be visible and configure it properly
        statusItem?.isVisible = true
        statusItem?.behavior = [.removalAllowed, .terminationOnRemoval]

        // Double-check the button is configured
        if let button = statusItem?.button {
            button.appearsDisabled = false
            button.isEnabled = true
            print("Menu bar button configured: title='\(button.title)', enabled=\(button.isEnabled)")
        }

        print("App setup complete - check your menu bar for the camera icon")
        print("You should see both:")
        print("1. SnippingEdit in the Dock (which you can see)")
        print("2. A camera icon in the menu bar (top-right of screen)")

        // Check permissions and show appropriate message after a longer delay
        // This ensures the menu bar icon appears first
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.checkScreenRecordingPermission()
        }
    }
    
    @objc func takeScreenshot() {
        // Check permissions before taking screenshot
        if !hasScreenRecordingPermission() {
            showPermissionAlert()
            return
        }

        // Show dock icon when taking screenshot
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)

        // Capture screenshot of all screens
        let displayID = CGMainDisplayID()
        guard let image = CGDisplayCreateImage(displayID) else {
            print("Failed to capture screenshot - this usually means missing permissions")
            showPermissionAlert()
            return
        }

        // Convert to NSImage
        let nsImage = NSImage(cgImage: image, size: NSSize(width: CGFloat(image.width), height: CGFloat(image.height)))

        // Create and show screenshot window
        screenshotWindow = ScreenshotWindow(screenshot: nsImage)
        screenshotWindow?.makeKeyAndOrderFront(nil)
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Clean up
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // Hide dock icon when no windows are open
        NSApp.setActivationPolicy(.accessory)
        return false
    }

    // MARK: - Permission Checking

    func hasScreenRecordingPermission() -> Bool {
        // Try to create a small screenshot to test permissions
        let displayID = CGMainDisplayID()
        guard let image = CGDisplayCreateImage(displayID) else {
            return false
        }

        // If we can create an image, we have permission
        return image.width > 0 && image.height > 0
    }

    func checkScreenRecordingPermission() {
        if hasScreenRecordingPermission() {
            showReadyAlert()
        } else {
            showPermissionAlert()
        }
    }

    func showReadyAlert() {
        let alert = NSAlert()
        alert.messageText = "SnippingEdit is Ready! 🎉"
        alert.informativeText = "✅ Screen recording permission granted\n\n📷 Click the camera icon in your menu bar to take screenshots\n🎨 Draw annotations with multiple colors\n📋 Copy to clipboard with one click"
        alert.addButton(withTitle: "Got it!")
        alert.runModal()
    }

    func showPermissionAlert() {
        let alert = NSAlert()
        alert.messageText = "Screen Recording Permission Required"
        alert.informativeText = "SnippingEdit needs permission to capture your screen.\n\n1. Click 'Open System Preferences' below\n2. Find 'SnippingEdit' in the list\n3. Check the box next to it\n4. Try taking a screenshot again"
        alert.addButton(withTitle: "Open System Preferences")
        alert.addButton(withTitle: "Cancel")

        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            openScreenRecordingPreferences()
        }
    }

    func openScreenRecordingPreferences() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture")!
        NSWorkspace.shared.open(url)
    }
}
