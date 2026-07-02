import AppKit

if CommandLine.arguments.contains("--cleanup-login-item") ||
   CommandLine.arguments.contains("--uninstall-login-item") ||
   CommandLine.arguments.contains("--uninstall") {
    AppDelegate.cleanupLoginItem()
    exit(0)
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
_ = NSApplicationMain(CommandLine.argc, CommandLine.unsafeArgv)
