import Cocoa

class AppDelegateSimple: NSObject, NSApplicationDelegate {

    var statusItem: NSStatusItem?
    var controlWindow: NSWindow?
    var useMenuBar = true // Default to menu bar
    // Keep a strong reference to the active screenshot window so AppKit doesn't
    // deallocate it prematurely while there are still internal Objective-C
    // references (targets, tracking areas, etc.). Clearing this when the
    // window closes avoids double-release/autorelease crashes.
    var screenshotWindow: ScreenshotWindow?
    private var screenshotWindowWillCloseObserver: NSObjectProtocol?

    private var userInitiatedQuit = false

    // Keep-alive token to prevent automatic termination by the system
    private var keepAliveActivity: NSObjectProtocol?


    // Store the last selection rectangle (in normalized coordinates 0-1)
    var lastSelectionRect: NSRect?

    // Track which mode the app is running in
    enum AppMode {
        case dockIcon
        case menuBar
        case cornerWidget
    }
    var currentMode: AppMode = .menuBar


    func applicationDidFinishLaunching(_ aNotification: Notification) {
        print("App starting...")
        // Strongly prevent auto/sudden termination for the session
        keepAliveActivity = ProcessInfo.processInfo.beginActivity(
            options: [.automaticTerminationDisabled, .suddenTerminationDisabled],
            reason: "Keep SnippingEdit alive until user quits"
        )

        // Prevent the system from auto-terminating or suddenly terminating when no windows
        ProcessInfo.processInfo.disableAutomaticTermination("Keep SnippingEdit in Dock/Corner modes")
        ProcessInfo.processInfo.disableSuddenTermination()

        // Check screen recording permission first
        checkScreenRecordingPermission()

        showModeSelectionDialog()
        print("Setup complete")
    }

    func checkScreenRecordingPermission() {
        // Try to capture a 1x1 pixel to trigger permission dialog if needed
        print("Checking screen recording permission...")

        let displayID = CGMainDisplayID()
        if CGDisplayCreateImage(displayID, rect: CGRect(x: 0, y: 0, width: 1, height: 1)) != nil {
            print("✓ Screen recording permission granted")
        } else {
            print("⚠️ Screen recording permission not granted - dialog will appear now")
        }
    }

    func showModeSelectionDialog() {
        // Ensure app is active and visible
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)

        // Add a small delay to ensure the app is fully loaded
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let alert = NSAlert()
            alert.messageText = "📷 SnippingEdit Setup"
            alert.informativeText = "Your menu bar looks crowded! Choose the best option:\n\n🎯 Dock Icon: Always visible in your dock\n📱 Corner Widget: Small subtle button in bottom-right corner (won't interfere with Stage Manager)\n📷 Menu Bar: Try camera icon in menu bar (might be hidden)"
            alert.addButton(withTitle: "🎯 Dock Icon")
            alert.addButton(withTitle: "📱 Corner Widget")
            alert.addButton(withTitle: "📷 Menu Bar")
            alert.alertStyle = .informational

            // Make sure the alert appears on top
            alert.window.level = .floating

            let response = alert.runModal()

