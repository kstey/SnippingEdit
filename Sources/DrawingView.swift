import Cocoa

class DrawingView: NSView {

    var croppedImage: NSImage?
    var currentColor: NSColor = .red
    private var paths: [DrawingPath] = []
    private var currentPath: DrawingPath?

    // Undo/Redo support
    private var undoStack: [[DrawingPath]] = []
    private var redoStack: [[DrawingPath]] = []

    // Callback to notify when undo/redo state changes
    var onUndoRedoStateChanged: ((Bool, Bool) -> Void)?

    // Callback to notify when user makes an edit
    var onEditMade: ((Bool) -> Void)?

    // Auto-clipboard timer
    private var autoClipboardTimer: Timer?
    var onAutoClipboard: (() -> Void)?

    // Track previous bounds to detect resize
    private var previousBounds: NSRect = .zero

    // Use flipped coordinates (top-left origin) for easier image alignment
    override var isFlipped: Bool {
        return true
    }

    private struct DrawingPath {
        var points: [NSPoint]
        var color: NSColor
        var lineWidth: CGFloat

        // Scale all points by the given factors
        func scaled(by scaleX: CGFloat, _ scaleY: CGFloat) -> DrawingPath {
            let scaledPoints = points.map { NSPoint(x: $0.x * scaleX, y: $0.y * scaleY) }
            return DrawingPath(points: scaledPoints, color: color, lineWidth: lineWidth)
        }
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Detect if bounds changed (window was resized)
        if previousBounds != .zero && previousBounds != self.bounds {
            print("View bounds changed from \(previousBounds) to \(self.bounds)")
            rescaleAnnotations(from: previousBounds, to: self.bounds)
        }
        previousBounds = self.bounds

        // Draw the cropped image as background
        if let image = croppedImage {
            // Draw image with proper aspect ratio, fitting within bounds
            image.draw(in: self.bounds,
                      from: NSRect.zero,
                      operation: .sourceOver,
                      fraction: 1.0,
                      respectFlipped: true,
                      hints: [.interpolation: NSNumber(value: NSImageInterpolation.high.rawValue)])
        }

        // Draw all paths
        drawAllPaths()
    }

    private func rescaleAnnotations(from oldBounds: NSRect, to newBounds: NSRect) {
        let scaleX = newBounds.width / oldBounds.width
        let scaleY = newBounds.height / oldBounds.height

        print("Rescaling annotations by \(scaleX)x, \(scaleY)y")

        // Scale all existing paths
        paths = paths.map { $0.scaled(by: scaleX, scaleY) }

        // Scale undo stack
        undoStack = undoStack.map { pathArray in
            pathArray.map { $0.scaled(by: scaleX, scaleY) }
        }

        // Scale redo stack
        redoStack = redoStack.map { pathArray in
            pathArray.map { $0.scaled(by: scaleX, scaleY) }
        }
    }
    
    private func drawAllPaths() {
        for path in paths {
            drawPath(path)
        }
        
        // Draw current path being drawn
        if let currentPath = currentPath {
            drawPath(currentPath)
        }
    }
    
    private func drawPath(_ path: DrawingPath) {
        guard path.points.count > 1 else { return }
        
        let bezierPath = NSBezierPath()
        bezierPath.lineWidth = path.lineWidth
        bezierPath.lineCapStyle = .round
        bezierPath.lineJoinStyle = .round
        
        bezierPath.move(to: path.points[0])
        for i in 1..<path.points.count {
            bezierPath.line(to: path.points[i])
        }
        
        path.color.setStroke()
        bezierPath.stroke()
    }
    
    override func mouseDown(with event: NSEvent) {
        let locationInView = self.convert(event.locationInWindow, from: nil)

        // Cancel any pending timer when user starts drawing
        cancelAutoClipboardTimer()
        print("Mouse down - cancelled auto-clipboard timer")

        currentPath = DrawingPath(
            points: [locationInView],
            color: currentColor,
            lineWidth: 3.0
        )

        self.needsDisplay = true
    }

    override func mouseDragged(with event: NSEvent) {
        guard var path = currentPath else { return }

        let locationInView = self.convert(event.locationInWindow, from: nil)
        path.points.append(locationInView)
        currentPath = path

        self.needsDisplay = true
    }
    
    override func mouseUp(with event: NSEvent) {
        guard let path = currentPath else { return }

        // Add completed path to paths array
        if path.points.count > 1 {
            // Save current state to undo stack before adding new path
            saveToUndoStack()
            paths.append(path)
            // Clear redo stack when new action is performed
            redoStack.removeAll()
            updateUndoRedoState()

            // Notify that an edit has been made
            onEditMade?(true)

            // Start auto-clipboard timer after mouse is released
            print("Mouse up - starting 2-second auto-clipboard timer")
            startAutoClipboardTimer()
        }

        currentPath = nil
        self.needsDisplay = true
    }

    private func startAutoClipboardTimer() {
        // Cancel any existing timer
        autoClipboardTimer?.invalidate()

        // Start a new 2-second timer
        print("⏱️  Starting new 2-second auto-clipboard timer")
        autoClipboardTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { [weak self] _ in
            print("✅ Auto-clipboard timer completed - copying to clipboard now")
            self?.onAutoClipboard?()
        }
    }

