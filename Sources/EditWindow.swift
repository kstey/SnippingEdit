import Cocoa

// MARK: - EditWindowDelegate Protocol
protocol EditWindowDelegate: AnyObject {
    func editWindowDidClose(_ window: EditWindow)
    func editWindowDidShow(_ window: EditWindow)
    func editWindowDidMiniaturize(_ window: EditWindow)
    func editWindowDidDeminiaturize(_ window: EditWindow)
}

class EditWindow: NSWindow {

    weak var editDelegate: EditWindowDelegate?

    private var sourceImage: NSImage
    private var drawingView: DrawingView
    private var floatingToolbar: FloatingToolbar!
    
    // Reduced to 6 common colors (removed purple and white)
    private let colors: [NSColor] = [
        .red, .blue, .green, .yellow, .orange, .black
    ]
    
    init(image: NSImage) {
        self.sourceImage = image
        
        // Calculate window size based on image aspect ratio
        let screenFrame = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 1920, height: 1080)
        let maxWidth = screenFrame.width * 0.8
        let maxHeight = screenFrame.height * 0.8
        
        let imageAspectRatio = image.size.width / image.size.height
        var imageWidth = min(maxWidth, image.size.width)
        var imageHeight = imageWidth / imageAspectRatio
        
        // If image height exceeds max, scale down
        if imageHeight > maxHeight {
            imageHeight = maxHeight
            imageWidth = imageHeight * imageAspectRatio
        }
        
        // Ensure minimum dimensions for very small images
        let minImageHeight: CGFloat = 200
        if imageHeight < minImageHeight {
            imageHeight = minImageHeight
            imageWidth = imageHeight * imageAspectRatio
        }
        
        // Window size is just the image size (no toolbar space needed)
        let windowWidth = imageWidth
        let windowHeight = imageHeight
        
        // Center window on screen
        let windowX = (screenFrame.width - windowWidth) / 2
        let windowY = (screenFrame.height - windowHeight) / 2
        
        let windowFrame = NSRect(x: windowX, y: windowY, width: windowWidth, height: windowHeight)
        
        // Create drawing view to fill the entire window
        self.drawingView = DrawingView(frame: NSRect(x: 0, y: 0, width: imageWidth, height: imageHeight))
        self.drawingView.croppedImage = image
        
        super.init(contentRect: windowFrame,
                   styleMask: [.titled, .closable, .miniaturizable, .resizable],
                   backing: .buffered,
                   defer: false)
        
        setupWindow()
        setupDrawingView()
        
        // Create floating toolbar positioned below this window
        floatingToolbar = FloatingToolbar(parentWindow: self, colors: colors)
        floatingToolbar.toolbarDelegate = self

        // Set up undo/redo callback
        drawingView.onUndoRedoStateChanged = { [weak self] canUndo, canRedo in
            self?.floatingToolbar.updateUndoRedoButtons(canUndo: canUndo, canRedo: canRedo)
        }
        
        // Set up callback for when user starts editing
        drawingView.onEditMade = { [weak self] hasEdits in
            self?.floatingToolbar.updateCopyButton(enabled: hasEdits)
        }

        // Initialize undo/redo button states and disable copy button
        floatingToolbar.updateUndoRedoButtons(canUndo: false, canRedo: false)
        floatingToolbar.updateCopyButton(enabled: false)

        // Set self as delegate to receive window events
        self.delegate = self
        
