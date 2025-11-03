import Cocoa

// MARK: - CropViewDelegate Protocol
protocol CropViewDelegate: AnyObject {
    func cropDidComplete(croppedRect: NSRect)
}

class ScreenshotWindow: NSWindow {
    
    private var screenshotImage: NSImage
    private var cropView: CropView
    private var drawingView: DrawingView
    private var toolbarView: NSView
    private var colorButtons: [NSButton] = []
    private var clipboardButton: NSButton!
    
    private let colors: [NSColor] = [
        .red, .blue, .green, .yellow, .orange, .purple, .black, .white
    ]
    
    init(screenshot: NSImage) {
        self.screenshotImage = screenshot
        
        // Get screen size
        let screenFrame = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 1920, height: 1080)
        
        // Create crop view
        self.cropView = CropView(frame: screenFrame)
        self.cropView.screenshotImage = screenshot
        
        // Create drawing view (initially hidden)
        self.drawingView = DrawingView(frame: NSRect.zero)
        
        // Create toolbar view
        self.toolbarView = NSView(frame: NSRect(x: 0, y: 0, width: 400, height: 60))
        
        super.init(contentRect: screenFrame,
                   styleMask: [.borderless],
                   backing: .buffered,
                   defer: false)
        
        setupWindow()
        setupToolbar()
        setupCropView()
    }
    
    private func setupWindow() {
        self.level = .screenSaver
        self.backgroundColor = NSColor.clear
        self.isOpaque = false
        self.hasShadow = false
        self.ignoresMouseEvents = false
        
        // Make window cover all screens
        if let screen = NSScreen.main {
            self.setFrame(screen.frame, display: true)
        }
    }
    
    private func setupToolbar() {
        toolbarView.wantsLayer = true
        toolbarView.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
        toolbarView.layer?.cornerRadius = 8
        
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
            
            toolbarView.addSubview(button)
            colorButtons.append(button)
            xOffset += 35
        }
        
        // Clipboard button
        clipboardButton = NSButton(frame: NSRect(x: xOffset + 10, y: 15, width: 80, height: 30))
        clipboardButton.title = "Clipboard"
        clipboardButton.bezelStyle = .rounded
        clipboardButton.target = self
        clipboardButton.action = #selector(copyToClipboard)
        toolbarView.addSubview(clipboardButton)
        
        // Initially hide toolbar
        toolbarView.isHidden = true
    }
    
    private func setupCropView() {
        cropView.delegate = self
        self.contentView?.addSubview(cropView)
    }
    
    @objc private func colorSelected(_ sender: NSButton) {
        let selectedColor = colors[sender.tag]
        drawingView.currentColor = selectedColor
        
        // Update button appearance
        for (index, button) in colorButtons.enumerated() {
            if index == sender.tag {
                button.layer?.borderColor = NSColor.black.cgColor
                button.layer?.borderWidth = 3
            } else {
                button.layer?.borderColor = NSColor.gray.cgColor
                button.layer?.borderWidth = 2
            }
        }
    }
    
    @objc private func copyToClipboard() {
        guard let finalImage = createFinalImage() else {
            print("Failed to create final image")
            return
        }

        // Optimize and convert image for clipboard
        guard let optimizedData = optimizeImageForClipboard(finalImage) else {
            print("Failed to optimize image")
            return
        }

        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()

        // Add optimized PNG data to pasteboard
        pasteboard.setData(optimizedData, forType: .png)

        print("Optimized image copied to clipboard successfully")

        // Show brief confirmation
        showCopyConfirmation()

        // Close window after copying
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.close()
            NSApp.setActivationPolicy(.accessory)
        }
    }

    private func optimizeImageForClipboard(_ image: NSImage) -> Data? {
        let imageSize = image.size

        // Determine if we need to downscale (for very large images > 4K)
        let maxDimension: CGFloat = 3840 // 4K width
        var targetSize = imageSize

        if imageSize.width > maxDimension || imageSize.height > maxDimension {
            let scale = min(maxDimension / imageSize.width, maxDimension / imageSize.height)
            targetSize = NSSize(width: imageSize.width * scale, height: imageSize.height * scale)
            print("Downscaling image from \(imageSize) to \(targetSize) for clipboard")
        }

        // Create bitmap representation with proper scaling
        let scaledImage: NSImage
        if targetSize != imageSize {
            scaledImage = NSImage(size: targetSize)
            scaledImage.lockFocus()
            image.draw(in: NSRect(origin: .zero, size: targetSize),
                      from: NSRect(origin: .zero, size: imageSize),
                      operation: .copy,
                      fraction: 1.0)
            scaledImage.unlockFocus()
        } else {
            scaledImage = image
        }

        // Convert to bitmap representation
        guard let tiffData = scaledImage.tiffRepresentation,
              let bitmapRep = NSBitmapImageRep(data: tiffData) else {
            print("Failed to create bitmap representation")
            return nil
        }

        // Use PNG with compression
        // compressionFactor: 0.0 (no compression) to 1.0 (maximum compression)
        // For clipboard, we want good compression without too much quality loss
        let compressionFactor: Float = 0.7

        let properties: [NSBitmapImageRep.PropertyKey: Any] = [
            .compressionFactor: compressionFactor,
            .interlaced: false // Non-interlaced PNGs are smaller
        ]

        guard let pngData = bitmapRep.representation(using: .png, properties: properties) else {
            print("Failed to create PNG data")
            return nil
        }

        let originalSize = (image.tiffRepresentation?.count ?? 0) / 1024
        let optimizedSize = pngData.count / 1024
        print("Image size: \(originalSize)KB → \(optimizedSize)KB (saved \(originalSize - optimizedSize)KB)")

        return pngData
    }

    private func showCopyConfirmation() {
        let confirmationLabel = NSTextField(labelWithString: "Copied to Clipboard!")
        confirmationLabel.textColor = .white
        confirmationLabel.backgroundColor = NSColor.black.withAlphaComponent(0.8)
        confirmationLabel.wantsLayer = true
        confirmationLabel.layer?.cornerRadius = 4
        confirmationLabel.alignment = .center

        let labelSize = confirmationLabel.intrinsicContentSize
        confirmationLabel.frame = NSRect(
            x: (self.frame.width - labelSize.width - 20) / 2,
            y: (self.frame.height - labelSize.height - 10) / 2,
            width: labelSize.width + 20,
            height: labelSize.height + 10
        )

        self.contentView?.addSubview(confirmationLabel)

        // Fade out after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.2
                confirmationLabel.animator().alphaValue = 0
            } completionHandler: {
                confirmationLabel.removeFromSuperview()
            }
        }
    }
    
    private func createFinalImage() -> NSImage? {
        guard let croppedImage = cropView.getCroppedImage() else { return nil }
        
        // Create final image with drawings
        let finalImage = NSImage(size: croppedImage.size)
        finalImage.lockFocus()
        
        // Draw cropped screenshot
        croppedImage.draw(at: NSPoint.zero, from: NSRect.zero, operation: .copy, fraction: 1.0)
        
        // Draw annotations
        drawingView.drawAnnotations(in: NSRect(origin: NSPoint.zero, size: croppedImage.size))
        
        finalImage.unlockFocus()
        
        return finalImage
    }
    
    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 { // Escape key
            print("ESC pressed - minimizing screenshot window")
            self.miniaturize(nil)
        }
    }
}

// MARK: - CropViewDelegate
extension ScreenshotWindow: CropViewDelegate {
    func cropDidComplete(croppedRect: NSRect) {
        // Hide crop view and show drawing view
        cropView.isHidden = true
        
        // Setup drawing view with cropped area
        drawingView.frame = croppedRect
        drawingView.croppedImage = cropView.getCroppedImage()
        self.contentView?.addSubview(drawingView)
        
        // Show toolbar
        toolbarView.isHidden = false
        let toolbarX = croppedRect.midX - toolbarView.frame.width / 2
        let toolbarY = croppedRect.minY - toolbarView.frame.height - 10
        toolbarView.frame.origin = NSPoint(x: toolbarX, y: toolbarY)
        self.contentView?.addSubview(toolbarView)
        
        // Select first color by default
        if !colorButtons.isEmpty {
            colorSelected(colorButtons[0])
        }
    }
}


