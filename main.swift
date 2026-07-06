import AppKit

if CommandLine.arguments.contains("--cleanup-login-item") ||
   CommandLine.arguments.contains("--uninstall-login-item") ||
   CommandLine.arguments.contains("--uninstall") {
    AppDelegate.cleanupLoginItem()
    exit(0)
}

// Prevent duplicate instances: terminate any other running copies of this app
// so only one menu bar item is ever present. The freshly launched process wins,
// which lets reinstalls/updates seamlessly replace an already-running instance.
let bundleID = Bundle.main.bundleIdentifier ?? "com.openhoangnc.macstats"
let currentPID = ProcessInfo.processInfo.processIdentifier
let otherInstances = NSRunningApplication.runningApplications(withBundleIdentifier: bundleID)
    .filter { $0.processIdentifier != currentPID }
if !otherInstances.isEmpty {
    otherInstances.forEach { $0.terminate() }
    // Give the old instances a brief window to release their status items.
    let deadline = Date().addingTimeInterval(2.0)
    while Date() < deadline,
          NSRunningApplication.runningApplications(withBundleIdentifier: bundleID)
            .contains(where: { $0.processIdentifier != currentPID && !$0.isTerminated }) {
        RunLoop.current.run(until: Date().addingTimeInterval(0.1))
    }
    // Force-terminate anything still lingering.
    NSRunningApplication.runningApplications(withBundleIdentifier: bundleID)
        .filter { $0.processIdentifier != currentPID && !$0.isTerminated }
        .forEach { $0.forceTerminate() }
}

// Use NSApplication.run() directly — lighter than NSApplicationMain which
// tries to load main NIB from Info.plist (we have none).
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