        // Listen for app activation/deactivation events
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationDidBecomeActive),
            name: NSApplication.didBecomeActiveNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationDidResignActive),
            name: NSApplication.didResignActiveNotification,
            object: nil
        )

        // Notify delegate
        editDelegate?.editWindowDidShow(self)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func applicationDidBecomeActive() {
        // Show toolbar when app becomes active
        if !self.isMiniaturized {
            print("App became active - showing toolbar")
            floatingToolbar.orderFront(nil)
            floatingToolbar.updatePosition()
        }
    }
    
    @objc private func applicationDidResignActive() {
        // Hide toolbar when app is deactivated
        print("App resigned active - hiding toolbar")
        floatingToolbar.orderOut(nil)
    }

    private func setupWindow() {
        self.title = "SnippingEdit - Edit Image"
        self.backgroundColor = NSColor.windowBackgroundColor
        self.isOpaque = true
        self.hasShadow = true

        // Make window key
        self.makeKey()
    }
    
    // Method to update the image in the window
    func updateImage(_ image: NSImage) {
        print("Updating EditWindow with new image: \(image.size)")
        self.sourceImage = image
        
        // Clear any existing drawings
        drawingView.clearDrawing()
        
        // Disable copy button until user makes new edits
        floatingToolbar.updateCopyButton(enabled: false)
        
        // Calculate new window size based on image
        let screenFrame = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 1920, height: 1080)
        let maxWidth = screenFrame.width * 0.8
        let maxHeight = screenFrame.height * 0.8
        
        let imageAspectRatio = image.size.width / image.size.height
        var imageWidth = min(maxWidth, image.size.width)
        var imageHeight = imageWidth / imageAspectRatio
        
        // If image height exceeds max, scale down
        if imageHeight > maxHeight {
            imageHeight = maxHeight
            imageWidth = imageHeight * imageAspectRatio
        }
        
        // Ensure minimum dimensions
        let minImageHeight: CGFloat = 200
        if imageHeight < minImageHeight {
            imageHeight = minImageHeight
            imageWidth = imageHeight * imageAspectRatio
        }
        
        // Window size is just the image size
        let windowWidth = imageWidth
        let windowHeight = imageHeight
        
        // Center window on screen
        let windowX = (screenFrame.width - windowWidth) / 2
        let windowY = (screenFrame.height - windowHeight) / 2
        
        let newFrame = NSRect(x: windowX, y: windowY, width: windowWidth, height: windowHeight)
        
        // Animate window resize
        self.setFrame(newFrame, display: true, animate: true)
        
        // Update drawing view frame to fill the content view (not raw dimensions)
        // This ensures it accounts for the title bar and window chrome
        if let contentView = self.contentView {
            drawingView.frame = contentView.bounds
        }
        
        // Update the image in the drawing view
        drawingView.croppedImage = image
        drawingView.needsDisplay = true
        
        // Update toolbar position to follow window
        floatingToolbar.updatePosition()
        
        print("✓ Image updated in EditWindow with new size: \(windowWidth) x \(windowHeight)")
    }
    
    private func setupDrawingView() {
        if let contentView = self.contentView {
            // Set the drawing view to fill the entire content view
            drawingView.frame = contentView.bounds
            drawingView.autoresizingMask = [.width, .height]
            
            // Ensure the image is drawn with proper aspect ratio within the view
            drawingView.wantsLayer = true
            drawingView.layer?.contentsGravity = .resizeAspect
            
            contentView.addSubview(drawingView)
        }
    }
    
    override func close() {
        print("Edit window closing")

        // Store delegate reference before clearing
        let delegate = editDelegate

        // Remove observers first
        NotificationCenter.default.removeObserver(self)

        // Disable animations to prevent crash during deallocation
        self.animationBehavior = .none

        // Close and release toolbar
        if let toolbar = floatingToolbar {
            toolbar.animationBehavior = .none
            toolbar.orderOut(nil)
            toolbar.close()
        }
        floatingToolbar = nil

        // Clear delegates to break retain cycles
        editDelegate = nil
        self.delegate = nil

        // Call super
        super.close()

        // Notify delegate after everything is cleaned up
        delegate?.editWindowDidClose(self)
    }
}

// MARK: - FloatingToolbarDelegate
extension EditWindow: FloatingToolbarDelegate {
    func toolbarDidSelectColor(_ color: NSColor) {
        drawingView.currentColor = color
        print("Color selected: \(color)")
    }

    func toolbarDidRequestClear() {
        drawingView.clearDrawing()
        print("Drawing cleared")
    }

    func toolbarDidRequestUndo() {
        drawingView.undo()
    }

    func toolbarDidRequestRedo() {
        drawingView.redo()
    }

