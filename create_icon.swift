#!/usr/bin/env swift

import Cocoa
import AppKit

// Create a camera icon for the app
func createCameraIcon(size: CGSize) -> NSImage {
    let image = NSImage(size: size)
    image.lockFocus()
    
    let ctx = NSGraphicsContext.current!.cgContext
    
    // Background - rounded square with gradient
    let rect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
    let cornerRadius = size.width * 0.2
    let path = NSBezierPath(roundedRect: rect, xRadius: cornerRadius, yRadius: cornerRadius)
    
    // Gradient background (blue to purple)
    let gradient = NSGradient(colors: [
        NSColor(red: 0.2, green: 0.5, blue: 1.0, alpha: 1.0),
        NSColor(red: 0.4, green: 0.3, blue: 0.9, alpha: 1.0)
    ])
    gradient?.draw(in: path, angle: 135)
    
    // Camera body (white)
    NSColor.white.setFill()
    
    let cameraWidth = size.width * 0.6
    let cameraHeight = size.height * 0.45
    let cameraX = (size.width - cameraWidth) / 2
    let cameraY = (size.height - cameraHeight) / 2
    
    let cameraBody = NSBezierPath(roundedRect: CGRect(x: cameraX, y: cameraY, width: cameraWidth, height: cameraHeight), 
                                   xRadius: size.width * 0.05, yRadius: size.width * 0.05)
    cameraBody.fill()
    
    // Camera lens (circle)
    let lensSize = size.width * 0.3
    let lensX = (size.width - lensSize) / 2
    let lensY = (size.height - lensSize) / 2
    
    // Outer lens ring (darker)
    NSColor(white: 0.3, alpha: 1.0).setFill()
    let outerLens = NSBezierPath(ovalIn: CGRect(x: lensX, y: lensY, width: lensSize, height: lensSize))
    outerLens.fill()
    
    // Inner lens (lighter)
    let innerLensSize = lensSize * 0.7
    let innerLensX = (size.width - innerLensSize) / 2
    let innerLensY = (size.height - innerLensSize) / 2
    NSColor(white: 0.5, alpha: 1.0).setFill()
    let innerLens = NSBezierPath(ovalIn: CGRect(x: innerLensX, y: innerLensY, width: innerLensSize, height: innerLensSize))
    innerLens.fill()
    
    // Lens reflection (small white circle)
    let reflectionSize = lensSize * 0.25
    let reflectionX = lensX + lensSize * 0.2
    let reflectionY = lensY + lensSize * 0.6
    NSColor(white: 1.0, alpha: 0.6).setFill()
    let reflection = NSBezierPath(ovalIn: CGRect(x: reflectionX, y: reflectionY, width: reflectionSize, height: reflectionSize))
    reflection.fill()
    
    // Viewfinder bump on top
    let bumpWidth = size.width * 0.25
    let bumpHeight = size.height * 0.12
    let bumpX = (size.width - bumpWidth) / 2
    let bumpY = cameraY + cameraHeight - bumpHeight * 0.3
    
    NSColor.white.setFill()
    let bump = NSBezierPath(roundedRect: CGRect(x: bumpX, y: bumpY, width: bumpWidth, height: bumpHeight),
                            xRadius: size.width * 0.03, yRadius: size.width * 0.03)
    bump.fill()
    
    // Flash indicator (small circle on top right)
    let flashSize = size.width * 0.08
    let flashX = cameraX + cameraWidth - flashSize * 1.5
    let flashY = cameraY + cameraHeight - flashSize * 1.2
    NSColor(red: 1.0, green: 0.9, blue: 0.3, alpha: 1.0).setFill()
    let flash = NSBezierPath(ovalIn: CGRect(x: flashX, y: flashY, width: flashSize, height: flashSize))
    flash.fill()
    
    image.unlockFocus()
    return image
}

// Create .icns file with multiple resolutions
func createIconSet() {
    let sizes: [CGFloat] = [16, 32, 64, 128, 256, 512, 1024]
    let iconsetPath = "AppIcon.iconset"
    
    // Create iconset directory
    try? FileManager.default.removeItem(atPath: iconsetPath)
    try! FileManager.default.createDirectory(atPath: iconsetPath, withIntermediateDirectories: true)
    
    for size in sizes {
        let image = createCameraIcon(size: CGSize(width: size, height: size))
        
        // Save standard resolution
        if let tiffData = image.tiffRepresentation,
           let bitmapImage = NSBitmapImageRep(data: tiffData),
           let pngData = bitmapImage.representation(using: .png, properties: [:]) {
            let filename = "icon_\(Int(size))x\(Int(size)).png"
            let path = "\(iconsetPath)/\(filename)"
            try! pngData.write(to: URL(fileURLWithPath: path))
            print("✓ Created \(filename)")
        }
        
        // Save @2x resolution (except for 1024 which doesn't have @2x)
        if size < 1024 {
            let image2x = createCameraIcon(size: CGSize(width: size * 2, height: size * 2))
            if let tiffData = image2x.tiffRepresentation,
               let bitmapImage = NSBitmapImageRep(data: tiffData),
               let pngData = bitmapImage.representation(using: .png, properties: [:]) {
                let filename = "icon_\(Int(size))x\(Int(size))@2x.png"
                let path = "\(iconsetPath)/\(filename)"
                try! pngData.write(to: URL(fileURLWithPath: path))
                print("✓ Created \(filename)")
            }
        }
    }
    
    print("\n📦 Converting to .icns format...")
    
    // Convert iconset to icns using iconutil
    let task = Process()
    task.launchPath = "/usr/bin/iconutil"
    task.arguments = ["-c", "icns", iconsetPath, "-o", "AppIcon.icns"]
    task.launch()
    task.waitUntilExit()
    
    if task.terminationStatus == 0 {
        print("✅ AppIcon.icns created successfully!")
        print("\n📁 Icon file: AppIcon.icns")
        
        // Clean up iconset directory
        try? FileManager.default.removeItem(atPath: iconsetPath)
        print("🧹 Cleaned up temporary files")
    } else {
        print("❌ Failed to create .icns file")
    }
}

// Run the icon creation
print("🎨 Creating app icon...")
print("")
createIconSet()
print("")
print("✨ Done! Use this icon in your app bundle.")