            switch response {
            case .alertFirstButtonReturn:
                self.setupDockIcon()
            case .alertSecondButtonReturn:
                self.setupCornerWidget()
            case .alertThirdButtonReturn:
                self.setupMenuBar()
            default:
                self.requestQuit(nil)
            }
        }
    }

    func setupMenuBar() {
        currentMode = .menuBar

        // Create status bar item with variable length to ensure it shows
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem?.button {
            // Use camera icon instead of text
            button.title = "📷"  // Camera emoji
            button.font = NSFont.systemFont(ofSize: 16)
            button.action = #selector(takeScreenshot)
            button.target = self
            button.isEnabled = true

            // Add a simple menu for right-click
            let menu = NSMenu()
            menu.addItem(NSMenuItem(title: "📷 Take Screenshot", action: #selector(takeScreenshot), keyEquivalent: ""))
            menu.addItem(NSMenuItem.separator())
            menu.addItem(NSMenuItem(title: "Switch to Dock Icon", action: #selector(switchToDockIcon), keyEquivalent: ""))
            menu.addItem(NSMenuItem(title: "Switch to Corner Widget", action: #selector(switchToCornerWidget), keyEquivalent: ""))
            menu.addItem(NSMenuItem.separator())
            let quitItem = NSMenuItem(title: "Quit", action: #selector(requestQuit(_:)), keyEquivalent: "q")
            quitItem.target = self
            menu.addItem(quitItem)
            statusItem?.menu = menu

            print("Status bar item created with camera icon 📷")
        } else {
            print("Failed to create status bar button")
        }

        // Make sure the item is visible
        statusItem?.isVisible = true

        // Keep app running without dock icon for menu bar mode
        NSApp.setActivationPolicy(.accessory)
    }

    func setupFloatingWindow() {
        currentMode = .cornerWidget

        // Remove status bar item if it exists
        if let statusItem = statusItem {
            NSStatusBar.system.removeStatusItem(statusItem)
            self.statusItem = nil
        }

        // Create floating control window
        controlWindow = createControlWindow()
        controlWindow?.makeKeyAndOrderFront(nil)

        // Show dock icon for floating window mode
        NSApp.setActivationPolicy(.regular)
    }

    func setupDockIcon() {
        currentMode = .dockIcon

        print("Setting up dock icon...")

        // Remove status bar item if it exists
        if let statusItem = statusItem {
            NSStatusBar.system.removeStatusItem(statusItem)
            self.statusItem = nil
        }

        // Show app in dock
        NSApp.setActivationPolicy(.regular)

        // Create a simple main window that can be minimized
        let window = NSWindow(
            contentRect: NSRect(x: 100, y: 100, width: 300, height: 150),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )

        window.title = "📷 SnippingEdit"
        window.center()
        window.delegate = self  // Set delegate to handle window close events
        window.isReleasedWhenClosed = false

        let stackView = NSStackView()
        stackView.orientation = .vertical
        stackView.spacing = 20
        stackView.translatesAutoresizingMaskIntoConstraints = false

        let titleLabel = NSTextField(labelWithString: "📷 SnippingEdit Ready!")
        titleLabel.font = NSFont.systemFont(ofSize: 16, weight: .medium)
        titleLabel.alignment = .center

        let button = NSButton(frame: NSRect(x: 0, y: 0, width: 200, height: 40))
        button.title = "Take Screenshot"
        button.bezelStyle = .rounded
        button.target = self
        button.action = #selector(takeScreenshot)

        let instructionLabel = NSTextField(labelWithString: "Click the dock icon anytime to take screenshots!\nYou can minimize this window.")
        instructionLabel.font = NSFont.systemFont(ofSize: 12)
        instructionLabel.alignment = .center
        instructionLabel.maximumNumberOfLines = 2

        stackView.addArrangedSubview(titleLabel)
        stackView.addArrangedSubview(button)
        stackView.addArrangedSubview(instructionLabel)

        window.contentView?.addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: window.contentView!.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: window.contentView!.centerYAnchor),
            stackView.widthAnchor.constraint(lessThanOrEqualTo: window.contentView!.widthAnchor, constant: -40)
        ])

        window.makeKeyAndOrderFront(nil)
        self.controlWindow = window

        print("Dock icon setup complete - app visible in dock!")
    }

    func setupCornerWidget() {
        currentMode = .cornerWidget

        print("Setting up smart corner widget...")

        // Remove status bar item if it exists
        if let statusItem = statusItem {
            NSStatusBar.system.removeStatusItem(statusItem)
            self.statusItem = nil
        }

        // Position in bottom-right corner, away from Stage Manager
        let screenFrame = NSScreen.main!.frame
        let window = NSWindow(
            contentRect: NSRect(x: screenFrame.width - 50, y: 20, width: 40, height: 40),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        window.level = .floating
        window.backgroundColor = NSColor.clear
        window.isOpaque = false
        window.hasShadow = false
        window.ignoresMouseEvents = false
        window.collectionBehavior = [.canJoinAllSpaces, .stationary]
        window.delegate = self  // Set delegate to handle window close events
        window.isReleasedWhenClosed = false

        // Create a simple, small button
        let button = NSButton(frame: NSRect(x: 0, y: 0, width: 40, height: 40))
        button.title = "📷"
        button.font = NSFont.systemFont(ofSize: 16)
        button.bezelStyle = .circular
        button.target = self
        button.action = #selector(takeScreenshot)
        button.isBordered = false

        // Make it subtle and semi-transparent
        button.wantsLayer = true
        button.layer?.backgroundColor = NSColor.black.withAlphaComponent(0.3).cgColor
        button.layer?.cornerRadius = 20
        button.alphaValue = 0.6

        // Add hover effects
        let trackingArea = NSTrackingArea(
            rect: button.bounds,
            options: [.mouseEnteredAndExited, .activeAlways],
            owner: button,
            userInfo: nil
        )
        button.addTrackingArea(trackingArea)

        // Add right-click context menu
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "📷 Take Screenshot", action: #selector(takeScreenshot), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Switch to Dock Icon", action: #selector(switchToDockIcon), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Switch to Menu Bar", action: #selector(switchToMenuBar), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        let quitItem = NSMenuItem(title: "Quit", action: #selector(requestQuit(_:)), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        button.menu = menu

        window.contentView?.addSubview(button)
        window.orderFront(nil)

        self.controlWindow = window

        // Keep app running without dock icon for corner widget
        NSApp.setActivationPolicy(.accessory)

        print("Smart corner widget setup complete - look for small 📷 in bottom-right corner!")
    }

    func createControlWindow() -> NSWindow {
        let window = NSWindow(
            contentRect: NSRect(x: 100, y: 100, width: 250, height: 120),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )

        window.title = "📷 SnippingEdit"
        window.level = .floating
        window.isReleasedWhenClosed = false

        // Create screenshot button
        let screenshotButton = NSButton(frame: NSRect(x: 25, y: 60, width: 200, height: 35))
        screenshotButton.title = "📷 Take Screenshot"
        screenshotButton.bezelStyle = .rounded
        screenshotButton.target = self
        screenshotButton.action = #selector(takeScreenshot)

        // Create switch to menu bar button
        let switchButton = NSButton(frame: NSRect(x: 25, y: 20, width: 200, height: 30))
        switchButton.title = "Switch to Menu Bar"
        switchButton.bezelStyle = .rounded
        switchButton.target = self
        switchButton.action = #selector(switchToMenuBar)

        window.contentView?.addSubview(screenshotButton)
        window.contentView?.addSubview(switchButton)

        // Center the window
        window.center()

        return window
    }

    @objc func switchToMenuBar() {
        useMenuBar = true
        controlWindow?.close()
        controlWindow = nil
        setupMenuBar()
    }

    @objc func switchToFloating() {
        useMenuBar = false
        setupFloatingWindow()
    }

    @objc func switchToDockIcon() {
        controlWindow?.close()
        controlWindow = nil
        setupDockIcon()
    }

    @objc func switchToCornerWidget() {
        controlWindow?.close()
        controlWindow = nil
        setupCornerWidget()
    }

    @objc func requestQuit(_ sender: Any?) {
        print("🔴 requestQuit called! Sender: \(String(describing: sender))")
        userInitiatedQuit = true
        print("🔴 userInitiatedQuit set to true, calling NSApp.terminate")
        NSApp.terminate(sender)
    }



    @objc func takeScreenshot() {
        print("Taking screenshot...")

        // Do not change activation policy here, only ensure Dock stays in Dock mode
        if currentMode == .dockIcon {
            NSApp.setActivationPolicy(.regular)
        }
        NSApp.activate(ignoringOtherApps: true)

        // Ensure no stale close observer from any previous screenshot window
        if let token = screenshotWindowWillCloseObserver {
            NotificationCenter.default.removeObserver(token)
            screenshotWindowWillCloseObserver = nil
        }

        // Clear any existing screenshot window reference
        screenshotWindow = nil

        // Hide/minimize the control window in dock icon mode before taking screenshot
        if currentMode == .dockIcon, let controlWindow = controlWindow {
            print("Minimizing control window before screenshot...")
            controlWindow.miniaturize(nil)

            // Wait a brief moment for the minimize animation to complete
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                self?.captureAndShowScreenshot()
            }
        } else {
            // For other modes, capture immediately
            captureAndShowScreenshot()
        }
    }

    private func captureAndShowScreenshot() {
        // Capture screenshot of all screens
        let displayID = CGMainDisplayID()
        guard let image = CGDisplayCreateImage(displayID) else {
            print("Failed to capture screenshot")

            // Show simple alert about permissions
            let alert = NSAlert()
            alert.messageText = "Permission Required"
            alert.informativeText = "Please grant Screen Recording permission in System Preferences > Security & Privacy > Privacy > Screen Recording"
            alert.runModal()
            return
        }

        print("Screenshot captured successfully")

        // Convert to NSImage
        let nsImage = NSImage(cgImage: image, size: NSSize(width: CGFloat(image.width), height: CGFloat(image.height)))

        // Calculate initial selection rectangle
        let screenFrame = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 1920, height: 1080)
        let initialSelection: NSRect

        if let lastRect = lastSelectionRect {
            // Convert normalized coordinates (0-1) to actual screen coordinates
            initialSelection = NSRect(
                x: lastRect.origin.x * screenFrame.width,
                y: lastRect.origin.y * screenFrame.height,
                width: lastRect.width * screenFrame.width,
                height: lastRect.height * screenFrame.height
            )
        } else {
            // Use full screen with some padding
            let padding: CGFloat = 100
            initialSelection = NSRect(
                x: padding,
                y: padding,
                width: screenFrame.width - padding * 2,
                height: screenFrame.height - padding * 2
            )
        }


        // Create and show screenshot window
        let screenshotWindow = ScreenshotWindow(screenshot: nsImage, initialSelection: initialSelection)
        // Don't set window delegate - it causes crashes during cleanup
        // Only set the screenshot delegate for callbacks
        screenshotWindow.screenshotDelegate = self
        // Replace the reference - ARC will handle cleanup of old window
        self.screenshotWindow = screenshotWindow

        // Observe the window closing to clear our strong reference safely
        screenshotWindowWillCloseObserver = NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification,
            object: screenshotWindow,
            queue: .main
        ) { [weak self] _ in
            guard let self = self else { return }
            print("Screenshot window willClose -> clearing reference")
            
            // Remove observer first to prevent any re-entry
            if let token = self.screenshotWindowWillCloseObserver {
                NotificationCenter.default.removeObserver(token)
                self.screenshotWindowWillCloseObserver = nil
            }
            
            // Clear window reference
            self.screenshotWindow = nil
            
            // Restore app activation policy for current mode with delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                self?.restoreActivationPolicy()
            }
        }

        screenshotWindow.makeKeyAndOrderFront(nil)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        print("🔴 applicationShouldTerminate called, userInitiatedQuit: \(userInitiatedQuit)")

        // Check if this is a user-initiated quit from dock menu or Cmd+Q
        // If there are no screenshot windows open, allow quit
        // If screenshot window is open, only quit if explicitly requested

        if userInitiatedQuit {
            print("🔴 Allowing termination: marked as user initiated")
            userInitiatedQuit = false
            return .terminateNow
        }

        // Allow termination if user clicked Quit from dock menu or pressed Cmd+Q
        // We can detect this by checking if there's no active screenshot editing
        if screenshotWindow == nil || !screenshotWindow!.isVisible {
            print("🔴 Allowing termination: no active screenshot window")
            return .terminateNow
        }

        print("🔴 Blocked termination: screenshot window is active")
        // Don't restore activation policy here - it can cause crashes
        // Just prevent the termination and let the app continue
        return .terminateCancel
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if currentMode == .dockIcon {
            // If an editor window exists and is minimized/hidden, bring it back
            if let w = screenshotWindow {
                if w.isMiniaturized { w.deminiaturize(nil) }
                if !w.isVisible { w.makeKeyAndOrderFront(nil) }
                NSApp.activate(ignoringOtherApps: true)
                return true
            }
            // Otherwise restore Dock Icon mode control window
            restoreActivationPolicy()
            return true
        }
        return false
    }

    func applicationWillTerminate(_ notification: Notification) {
        print("App will terminate - ending keepAliveActivity")
        if let activity = keepAliveActivity {
            ProcessInfo.processInfo.endActivity(activity)
            keepAliveActivity = nil
        }
    }

    func applicationDockMenu(_ sender: NSApplication) -> NSMenu? {
        // Provide a dock menu for when user right-clicks the dock icon
        print("applicationDockMenu called - creating custom dock menu")
        let dockMenu = NSMenu()

        // Add "Quit" option with explicit target and action
        let quitItem = NSMenuItem(title: "Quit", action: #selector(requestQuit(_:)), keyEquivalent: "q")
        quitItem.target = self
        quitItem.isEnabled = true
        dockMenu.addItem(quitItem)

        print("Dock menu created with Quit item, target: \(String(describing: quitItem.target)), action: \(String(describing: quitItem.action))")

        return dockMenu
    }

}

// MARK: - ScreenshotWindowDelegate
extension AppDelegateSimple: ScreenshotWindowDelegate {
    func screenshotWindow(_ window: ScreenshotWindow, didCompleteWithSelection selection: NSRect) {
        // Save the selection in normalized coordinates (0-1) for reuse
        let screenFrame = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 1920, height: 1080)
        lastSelectionRect = NSRect(
            x: selection.origin.x / screenFrame.width,
            y: selection.origin.y / screenFrame.height,
            width: selection.width / screenFrame.width,
            height: selection.height / screenFrame.height
        )
        print("Saved selection: \(lastSelectionRect!)")
    }

    func screenshotWindowGetLastSelection(_ window: ScreenshotWindow) -> NSRect? {
        // Return the last selection in actual screen coordinates
        print("🟠 AppDelegate.screenshotWindowGetLastSelection called")
        print("🟠 lastSelectionRect (normalized): \(String(describing: lastSelectionRect))")
        guard let lastRect = lastSelectionRect else {
            print("🟠 No last selection available")
            return nil
        }

        let screenFrame = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 1920, height: 1080)
        let result = NSRect(
            x: lastRect.origin.x * screenFrame.width,
            y: lastRect.origin.y * screenFrame.height,
            width: lastRect.width * screenFrame.width,
            height: lastRect.height * screenFrame.height
        )
        print("🟠 Returning selection (screen coords): \(result)")
        return result
    }
}

