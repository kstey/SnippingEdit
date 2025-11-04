#!/usr/bin/env swift

import Cocoa
import AppKit

// Create a clipboard icon with image/photo element
func createClipboardIcon(size: CGSize) -> NSImage {
    let image = NSImage(size: size)
    image.lockFocus()
    
    let ctx = NSGraphicsContext.current!.cgContext
    
    // Background - rounded square with gradient
    let rect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
    let cornerRadius = size.width * 0.2
    let path = NSBezierPath(roundedRect: rect, xRadius: cornerRadius, yRadius: cornerRadius)
    
    // Gradient background (teal to blue)
    let gradient = NSGradient(colors: [
        NSColor(red: 0.2, green: 0.7, blue: 0.9, alpha: 1.0),
        NSColor(red: 0.3, green: 0.5, blue: 1.0, alpha: 1.0)
    ])
    gradient?.draw(in: path, angle: 135)
    
    // Clipboard base (white rounded rectangle)
    NSColor.white.setFill()
    
    let clipboardWidth = size.width * 0.65
    let clipboardHeight = size.height * 0.7
    let clipboardX = (size.width - clipboardWidth) / 2
    let clipboardY = (size.height - clipboardHeight) / 2 - size.height * 0.05
    
    let clipboardBody = NSBezierPath(roundedRect: CGRect(x: clipboardX, y: clipboardY, 
                                                           width: clipboardWidth, height: clipboardHeight), 
                                     xRadius: size.width * 0.04, yRadius: size.width * 0.04)
    clipboardBody.fill()
    
    // Clipboard clip at top (dark gray)
    NSColor(white: 0.3, alpha: 1.0).setFill()
    let clipWidth = size.width * 0.25
    let clipHeight = size.height * 0.08
    let clipX = (size.width - clipWidth) / 2
    let clipY = clipboardY + clipboardHeight - clipHeight * 0.3
    
    let clip = NSBezierPath(roundedRect: CGRect(x: clipX, y: clipY, 
                                                  width: clipWidth, height: clipHeight),
                            xRadius: size.width * 0.02, yRadius: size.width * 0.02)
    clip.fill()
    
    // Image/photo icon on clipboard (light blue rectangle with mountain/sun symbol)
    let imageWidth = clipboardWidth * 0.7
    let imageHeight = clipboardHeight * 0.5
    let imageX = clipboardX + (clipboardWidth - imageWidth) / 2
    let imageY = clipboardY + (clipboardHeight - imageHeight) / 2 - size.height * 0.03
    
    // Image background (light blue)
    NSColor(red: 0.7, green: 0.85, blue: 1.0, alpha: 1.0).setFill()
    let imageRect = NSBezierPath(rect: CGRect(x: imageX, y: imageY, 
                                               width: imageWidth, height: imageHeight))
    imageRect.fill()
    
    // Simple mountain shape
    NSColor(red: 0.4, green: 0.6, blue: 0.9, alpha: 1.0).setFill()
    let mountain = NSBezierPath()
    mountain.move(to: CGPoint(x: imageX, y: imageY))
    mountain.line(to: CGPoint(x: imageX + imageWidth * 0.4, y: imageY + imageHeight * 0.6))
    mountain.line(to: CGPoint(x: imageX + imageWidth * 0.7, y: imageY))
    mountain.close()
    mountain.fill()
    
    // Sun (circle in top right)
    NSColor(red: 1.0, green: 0.9, blue: 0.3, alpha: 1.0).setFill()
    let sunSize = imageWidth * 0.2
    let sunX = imageX + imageWidth - sunSize - imageWidth * 0.1
    let sunY = imageY + imageHeight - sunSize - imageHeight * 0.1
    let sun = NSBezierPath(ovalIn: CGRect(x: sunX, y: sunY, width: sunSize, height: sunSize))
    sun.fill()
    
    // Target/crosshair overlay (centered on image area)
    // Represents screenshot/capture functionality
    let targetSize = min(imageWidth, imageHeight) * 0.5  // 1/2 of width/height
    let targetX = imageX + (imageWidth - targetSize) / 2
    let targetY = imageY + (imageHeight - targetSize) / 2
    
    // Outer circle (red/orange)
    NSColor(red: 1.0, green: 0.3, blue: 0.2, alpha: 0.8).setStroke()
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
    NSColor(red: 1.0, green: 0.3, blue: 0.2, alpha: 0.9).setFill()
    let dotSize = size.width * 0.015
    let dot = NSBezierPath(ovalIn: CGRect(x: centerX - dotSize/2, y: centerY - dotSize/2,
                                           width: dotSize, height: dotSize))
    dot.fill()
    
    image.unlockFocus()
    return image
}

