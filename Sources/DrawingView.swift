import Cocoa

class DrawingView: NSView {
    
    var croppedImage: NSImage?
    var currentColor: NSColor = .red
    private var paths: [DrawingPath] = []
    private var currentPath: DrawingPath?
    
    private struct DrawingPath {
        var points: [NSPoint]
        var color: NSColor
        var lineWidth: CGFloat
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        // Draw the cropped image as background
        if let image = croppedImage {
            image.draw(in: self.bounds)
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
            paths.append(path)
        }
        
        currentPath = nil
        self.needsDisplay = true
    }
    
    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 { // Escape key
            print("ESC pressed in drawing view - minimizing window")
            self.window?.miniaturize(nil)
        } else if event.keyCode == 51 { // Delete key
            // Clear last drawn path
            if !paths.isEmpty {
                print("Delete pressed - removing last path")
                paths.removeLast()
                self.needsDisplay = true
            }
        } else if event.keyCode == 15 && event.modifierFlags.contains(.command) { // Cmd+R for clear all
            print("Cmd+R pressed - clearing all paths")
            paths.removeAll()
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
    
    override var acceptsFirstResponder: Bool {
        return true
    }
    
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        return true
    }
}
