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

    // Use flipped coordinates (top-left origin) for easier image alignment
    override var isFlipped: Bool {
        return true
    }

    private struct DrawingPath {
        var points: [NSPoint]
        var color: NSColor
        var lineWidth: CGFloat
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
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
        }

        currentPath = nil
        self.needsDisplay = true
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
