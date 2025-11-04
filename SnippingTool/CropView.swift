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
            // Pass the selection rect directly (already in view coordinates)
            delegate?.cropDidComplete(croppedRect: selectionRect)
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
                // Pass the selection rect directly (already in view coordinates)
                delegate?.cropDidComplete(croppedRect: selectionRect)
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
        
        // NSView coordinate system: origin at bottom-left, y increases upward
        // Screen/CGImage coordinate system: origin at top-left, y increases downward
        // When we display the image with draw(in:), NSImage flips it for us
        // But the underlying CGImage data is still in screen coordinates
        
        // Convert from NSView coordinates (bottom-left) to CGImage coordinates (top-left)
        // selectionRect.minY = distance from bottom of view
        // We want distance from top of image = viewHeight - (selectionRect.minY + selectionRect.height)
        let imageY = (viewSize.height - selectionRect.minY - selectionRect.height) * scaleY
        let imageX = selectionRect.minX * scaleX
        let imageWidth = selectionRect.width * scaleX
        let imageHeight = selectionRect.height * scaleY
        
        print("=== Crop Debug ===")
        print("Selection rect: \(selectionRect)")
        print("View size: \(viewSize)")
        print("Image size: \(imageSize)")
        print("Calculated crop: x=\(imageX), y=\(imageY), w=\(imageWidth), h=\(imageHeight)")
        
        // Get CGImage representation
        guard let tiffData = originalImage.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData),
              let cgImage = bitmap.cgImage else {
            print("Failed to get CGImage")
            return nil
        }
        
        // Crop using CGImage (unambiguous coordinate system)
        let cropRect = CGRect(x: imageX, y: imageY, width: imageWidth, height: imageHeight)
        
        guard let croppedCGImage = cgImage.cropping(to: cropRect) else {
            print("Failed to crop CGImage")
            return nil
        }
        
        // Convert back to NSImage
        let croppedImage = NSImage(cgImage: croppedCGImage, size: NSSize(width: imageWidth, height: imageHeight))
        
        return croppedImage
    }
    
    override var acceptsFirstResponder: Bool {
        return true
    }
    
    // MARK: - Reset State
    func resetState() {
        startPoint = NSPoint.zero
        currentPoint = NSPoint.zero
        isDragging = false
        selectionRect = NSRect.zero
        self.needsDisplay = true
    }
}
