import Cocoa

class CropView: NSView {
    
    weak var delegate: CropViewDelegate?
    var screenshotImage: NSImage?
    
    private var startPoint: NSPoint = NSPoint.zero
    private var currentPoint: NSPoint = NSPoint.zero
    private var isDragging: Bool = false
    private var selectionRect: NSRect = NSRect.zero
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        // Draw the screenshot as background
        if let image = screenshotImage {
            image.draw(in: self.bounds)
        }
        
        // Draw overlay
        if isDragging || !selectionRect.isEmpty {
            drawOverlay()
        }
    }
    
    private func drawOverlay() {
        // Draw semi-transparent overlay over entire view
        NSColor.black.withAlphaComponent(0.3).setFill()
        self.bounds.fill()
        
        // Clear the selection area
        if !selectionRect.isEmpty {
            NSColor.clear.setFill()
            selectionRect.fill(using: .copy)
            
            // Draw selection border
            NSColor.white.setStroke()
            let borderPath = NSBezierPath(rect: selectionRect)
            borderPath.lineWidth = 2.0
            borderPath.stroke()
            
            // Draw corner handles
            drawCornerHandles()
        }
    }
    
    private func drawCornerHandles() {
        let handleSize: CGFloat = 8
        let handles = [
            NSRect(x: selectionRect.minX - handleSize/2, y: selectionRect.minY - handleSize/2, width: handleSize, height: handleSize),
            NSRect(x: selectionRect.maxX - handleSize/2, y: selectionRect.minY - handleSize/2, width: handleSize, height: handleSize),
            NSRect(x: selectionRect.minX - handleSize/2, y: selectionRect.maxY - handleSize/2, width: handleSize, height: handleSize),
            NSRect(x: selectionRect.maxX - handleSize/2, y: selectionRect.maxY - handleSize/2, width: handleSize, height: handleSize)
        ]
        
        NSColor.white.setFill()
        NSColor.black.setStroke()
        
        for handle in handles {
            let handlePath = NSBezierPath(ovalIn: handle)
            handlePath.fill()
            handlePath.lineWidth = 1.0
            handlePath.stroke()
        }
    }
    
    override func mouseDown(with event: NSEvent) {
        let locationInView = self.convert(event.locationInWindow, from: nil)
        startPoint = locationInView
        currentPoint = locationInView
        isDragging = true
        selectionRect = NSRect.zero
        
        self.needsDisplay = true
    }
    
    override func mouseDragged(with event: NSEvent) {
        guard isDragging else { return }
        
        let locationInView = self.convert(event.locationInWindow, from: nil)
        currentPoint = locationInView
        
        // Calculate selection rectangle
        let minX = min(startPoint.x, currentPoint.x)
        let minY = min(startPoint.y, currentPoint.y)
        let maxX = max(startPoint.x, currentPoint.x)
        let maxY = max(startPoint.y, currentPoint.y)
        
        selectionRect = NSRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
        
        self.needsDisplay = true
    }
    
    override func mouseUp(with event: NSEvent) {
        guard isDragging else { return }
        
        isDragging = false
        
        // Ensure minimum selection size
        if selectionRect.width > 10 && selectionRect.height > 10 {
            // Convert to screen coordinates for the delegate
            let screenRect = self.convert(selectionRect, to: nil)
            delegate?.cropDidComplete(croppedRect: screenRect)
        } else {
            // Reset if selection is too small
            selectionRect = NSRect.zero
            self.needsDisplay = true
        }
    }
    
    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 { // Escape key
            print("ESC pressed in crop view - minimizing window")
            self.window?.miniaturize(nil)
        } else if event.keyCode == 36 { // Enter key
            if !selectionRect.isEmpty {
                let screenRect = self.convert(selectionRect, to: nil)
                delegate?.cropDidComplete(croppedRect: screenRect)
            }
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
}
