import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {

    var editWindow: EditWindow?

    // Clipboard monitoring
    private var clipboardTimer: Timer?
    private var lastChangeCount: Int = 0
    private var ignoreNextClipboardChange: Bool = false  // Flag to ignore our own clipboard writes
    private var latestClipboardImage: NSImage?  // Store latest clipboard image
    
    // Icon animation
    private var iconAnimationTimer: Timer?
    private var animationStartTime: Date?
    private let animationDuration: TimeInterval = 2.0
    private var originalDockIcon: NSImage?

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        print("App starting...")

        // Start as regular dock app
        NSApp.setActivationPolicy(.regular)
        
        // Store original dock icon
        originalDockIcon = NSApp.applicationIconImage

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
            
            // Animate dock icon for 2 seconds
            startIconAnimation()
            
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
    
    // MARK: - Icon Animation
    
    private func startIconAnimation() {
        // Stop any existing animation
        stopIconAnimation()
        
        // Start animation
        animationStartTime = Date()
        iconAnimationTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            self?.updateIconAnimation()
        }
        
        print("🎬 Started dock icon animation")
    }
    
    private func updateIconAnimation() {
        guard let startTime = animationStartTime else {
            stopIconAnimation()
            return
        }
        
        let elapsed = Date().timeIntervalSince(startTime)
        
        // Stop after duration
        if elapsed >= animationDuration {
            stopIconAnimation()
            return
        }
        
        // Calculate pulse intensity (0.0 to 1.0 and back)
        // Creates a smooth pulse effect
        let progress = elapsed / animationDuration
        let pulseIntensity = sin(progress * .pi * 4) * (1.0 - progress)  // Multiple pulses that fade
        
        // Create animated icon
        let animatedIcon = createAnimatedIcon(pulseIntensity: CGFloat(max(0, pulseIntensity)))
        NSApp.applicationIconImage = animatedIcon
    }
    
    private func stopIconAnimation() {
        iconAnimationTimer?.invalidate()
        iconAnimationTimer = nil
        animationStartTime = nil
        
        // Restore original icon
        if let original = originalDockIcon {
            NSApp.applicationIconImage = original
        }
        
        print("🎬 Stopped dock icon animation")
    }
    
    private func createAnimatedIcon(pulseIntensity: CGFloat) -> NSImage {
        let size = CGSize(width: 512, height: 512)
        let image = NSImage(size: size)
        image.lockFocus()
        
        // Background with pulse glow
        let rect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        let cornerRadius = size.width * 0.2
        let path = NSBezierPath(roundedRect: rect, xRadius: cornerRadius, yRadius: cornerRadius)
        
        // Brighter gradient during pulse
        let brightness = 1.0 + pulseIntensity * 0.4
        let gradient = NSGradient(colors: [
            NSColor(red: 0.2 * brightness, green: 0.7 * brightness, blue: 0.9 * brightness, alpha: 1.0),
            NSColor(red: 0.3 * brightness, green: 0.5 * brightness, blue: 1.0 * brightness, alpha: 1.0)
        ])
        gradient?.draw(in: path, angle: 135)
        
        // Add glow effect during pulse
        if pulseIntensity > 0.1 {
            let ctx = NSGraphicsContext.current!.cgContext
            ctx.saveGState()
            ctx.setShadow(offset: .zero, blur: 30 * pulseIntensity,
                          color: NSColor(red: 0.3, green: 0.7, blue: 1.0, alpha: pulseIntensity * 0.8).cgColor)
            path.fill()
            ctx.restoreGState()
        }
        
        // Clipboard body
        NSColor.white.setFill()
        let clipboardWidth = size.width * 0.65
        let clipboardHeight = size.height * 0.7
        let clipboardX = (size.width - clipboardWidth) / 2
        let clipboardY = (size.height - clipboardHeight) / 2 - size.height * 0.05
        
        let clipboardBody = NSBezierPath(roundedRect: CGRect(x: clipboardX, y: clipboardY,
                                                               width: clipboardWidth, height: clipboardHeight),
                                         xRadius: size.width * 0.04, yRadius: size.width * 0.04)
        clipboardBody.fill()
        
        // Clipboard clip
        NSColor(white: 0.3, alpha: 1.0).setFill()
        let clipWidth = size.width * 0.25
        let clipHeight = size.height * 0.08
        let clipX = (size.width - clipWidth) / 2
        let clipY = clipboardY + clipboardHeight - clipHeight * 0.3
        
        let clip = NSBezierPath(roundedRect: CGRect(x: clipX, y: clipY,
                                                      width: clipWidth, height: clipHeight),
                                xRadius: size.width * 0.02, yRadius: size.width * 0.02)
        clip.fill()
        
        // Image on clipboard
        let imageWidth = clipboardWidth * 0.7
        let imageHeight = clipboardHeight * 0.5
        let imageX = clipboardX + (clipboardWidth - imageWidth) / 2
        let imageY = clipboardY + (clipboardHeight - imageHeight) / 2 - size.height * 0.03
        
        NSColor(red: 0.7, green: 0.85, blue: 1.0, alpha: 1.0).setFill()
        let imageRect = NSBezierPath(rect: CGRect(x: imageX, y: imageY,
                                                   width: imageWidth, height: imageHeight))
        imageRect.fill()
        
        // Mountain
        NSColor(red: 0.4, green: 0.6, blue: 0.9, alpha: 1.0).setFill()
        let mountain = NSBezierPath()
        mountain.move(to: CGPoint(x: imageX, y: imageY))
        mountain.line(to: CGPoint(x: imageX + imageWidth * 0.4, y: imageY + imageHeight * 0.6))
        mountain.line(to: CGPoint(x: imageX + imageWidth * 0.7, y: imageY))
        mountain.close()
        mountain.fill()
        
        // Sun
        NSColor(red: 1.0, green: 0.9, blue: 0.3, alpha: 1.0).setFill()
        let sunSize = imageWidth * 0.2
        let sunX = imageX + imageWidth - sunSize - imageWidth * 0.1
        let sunY = imageY + imageHeight - sunSize - imageHeight * 0.1
        let sun = NSBezierPath(ovalIn: CGRect(x: sunX, y: sunY, width: sunSize, height: sunSize))
        sun.fill()
        
        // Target/crosshair overlay (centered on image area)
        let targetSize = min(imageWidth, imageHeight) * 0.5
        let targetX = imageX + (imageWidth - targetSize) / 2
        let targetY = imageY + (imageHeight - targetSize) / 2
        
        // Outer circle (red/orange with pulse)
        let targetBrightness = 1.0 + pulseIntensity * 0.2
        NSColor(red: 1.0 * targetBrightness, green: 0.3, blue: 0.2, alpha: 0.8).setStroke()
        let outerCircle = NSBezierPath(ovalIn: CGRect(x: targetX, y: targetY, 
                                                        width: targetSize, height: targetSize))
        outerCircle.lineWidth = size.width * 0.012
        outerCircle.stroke()
        
        // Inner circle
        let innerSize = targetSize * 0.6
        let innerX = targetX + (targetSize - innerSize) / 2
        let innerY = targetY + (targetSize - innerSize) / 2
        let innerCircle = NSBezierPath(ovalIn: CGRect(x: innerX, y: innerY, 
                                                        width: innerSize, height: innerSize))
        innerCircle.lineWidth = size.width * 0.008
        innerCircle.stroke()
        
        // Crosshair lines
        let centerX = targetX + targetSize / 2
        let centerY = targetY + targetSize / 2
        let crosshairLength = targetSize * 0.15
        
        // Horizontal line
        let hLine = NSBezierPath()
        hLine.move(to: CGPoint(x: centerX - crosshairLength, y: centerY))
        hLine.line(to: CGPoint(x: centerX + crosshairLength, y: centerY))
        hLine.lineWidth = size.width * 0.01
        hLine.stroke()
        
        // Vertical line
        let vLine = NSBezierPath()
        vLine.move(to: CGPoint(x: centerX, y: centerY - crosshairLength))
        vLine.line(to: CGPoint(x: centerX, y: centerY + crosshairLength))
        vLine.lineWidth = size.width * 0.01
        vLine.stroke()
        
        // Center dot
        NSColor(red: 1.0 * targetBrightness, green: 0.3, blue: 0.2, alpha: 0.9).setFill()
        let dotSize = size.width * 0.015
        let dot = NSBezierPath(ovalIn: CGRect(x: centerX - dotSize/2, y: centerY - dotSize/2,
                                               width: dotSize, height: dotSize))
        dot.fill()
        
        image.unlockFocus()
        return image
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Stop icon animation
        stopIconAnimation()
        
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
