import Cocoa

let app = NSApplication.shared
let delegate = EyeBreakAppDelegate()
app.delegate = delegate

// Desktop-like behavior so UI panels can receive clicks.
// Accessory app: shows in menu bar, not in Dock.
app.setActivationPolicy(.accessory)
app.run()