    func toolbarDidRequestCopyToClipboard() {
        guard let finalImage = drawingView.getFinalImage() else {
            print("Failed to get final image")
            return
        }

        // Notify AppDelegate that we're about to write to clipboard
        if let appDelegate = NSApp.delegate as? AppDelegate {
            appDelegate.willWriteToClipboard()
        }

        // Copy to clipboard
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.writeObjects([finalImage])

        print("Image copied to clipboard")

        floatingToolbar.showCopiedFeedback()
    }
}

// MARK: - NSWindowDelegate
extension EditWindow: NSWindowDelegate {
    func windowDidMiniaturize(_ notification: Notification) {
        print("EditWindow miniaturized")
        floatingToolbar.orderOut(nil)
        editDelegate?.editWindowDidMiniaturize(self)
    }

    func windowDidDeminiaturize(_ notification: Notification) {
        print("EditWindow deminiaturized")
        // Only show toolbar if app is currently active
        if NSApp.isActive {
            floatingToolbar.orderFront(nil)
            floatingToolbar.updatePosition()
        }
        editDelegate?.editWindowDidDeminiaturize(self)
    }
    
    func windowDidMove(_ notification: Notification) {
        // Only update position if toolbar is visible
        if floatingToolbar.isVisible && NSApp.isActive {
            floatingToolbar.updatePosition()
        }
    }
    
    func windowDidBecomeKey(_ notification: Notification) {
        // Show toolbar when window becomes key (if app is active)
        if NSApp.isActive && !self.isMiniaturized {
            floatingToolbar.orderFront(nil)
            floatingToolbar.updatePosition()
        }
    }
    
    func windowDidResignKey(_ notification: Notification) {
        // Keep toolbar visible when window loses key status
        // It will be hidden when app deactivates
    }
}

// MARK: - FloatingToolbar
protocol FloatingToolbarDelegate: AnyObject {
    func toolbarDidSelectColor(_ color: NSColor)
    func toolbarDidRequestClear()
    func toolbarDidRequestUndo()
    func toolbarDidRequestRedo()
    func toolbarDidRequestCopyToClipboard()
}

class FloatingToolbar: NSPanel {
    weak var toolbarDelegate: FloatingToolbarDelegate?
    private weak var editWindow: NSWindow?
    private var colorButtons: [NSButton] = []
    private var clipboardButton: NSButton!
    private var undoButton: NSButton!
    private var redoButton: NSButton!

    init(parentWindow: NSWindow, colors: [NSColor]) {
        self.editWindow = parentWindow

        // Create floating panel (wider to accommodate undo/redo buttons)
        let toolbarWidth: CGFloat = 550
        let toolbarHeight: CGFloat = 60
        let toolbarFrame = NSRect(x: 0, y: 0, width: toolbarWidth, height: toolbarHeight)

        super.init(contentRect: toolbarFrame,
                   styleMask: [.nonactivatingPanel, .utilityWindow],
                   backing: .buffered,
                   defer: false)

        // Configure panel to float
        self.level = .floating
        self.isFloatingPanel = true
        self.hidesOnDeactivate = false
        self.becomesKeyOnlyIfNeeded = true
        self.backgroundColor = NSColor.controlBackgroundColor.withAlphaComponent(0.95)
        self.isOpaque = false
        self.hasShadow = true
        self.styleMask.insert(.nonactivatingPanel)

        setupToolbarContent(colors: colors)
        updatePosition()
        self.orderFront(nil)
    }

    deinit {
        print("FloatingToolbar deinit")
        toolbarDelegate = nil
        editWindow = nil
    }
    
