import AppKit

if CommandLine.arguments.contains("--cleanup-login-item") ||
   CommandLine.arguments.contains("--uninstall-login-item") ||
   CommandLine.arguments.contains("--uninstall") {
    AppDelegate.cleanupLoginItem()
    exit(0)
}

// Use NSApplication.run() directly — lighter than NSApplicationMain which
// tries to load main NIB from Info.plist (we have none).
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
