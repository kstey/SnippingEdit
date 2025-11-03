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
        guard let image = CGDisplayCreateImage(displayID) else {
            print("Failed to capture screenshot")
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
}
