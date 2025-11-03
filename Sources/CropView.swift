import Cocoa

enum ResizeHandle {
    case none
    case topLeft, topRight, bottomLeft, bottomRight
    case top, bottom, left, right
    case move
}

class CropView: NSView {

    weak var delegate: CropViewDelegate?
    var screenshotImage: NSImage?
    private var isClosing = false

    private var startPoint: NSPoint = NSPoint.zero
    private var currentPoint: NSPoint = NSPoint.zero
    private var isDragging: Bool = false
    private var selectionRect: NSRect = NSRect.zero

    // Resize handling
    private var activeHandle: ResizeHandle = .none
    private var resizeStartPoint: NSPoint = NSPoint.zero
    private var resizeStartRect: NSRect = NSRect.zero

    // Handle size
    private let handleSize: CGFloat = 10
    private let edgeGrabDistance: CGFloat = 8

    // Capture button
    private var captureButton: NSButton!
    private var cancelButton: NSButton!

    // MARK: - Initialization

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupButtons()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupButtons()
    }

    private func setupButtons() {
        // Create Capture button
        captureButton = NSButton(frame: NSRect(x: 0, y: 0, width: 120, height: 40))
        captureButton.title = "✓ Capture"
        captureButton.bezelStyle = .rounded
        captureButton.font = NSFont.systemFont(ofSize: 14, weight: .medium)
        captureButton.target = self
        captureButton.action = #selector(captureButtonClicked)
        captureButton.keyEquivalent = "\r" // Enter key
        captureButton.wantsLayer = true
        captureButton.layer?.backgroundColor = NSColor(calibratedRed: 0.2, green: 0.6, blue: 1.0, alpha: 0.9).cgColor
        captureButton.layer?.cornerRadius = 6
        captureButton.contentTintColor = .white
        captureButton.isHidden = true
        self.addSubview(captureButton)

        // Create Cancel button
        cancelButton = NSButton(frame: NSRect(x: 0, y: 0, width: 100, height: 40))
        cancelButton.title = "✕ Cancel"
        cancelButton.bezelStyle = .rounded
        cancelButton.font = NSFont.systemFont(ofSize: 14, weight: .medium)
        cancelButton.target = self
        cancelButton.action = #selector(cancelButtonClicked)
        cancelButton.keyEquivalent = "\u{1b}" // Escape key
        cancelButton.wantsLayer = true
        cancelButton.layer?.backgroundColor = NSColor(calibratedWhite: 0.3, alpha: 0.8).cgColor
        cancelButton.layer?.cornerRadius = 6
        cancelButton.contentTintColor = .white
        cancelButton.isHidden = true
        self.addSubview(cancelButton)
    }

    @objc private func captureButtonClicked() {
        confirmSelection()
    }

    @objc private func cancelButtonClicked() {
        print("Cancel button clicked - minimizing window")
        self.window?.miniaturize(nil)
    }

    private func confirmSelection() {
        if !selectionRect.isEmpty {
            let screenRect = self.convert(selectionRect, to: nil)
            // Safely call delegate only if not closing
            if !isClosing, let delegate = delegate {
                delegate.cropDidComplete(croppedRect: screenRect)
            }
        }
    }

    // MARK: - Public Methods

    func setInitialSelection(_ rect: NSRect) {
        print("🔴 CropView.setInitialSelection called with: \(rect)")
        selectionRect = rect
        print("🔴 selectionRect is now: \(selectionRect)")
        // Show buttons when selection is set
        updateButtonPositions()
        captureButton.isHidden = false
        cancelButton.isHidden = false
        print("🔴 Buttons shown, captureButton.isHidden = \(captureButton.isHidden)")
        // Trigger a redraw to show the selection immediately
        self.needsDisplay = true
    }

    private func updateButtonPositions() {
        guard !selectionRect.isEmpty else {
            captureButton.isHidden = true
            cancelButton.isHidden = true
            return
        }

        // Position buttons below the selection rectangle
        let buttonSpacing: CGFloat = 10
        let totalWidth = captureButton.frame.width + cancelButton.frame.width + buttonSpacing
        let buttonY = selectionRect.minY - captureButton.frame.height - 15

        // Check if buttons fit below selection, otherwise put them above
        let finalButtonY: CGFloat
        if buttonY > 10 {
            finalButtonY = buttonY
        } else {
            finalButtonY = selectionRect.maxY + 15
        }

        let startX = selectionRect.midX - totalWidth / 2

        captureButton.frame.origin = NSPoint(x: startX, y: finalButtonY)
        cancelButton.frame.origin = NSPoint(x: startX + captureButton.frame.width + buttonSpacing, y: finalButtonY)

        // Show buttons
        captureButton.isHidden = false
        cancelButton.isHidden = false
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Draw the screenshot as background
        if let image = screenshotImage {
            image.draw(in: self.bounds)
        }

        // Draw overlay - always show if there's a selection
        if isDragging || !selectionRect.isEmpty {
            drawOverlay()
        }
    }

    private func drawOverlay() {
        // Draw semi-transparent overlay over entire view
        NSColor.black.withAlphaComponent(0.4).setFill()
        self.bounds.fill()

        // Clear the selection area
        if !selectionRect.isEmpty {
            NSColor.clear.setFill()
            selectionRect.fill(using: .copy)

            // Draw dashed selection border
            drawDashedBorder()

            // Draw corner and edge handles
            drawResizeHandles()

            // Draw dimension label
            drawDimensionLabel()
        }
    }

    private func drawDashedBorder() {
        // Create dashed border path
        let borderPath = NSBezierPath(rect: selectionRect)

        // Set up dashed line pattern
        let dashPattern: [CGFloat] = [8.0, 4.0] // 8 points on, 4 points off
        borderPath.setLineDash(dashPattern, count: 2, phase: 0)
        borderPath.lineWidth = 2.0

        // Draw white dashed border
        NSColor.white.setStroke()
        borderPath.stroke()

        // Draw black dashed border slightly offset for contrast
        let shadowPath = NSBezierPath(rect: selectionRect)
        shadowPath.setLineDash(dashPattern, count: 2, phase: 0)
        shadowPath.lineWidth = 2.0

        let context = NSGraphicsContext.current?.cgContext
        context?.saveGState()
        context?.setShadow(offset: CGSize(width: 0, height: 0), blur: 2, color: NSColor.black.cgColor)
        NSColor.white.setStroke()
        shadowPath.stroke()
        context?.restoreGState()
    }

    private func drawResizeHandles() {
        // Corner handles (larger, more visible)
        let cornerHandles = [
            (NSRect(x: selectionRect.minX - handleSize/2, y: selectionRect.minY - handleSize/2, width: handleSize, height: handleSize), ResizeHandle.bottomLeft),
            (NSRect(x: selectionRect.maxX - handleSize/2, y: selectionRect.minY - handleSize/2, width: handleSize, height: handleSize), ResizeHandle.bottomRight),
            (NSRect(x: selectionRect.minX - handleSize/2, y: selectionRect.maxY - handleSize/2, width: handleSize, height: handleSize), ResizeHandle.topLeft),
            (NSRect(x: selectionRect.maxX - handleSize/2, y: selectionRect.maxY - handleSize/2, width: handleSize, height: handleSize), ResizeHandle.topRight)
        ]

        // Edge handles (smaller, on the middle of each edge)
        let edgeHandles = [
            (NSRect(x: selectionRect.midX - handleSize/3, y: selectionRect.minY - handleSize/2, width: handleSize * 0.66, height: handleSize), ResizeHandle.bottom),
            (NSRect(x: selectionRect.midX - handleSize/3, y: selectionRect.maxY - handleSize/2, width: handleSize * 0.66, height: handleSize), ResizeHandle.top),
            (NSRect(x: selectionRect.minX - handleSize/2, y: selectionRect.midY - handleSize/3, width: handleSize, height: handleSize * 0.66), ResizeHandle.left),
            (NSRect(x: selectionRect.maxX - handleSize/2, y: selectionRect.midY - handleSize/3, width: handleSize, height: handleSize * 0.66), ResizeHandle.right)
        ]

        // Draw corner handles (circles)
        for (rect, _) in cornerHandles {
            drawHandle(rect: rect, isCorner: true)
        }

        // Draw edge handles (rectangles)
        for (rect, _) in edgeHandles {
            drawHandle(rect: rect, isCorner: false)
        }
    }

    private func drawHandle(rect: NSRect, isCorner: Bool) {
        let handlePath: NSBezierPath
        if isCorner {
            handlePath = NSBezierPath(ovalIn: rect)
        } else {
            handlePath = NSBezierPath(roundedRect: rect, xRadius: 2, yRadius: 2)
        }

        // Fill with white
        NSColor.white.setFill()
        handlePath.fill()

        // Stroke with blue for visibility
        NSColor(calibratedRed: 0.2, green: 0.6, blue: 1.0, alpha: 1.0).setStroke()
        handlePath.lineWidth = 2.0
        handlePath.stroke()
    }

    private func drawDimensionLabel() {
        // Calculate dimensions in pixels
        let width = Int(selectionRect.width)
        let height = Int(selectionRect.height)
        let dimensionText = "\(width) × \(height)"

        // Create label
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 14, weight: .medium),
            .foregroundColor: NSColor.white
        ]

        let attributedString = NSAttributedString(string: dimensionText, attributes: attributes)
        let textSize = attributedString.size()

        // Position label above the selection (or below if too close to top)
        let labelPadding: CGFloat = 8
        let labelY: CGFloat
        if selectionRect.maxY + textSize.height + labelPadding * 2 < self.bounds.height {
            labelY = selectionRect.maxY + labelPadding
        } else {
            labelY = selectionRect.minY - textSize.height - labelPadding
        }

        let labelRect = NSRect(
            x: selectionRect.midX - textSize.width / 2 - labelPadding,
            y: labelY,
            width: textSize.width + labelPadding * 2,
            height: textSize.height + labelPadding
        )

        // Draw background
        let backgroundPath = NSBezierPath(roundedRect: labelRect, xRadius: 4, yRadius: 4)
        NSColor.black.withAlphaComponent(0.7).setFill()
        backgroundPath.fill()

        // Draw text
        attributedString.draw(at: NSPoint(x: labelRect.minX + labelPadding, y: labelRect.minY + labelPadding / 2))
    }

    override func mouseDown(with event: NSEvent) {
        let locationInView = self.convert(event.locationInWindow, from: nil)

        // Check if clicking on an existing selection to resize/move
        if !selectionRect.isEmpty {
            activeHandle = getHandleAtPoint(locationInView)

            if activeHandle != .none {
                // Start resizing
                resizeStartPoint = locationInView
                resizeStartRect = selectionRect
                isDragging = false
                return
            }
        }

        // Start new selection
        startPoint = locationInView
        currentPoint = locationInView
        isDragging = true
        selectionRect = NSRect.zero
        activeHandle = .none

        self.needsDisplay = true
    }

    override func mouseDragged(with event: NSEvent) {
        let locationInView = self.convert(event.locationInWindow, from: nil)

        if activeHandle != .none {
            // Resize existing selection
            resizeSelection(to: locationInView)
        } else if isDragging {
            // Create new selection
            currentPoint = locationInView

            // Calculate selection rectangle
            let minX = min(startPoint.x, currentPoint.x)
            let minY = min(startPoint.y, currentPoint.y)
            let maxX = max(startPoint.x, currentPoint.x)
            let maxY = max(startPoint.y, currentPoint.y)

            selectionRect = NSRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
        }

        // Update button positions
        updateButtonPositions()
        self.needsDisplay = true
    }

    override func mouseUp(with event: NSEvent) {
        if activeHandle != .none {
            // Finished resizing
            activeHandle = .none
            updateButtonPositions()
            self.needsDisplay = true
            return
        }

        guard isDragging else { return }

        isDragging = false

        // Ensure minimum selection size
        if selectionRect.width > 10 && selectionRect.height > 10 {
            // Keep the selection for further editing
            updateButtonPositions()
            self.needsDisplay = true
        } else {
            // Reset if selection is too small
            selectionRect = NSRect.zero
            captureButton.isHidden = true
            cancelButton.isHidden = true
            self.needsDisplay = true
        }
    }

    override func mouseMoved(with event: NSEvent) {
        let locationInView = self.convert(event.locationInWindow, from: nil)
        updateCursor(for: locationInView)
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()

        // Remove existing tracking areas
        for trackingArea in trackingAreas {
            removeTrackingArea(trackingArea)
        }

        // Add new tracking area for cursor updates
        let trackingArea = NSTrackingArea(
            rect: bounds,
            options: [.activeAlways, .mouseMoved, .cursorUpdate],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(trackingArea)
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 { // Escape key
            cancelButtonClicked()
        } else if event.keyCode == 36 { // Enter key
            captureButtonClicked()
        }
    }

    // MARK: - Resize Handling

    private func getHandleAtPoint(_ point: NSPoint) -> ResizeHandle {
        guard !selectionRect.isEmpty else { return .none }

        // Check corner handles first (they have priority)
        let corners: [(NSRect, ResizeHandle)] = [
            (NSRect(x: selectionRect.minX - handleSize, y: selectionRect.minY - handleSize, width: handleSize * 2, height: handleSize * 2), .bottomLeft),
            (NSRect(x: selectionRect.maxX - handleSize, y: selectionRect.minY - handleSize, width: handleSize * 2, height: handleSize * 2), .bottomRight),
            (NSRect(x: selectionRect.minX - handleSize, y: selectionRect.maxY - handleSize, width: handleSize * 2, height: handleSize * 2), .topLeft),
            (NSRect(x: selectionRect.maxX - handleSize, y: selectionRect.maxY - handleSize, width: handleSize * 2, height: handleSize * 2), .topRight)
        ]

        for (rect, handle) in corners {
            if rect.contains(point) {
                return handle
            }
        }

        // Check edge handles
        let edges: [(NSRect, ResizeHandle)] = [
            (NSRect(x: selectionRect.minX - edgeGrabDistance, y: selectionRect.minY + handleSize, width: edgeGrabDistance * 2, height: selectionRect.height - handleSize * 2), .left),
            (NSRect(x: selectionRect.maxX - edgeGrabDistance, y: selectionRect.minY + handleSize, width: edgeGrabDistance * 2, height: selectionRect.height - handleSize * 2), .right),
            (NSRect(x: selectionRect.minX + handleSize, y: selectionRect.minY - edgeGrabDistance, width: selectionRect.width - handleSize * 2, height: edgeGrabDistance * 2), .bottom),
            (NSRect(x: selectionRect.minX + handleSize, y: selectionRect.maxY - edgeGrabDistance, width: selectionRect.width - handleSize * 2, height: edgeGrabDistance * 2), .top)
        ]

        for (rect, handle) in edges {
            if rect.contains(point) {
                return handle
            }
        }

        // Check if inside selection (for moving)
        if selectionRect.contains(point) {
            return .move
        }

        return .none
    }

    private func resizeSelection(to point: NSPoint) {
        let dx = point.x - resizeStartPoint.x
        let dy = point.y - resizeStartPoint.y

        var newRect = resizeStartRect

        switch activeHandle {
        case .topLeft:
            newRect.origin.x = resizeStartRect.minX + dx
            newRect.origin.y = resizeStartRect.minY
            newRect.size.width = resizeStartRect.width - dx
            newRect.size.height = resizeStartRect.height + dy

        case .topRight:
            newRect.origin.y = resizeStartRect.minY
            newRect.size.width = resizeStartRect.width + dx
            newRect.size.height = resizeStartRect.height + dy

        case .bottomLeft:
            newRect.origin.x = resizeStartRect.minX + dx
            newRect.origin.y = resizeStartRect.minY + dy
            newRect.size.width = resizeStartRect.width - dx
            newRect.size.height = resizeStartRect.height - dy

        case .bottomRight:
            newRect.origin.y = resizeStartRect.minY + dy
            newRect.size.width = resizeStartRect.width + dx
            newRect.size.height = resizeStartRect.height - dy

        case .top:
            newRect.size.height = resizeStartRect.height + dy

        case .bottom:
            newRect.origin.y = resizeStartRect.minY + dy
            newRect.size.height = resizeStartRect.height - dy

        case .left:
            newRect.origin.x = resizeStartRect.minX + dx
            newRect.size.width = resizeStartRect.width - dx

        case .right:
            newRect.size.width = resizeStartRect.width + dx

        case .move:
            newRect.origin.x = resizeStartRect.minX + dx
            newRect.origin.y = resizeStartRect.minY + dy

        case .none:
            return
        }

        // Ensure minimum size
        if newRect.width >= 20 && newRect.height >= 20 {
            // Ensure rect stays within bounds
            newRect = newRect.intersection(self.bounds)
            selectionRect = newRect
        }
    }

    private func updateCursor(for point: NSPoint) {
        let handle = getHandleAtPoint(point)

        switch handle {
        case .topLeft, .bottomRight:
            // Use custom cursor or fallback to arrow
            if #available(macOS 15.0, *) {
                NSCursor.frameResize(position: .topLeft, directions: [.inward, .outward]).set()
            } else {
                NSCursor.arrow.set()
            }
        case .topRight, .bottomLeft:
            if #available(macOS 15.0, *) {
                NSCursor.frameResize(position: .topRight, directions: [.inward, .outward]).set()
            } else {
                NSCursor.arrow.set()
            }
        case .top, .bottom:
            NSCursor.resizeUpDown.set()
        case .left, .right:
            NSCursor.resizeLeftRight.set()
        case .move:
            NSCursor.openHand.set()
        case .none:
            NSCursor.crosshair.set()
        }
    }

    func getCroppedImage() -> NSImage? {
        guard let originalImage = screenshotImage, !selectionRect.isEmpty else { return nil }

        // Convert selection rect to image coordinates
        let imageSize = originalImage.size
        let viewSize = self.bounds.size

        let scaleX = imageSize.width / viewSize.width
        let scaleY = imageSize.height / viewSize.height

        // Flip Y coordinate (NSView uses bottom-left origin, NSImage uses top-left)
        let flippedY = viewSize.height - selectionRect.maxY

        let cropRect = NSRect(
            x: selectionRect.minX * scaleX,
            y: flippedY * scaleY,
            width: selectionRect.width * scaleX,
            height: selectionRect.height * scaleY
        )

        // Create cropped image
        let croppedImage = NSImage(size: NSSize(width: cropRect.width, height: cropRect.height))
        croppedImage.lockFocus()

        let sourceRect = NSRect(
            x: cropRect.minX,
            y: cropRect.minY,
            width: cropRect.width,
            height: cropRect.height
        )

        let destRect = NSRect(
            x: 0,
            y: 0,
            width: cropRect.width,
            height: cropRect.height
        )

        originalImage.draw(in: destRect, from: sourceRect, operation: .copy, fraction: 1.0)
        croppedImage.unlockFocus()

        return croppedImage
    }

    override var acceptsFirstResponder: Bool {
        return true
    }


    // Reset the crop UI for a new capture and update the backing screenshot image
    func resetForNewCapture(with image: NSImage) {
        print("🟣 CropView.resetForNewCapture called")
        isClosing = false
        screenshotImage = image
        startPoint = .zero
        currentPoint = .zero
        isDragging = false
        selectionRect = .zero
        activeHandle = .none
        captureButton.isHidden = true
        cancelButton.isHidden = true
        print("🟣 Reset complete, buttons hidden")
        self.needsDisplay = true
    }

    func prepareForClose() {
        isClosing = true
        delegate = nil
    }
}
