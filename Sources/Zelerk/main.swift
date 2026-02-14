import AppKit

let app = NSApplication.shared
let delegate = ZelerkAppDelegate()
app.delegate = delegate

// Hide from Dock (menu bar app only)
app.setActivationPolicy(.accessory)

app.run()
