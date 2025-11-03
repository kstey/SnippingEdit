import Cocoa

class ViewController: NSViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // This view controller is mainly for storyboard compatibility
        // The main functionality is handled by AppDelegate and ScreenshotWindow
    }

    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
        }
    }
}