    private func cancelAutoClipboardTimer() {
        if autoClipboardTimer != nil {
            print("❌ Cancelling auto-clipboard timer")
            autoClipboardTimer?.invalidate()
            autoClipboardTimer = nil
        }
    }
    
    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 { // Escape key
            print("ESC pressed in drawing view - minimizing window")
            self.window?.miniaturize(nil)
        } else if event.keyCode == 6 && event.modifierFlags.contains(.command) { // Cmd+Z for undo
            if event.modifierFlags.contains(.shift) {
                // Cmd+Shift+Z for redo
                redo()
            } else {
                // Cmd+Z for undo
                undo()
            }
        } else if event.keyCode == 51 { // Delete key
            // Clear last drawn path (same as undo)
            undo()
        } else if event.keyCode == 15 && event.modifierFlags.contains(.command) { // Cmd+R for clear all
            print("Cmd+R pressed - clearing all paths")
            saveToUndoStack()
            paths.removeAll()
            redoStack.removeAll()
            updateUndoRedoState()
            self.needsDisplay = true
        } else {
            super.keyDown(with: event)
        }
    }
    
    func drawAnnotations(in rect: NSRect) {
        // This method is called when creating the final image
        // Scale the drawing to match the final image size
        let scaleX = rect.width / self.bounds.width
        let scaleY = rect.height / self.bounds.height
        
        for path in paths {
            guard path.points.count > 1 else { continue }
            
            let bezierPath = NSBezierPath()
            bezierPath.lineWidth = path.lineWidth * min(scaleX, scaleY)
            bezierPath.lineCapStyle = .round
            bezierPath.lineJoinStyle = .round
            
            // Scale and move first point
            let firstPoint = NSPoint(
                x: path.points[0].x * scaleX,
                y: path.points[0].y * scaleY
            )
            bezierPath.move(to: firstPoint)
            
            // Scale and add remaining points
            for i in 1..<path.points.count {
                let scaledPoint = NSPoint(
                    x: path.points[i].x * scaleX,
                    y: path.points[i].y * scaleY
                )
                bezierPath.line(to: scaledPoint)
            }
            
            path.color.setStroke()
            bezierPath.stroke()
        }
    }
    
    func clearDrawing() {
        saveToUndoStack()
        paths.removeAll()
        currentPath = nil
        redoStack.removeAll()
        updateUndoRedoState()

        // Cancel auto-clipboard timer when clearing
        cancelAutoClipboardTimer()

        // Notify that there are no edits
        onEditMade?(false)

        self.needsDisplay = true
    }

    // MARK: - Undo/Redo Methods

    private func saveToUndoStack() {
        undoStack.append(paths)
        // Limit undo stack to 50 actions to prevent memory issues
        if undoStack.count > 50 {
            undoStack.removeFirst()
        }
    }

    private func updateUndoRedoState() {
        let canUndo = !undoStack.isEmpty
        let canRedo = !redoStack.isEmpty
        onUndoRedoStateChanged?(canUndo, canRedo)
        
        // Also update edit state - if there are any paths, there are edits
        onEditMade?(!paths.isEmpty)
    }

    func undo() {
        guard !undoStack.isEmpty else {
            print("Nothing to undo")
            return
        }

        print("Undo - restoring previous state")
        // Save current state to redo stack
        redoStack.append(paths)
        // Restore previous state from undo stack
        paths = undoStack.removeLast()
        updateUndoRedoState()
        self.needsDisplay = true

        // Start auto-clipboard timer after undo
        print("Undo completed - starting 2-second auto-clipboard timer")
        startAutoClipboardTimer()
    }

    func redo() {
        guard !redoStack.isEmpty else {
            print("Nothing to redo")
            return
        }

        print("Redo - restoring next state")
        // Save current state to undo stack
        undoStack.append(paths)
        // Restore next state from redo stack
        paths = redoStack.removeLast()
        updateUndoRedoState()
        self.needsDisplay = true

        // Start auto-clipboard timer after redo
        print("Redo completed - starting 2-second auto-clipboard timer")
        startAutoClipboardTimer()
    }

    func canUndo() -> Bool {
        return !undoStack.isEmpty
    }

    func canRedo() -> Bool {
        return !redoStack.isEmpty
    }

    func getFinalImage() -> NSImage? {
        guard let backgroundImage = croppedImage else { return nil }

        let finalImage = NSImage(size: backgroundImage.size)
        finalImage.lockFocusFlipped(true)  // Use flipped coordinates to match DrawingView

        // Draw background
        backgroundImage.draw(in: NSRect(origin: .zero, size: backgroundImage.size))

        // Draw annotations scaled to image size
        drawAnnotations(in: NSRect(origin: .zero, size: backgroundImage.size))

        finalImage.unlockFocus()
        return finalImage
    }

    override var acceptsFirstResponder: Bool {
        return true
    }

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        return true
    }
}
