import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    
    var statusItem: NSStatusItem?
    var screenshotWindow: ScreenshotWindow?
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Create status bar item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "camera.viewfinder", accessibilityDescription: "Screenshot")
            button.action = #selector(takeScreenshot)
            button.target = self
        }
        
        // Hide dock icon initially - user can launch from status bar
        NSApp.setActivationPolicy(.accessory)
    }
    
    @objc func takeScreenshot() {
        // Show dock icon when taking screenshot
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        
        // Capture screenshot of all screens
        let displayID = CGMainDisplayID()
        guard let cgImage = CGDisplayCreateImage(displayID) else {
            print("Failed to capture screenshot")
            return
        }
        
        // Convert to NSImage with proper coordinate handling
        let nsImage = createNSImage(from: cgImage)
        
        // Create and show screenshot window
        screenshotWindow = ScreenshotWindow(screenshot: nsImage)
        screenshotWindow?.makeKeyAndOrderFront(nil)
    }
    
    private func createNSImage(from cgImage: CGImage) -> NSImage {
        let width = cgImage.width
        let height = cgImage.height
        
        // Create NSImage with proper bitmap representation
        let nsImage = NSImage(size: NSSize(width: width, height: height))
        nsImage.lockFocus()
        
        if let context = NSGraphicsContext.current?.cgContext {
            // Draw the CGImage into the context
            context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        }
        
        nsImage.unlockFocus()
        return nsImage
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Clean up
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // Hide dock icon when no windows are open
        NSApp.setActivationPolicy(.accessory)
        return false
    }
}