// MARK: - NSWindowDelegate
extension AppDelegateSimple: NSWindowDelegate {
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        // Prevent control window from closing in dock icon or corner widget mode
        if sender === self.controlWindow {
            if currentMode == .dockIcon || currentMode == .cornerWidget {
                print("Control window close prevented - minimizing instead")
                sender.miniaturize(nil)
                return false
            }
        }
        return true
    }

    func windowWillClose(_ notification: Notification) {
        // Only handle control window closing (dock icon or corner widget)
        if let win = notification.object as? NSWindow, win === self.controlWindow {
            print("Control window will close")
            // Don't actually close it in dock icon or corner widget mode
            // This is handled by windowShouldClose
        }
        // Don't handle screenshot window here - no longer using window delegate for it
    }

    // Restore the correct activation policy based on the current mode
    func restoreActivationPolicy() {
        print("Restoring activation policy for mode: \(currentMode)")
        
        // Schedule on next run loop to avoid crashes during window cleanup
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            switch self.currentMode {
            case .dockIcon:
                // Keep dock icon visible and ensure control window exists and is frontmost
                NSApp.setActivationPolicy(.regular)
                if self.controlWindow == nil {
                    print("Control window missing - recreating for dock icon mode")
                    self.setupDockIcon()
                } else {
                    if let controlWindow = self.controlWindow {
                        if controlWindow.isMiniaturized {
                            print("Control window is miniaturized - deminiaturizing")
                            controlWindow.deminiaturize(nil)
                        }
                        if !controlWindow.isVisible {
                            print("Control window not visible - showing it")
                            controlWindow.orderFront(nil)
                        }
                    }
                }
                // Bring app to front to ensure user can click again
                NSApp.activate(ignoringOtherApps: true)
                
                // Reassert after a short delay in case something toggles policy late
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
                    guard let self = self, self.currentMode == .dockIcon else { return }
                    print("Reasserting Dock Icon policy and control window visibility")
                    NSApp.setActivationPolicy(.regular)
                    if self.controlWindow == nil {
                        self.setupDockIcon()
                    } else {
                        if let controlWindow = self.controlWindow {
                            if controlWindow.isMiniaturized { controlWindow.deminiaturize(nil) }
                            if !controlWindow.isVisible { controlWindow.orderFront(nil) }
                        }
                    }
                    NSApp.activate(ignoringOtherApps: true)
                }
            case .menuBar:
                // Hide dock icon, keep only menu bar item visible
                NSApp.setActivationPolicy(.accessory)
                if self.statusItem == nil {
                    print("Status item missing - recreating for menu bar mode")
                    self.setupMenuBar()
                }
                self.statusItem?.isVisible = true
            case .cornerWidget:
                // Hide dock icon, keep corner widget window visible
                NSApp.setActivationPolicy(.accessory)
                if self.controlWindow == nil {
                    print("Corner widget missing - recreating")
                    self.setupCornerWidget()
                } else {
                    if let controlWindow = self.controlWindow, !controlWindow.isVisible {
                        print("Corner widget not visible - showing it")
                        controlWindow.orderFront(nil)
                    }
                }
            }
        }
    }
}