// Create an animated version with a pulse/glow effect
func createAnimatedClipboardIcon(size: CGSize, pulseIntensity: CGFloat) -> NSImage {
    let image = NSImage(size: size)
    image.lockFocus()
    
    let ctx = NSGraphicsContext.current!.cgContext
    
    // Background - rounded square with brighter gradient for animation
    let rect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
    let cornerRadius = size.width * 0.2
    let path = NSBezierPath(roundedRect: rect, xRadius: cornerRadius, yRadius: cornerRadius)
    
    // Brighter gradient during pulse
    let brightness = 1.0 + pulseIntensity * 0.3
    let gradient = NSGradient(colors: [
        NSColor(red: 0.2 * brightness, green: 0.7 * brightness, blue: 0.9 * brightness, alpha: 1.0),
        NSColor(red: 0.3 * brightness, green: 0.5 * brightness, blue: 1.0 * brightness, alpha: 1.0)
    ])
    gradient?.draw(in: path, angle: 135)
    
    // Add glow effect
    if pulseIntensity > 0 {
        ctx.saveGState()
        ctx.setShadow(offset: .zero, blur: 20 * pulseIntensity, 
                      color: NSColor(red: 0.3, green: 0.7, blue: 1.0, alpha: pulseIntensity).cgColor)
        path.fill()
        ctx.restoreGState()
    }
    
    // Same clipboard design as base icon
    NSColor.white.setFill()
    
    let clipboardWidth = size.width * 0.65
    let clipboardHeight = size.height * 0.7
    let clipboardX = (size.width - clipboardWidth) / 2
    let clipboardY = (size.height - clipboardHeight) / 2 - size.height * 0.05
    
    let clipboardBody = NSBezierPath(roundedRect: CGRect(x: clipboardX, y: clipboardY, 
                                                           width: clipboardWidth, height: clipboardHeight), 
                                     xRadius: size.width * 0.04, yRadius: size.width * 0.04)
    clipboardBody.fill()
    
    NSColor(white: 0.3, alpha: 1.0).setFill()
    let clipWidth = size.width * 0.25
    let clipHeight = size.height * 0.08
    let clipX = (size.width - clipWidth) / 2
    let clipY = clipboardY + clipboardHeight - clipHeight * 0.3
    
    let clip = NSBezierPath(roundedRect: CGRect(x: clipX, y: clipY, 
                                                  width: clipWidth, height: clipHeight),
                            xRadius: size.width * 0.02, yRadius: size.width * 0.02)
    clip.fill()
    
    let imageWidth = clipboardWidth * 0.7
    let imageHeight = clipboardHeight * 0.5
    let imageX = clipboardX + (clipboardWidth - imageWidth) / 2
    let imageY = clipboardY + (clipboardHeight - imageHeight) / 2 - size.height * 0.03
    
    NSColor(red: 0.7, green: 0.85, blue: 1.0, alpha: 1.0).setFill()
    let imageRect = NSBezierPath(rect: CGRect(x: imageX, y: imageY, 
                                               width: imageWidth, height: imageHeight))
    imageRect.fill()
    
    NSColor(red: 0.4, green: 0.6, blue: 0.9, alpha: 1.0).setFill()
    let mountain = NSBezierPath()
    mountain.move(to: CGPoint(x: imageX, y: imageY))
    mountain.line(to: CGPoint(x: imageX + imageWidth * 0.4, y: imageY + imageHeight * 0.6))
    mountain.line(to: CGPoint(x: imageX + imageWidth * 0.7, y: imageY))
    mountain.close()
    mountain.fill()
    
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

// Generate .icns file
func generateIconSet() {
    let sizes: [Int] = [16, 32, 64, 128, 256, 512, 1024]
    let iconSet = NSMutableDictionary()
    
    print("Generating clipboard icon...")
    
    for size in sizes {
        let cgSize = CGSize(width: size, height: size)
        let icon = createClipboardIcon(size: cgSize)
        
        if let tiff = icon.tiffRepresentation,
           let bitmap = NSBitmapImageRep(data: tiff),
           let png = bitmap.representation(using: .png, properties: [:]) {
            let filename = "icon_\(size)x\(size).png"
            try? png.write(to: URL(fileURLWithPath: "/tmp/\(filename)"))
            print("Created \(filename)")
        }
    }
    
    // Create .icns using iconutil
    print("\nCreating .icns file...")
    print("Run these commands:")
    print("mkdir -p AppIcon.iconset")
    sizes.forEach { size in
        print("sips -s format png /tmp/icon_\(size)x\(size).png --out AppIcon.iconset/icon_\(size)x\(size).png")
        if size <= 512 {
            print("sips -s format png /tmp/icon_\(size)x\(size).png --out AppIcon.iconset/icon_\(size)x\(size)@2x.png")
        }
    }
    print("iconutil -c icns AppIcon.iconset -o AppIcon.icns")
    print("\nIcon files created in /tmp/")
}

generateIconSet()