    private func setupToolbarContent(colors: [NSColor]) {
        guard let contentView = self.contentView else { return }
        
        contentView.wantsLayer = true
        contentView.layer?.cornerRadius = 8
        contentView.layer?.borderWidth = 2
        contentView.layer?.borderColor = NSColor.systemGray.cgColor
        
        var xOffset: CGFloat = 10
        
        // Color selection buttons
        for (index, color) in colors.enumerated() {
            let button = NSButton(frame: NSRect(x: xOffset, y: 15, width: 30, height: 30))
            button.wantsLayer = true
            button.layer?.backgroundColor = color.cgColor
            button.layer?.cornerRadius = 15
            button.layer?.borderWidth = 2
            button.layer?.borderColor = NSColor.gray.cgColor
            button.target = self
            button.action = #selector(colorSelected(_:))
            button.tag = index
            button.isBordered = false
            button.title = ""
            
            contentView.addSubview(button)
            colorButtons.append(button)
            
            xOffset += 40
        }
        
        // Select first color by default
        if let firstButton = colorButtons.first {
            firstButton.layer?.borderColor = NSColor.black.cgColor
            firstButton.layer?.borderWidth = 3
            toolbarDelegate?.toolbarDidSelectColor(colors[0])
        }
        
        xOffset += 10

        // Undo button
        undoButton = NSButton(frame: NSRect(x: xOffset, y: 15, width: 60, height: 30))
        undoButton.title = "Undo"
        undoButton.bezelStyle = .rounded
        undoButton.target = self
        undoButton.action = #selector(undoAction)
        undoButton.isEnabled = false
        contentView.addSubview(undoButton)

        xOffset += 70

        // Redo button
        redoButton = NSButton(frame: NSRect(x: xOffset, y: 15, width: 60, height: 30))
        redoButton.title = "Redo"
        redoButton.bezelStyle = .rounded
        redoButton.target = self
        redoButton.action = #selector(redoAction)
        redoButton.isEnabled = false
        contentView.addSubview(redoButton)

        xOffset += 70

        // Clear button
        let clearButton = NSButton(frame: NSRect(x: xOffset, y: 15, width: 60, height: 30))
        clearButton.title = "Clear"
        clearButton.bezelStyle = .rounded
        clearButton.target = self
        clearButton.action = #selector(clearDrawing)
        contentView.addSubview(clearButton)

        xOffset += 70

        // Clipboard button - disabled by default until user makes edits
        clipboardButton = NSButton(frame: NSRect(x: xOffset, y: 15, width: 80, height: 30))
        clipboardButton.title = "Copy"
        clipboardButton.bezelStyle = .rounded
        clipboardButton.target = self
        clipboardButton.action = #selector(copyToClipboard)
        clipboardButton.isEnabled = false  // Disabled by default
        
        contentView.addSubview(clipboardButton)
    }
    
    func updatePosition() {
        guard let parent = editWindow else { return }
        
        let parentFrame = parent.frame
        let toolbarWidth = self.frame.width
        
        // Position below parent window, centered
        let x = parentFrame.origin.x + (parentFrame.width - toolbarWidth) / 2
        let y = parentFrame.origin.y - self.frame.height - 10  // 10px gap
        
        self.setFrameOrigin(NSPoint(x: x, y: y))
    }
    
    @objc private func colorSelected(_ sender: NSButton) {
        // Reset all button borders
        for button in colorButtons {
            button.layer?.borderColor = NSColor.gray.cgColor
            button.layer?.borderWidth = 2
        }
        
        // Highlight selected button
        sender.layer?.borderColor = NSColor.black.cgColor
        sender.layer?.borderWidth = 3
        
        toolbarDelegate?.toolbarDidSelectColor(sender.layer?.backgroundColor?.nsColor ?? .red)
    }
    
    @objc private func undoAction() {
        toolbarDelegate?.toolbarDidRequestUndo()
    }

    @objc private func redoAction() {
        toolbarDelegate?.toolbarDidRequestRedo()
    }

    @objc private func clearDrawing() {
        toolbarDelegate?.toolbarDidRequestClear()
    }

    @objc private func copyToClipboard() {
        toolbarDelegate?.toolbarDidRequestCopyToClipboard()
    }

    func updateUndoRedoButtons(canUndo: Bool, canRedo: Bool) {
        undoButton.isEnabled = canUndo
        redoButton.isEnabled = canRedo
    }
    
    func updateCopyButton(enabled: Bool) {
        clipboardButton.isEnabled = enabled
    }

    func showCopiedFeedback() {
        let originalTitle = clipboardButton.title
        clipboardButton.title = "✅ Copied!"

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            guard let self = self else { return }
            self.clipboardButton.title = originalTitle
            // Disable the copy button after copying
            self.clipboardButton.isEnabled = false
        }
    }
}

// Helper to convert CGColor to NSColor
extension CGColor {
    var nsColor: NSColor {
        return NSColor(cgColor: self) ?? .black
    }
}

