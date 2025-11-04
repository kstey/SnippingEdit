import Cocoa

// Create and run the application
let app = NSApplication.shared
let delegate = AppDelegate()  // Use clipboard-only version
app.delegate = delegate

// Run the app
app.run()
