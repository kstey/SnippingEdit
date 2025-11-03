import Cocoa

// Create and run the application
let app = NSApplication.shared
let delegate = AppDelegateSimple()  // Use the simpler version for now
app.delegate = delegate

// Run the app
app.run()
