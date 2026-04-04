// PermissionsManager.swift
// Handles Accessibility permission — required to post CGEvents (clicks, keystrokes).

import ApplicationServices
import AppKit
import Foundation

class PermissionsManager {

    // Force a fresh check (not cached) by passing options with prompt=false.
    static func isAccessibilityGranted() -> Bool {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: false] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }

    // Shows the system permission dialog.
    func requestAccessibilityPermission() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        AXIsProcessTrustedWithOptions(options)
    }

    // Polls every 1 second until Accessibility is granted, then calls completion on main thread.
    // If permission is still not detected after 60 s (user may have granted but macOS cached
    // the old state), shows a "please restart" alert as a fallback.
    func pollUntilGranted(completion: @escaping () -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            // Check quickly at first so an already-granted permission is detected immediately.
            var checks = 0
            while !PermissionsManager.isAccessibilityGranted() {
                let interval: TimeInterval = checks < 10 ? 0.5 : 2.0
                Thread.sleep(forTimeInterval: interval)
                checks += 1
                // After ~60 s of polling with no result, offer a restart — some macOS
                // versions don't propagate the grant to an already-running process.
                if checks == 40 {
                    DispatchQueue.main.async { PermissionsManager.showRestartAlert() }
                }
            }
            DispatchQueue.main.async { completion() }
        }
    }

    // Some macOS versions (and ad-hoc signed / Xcode-run builds) don't propagate the
    // Accessibility grant to the live process. A restart always works.
    static func showRestartAlert() {
        let alert = NSAlert()
        alert.messageText = "Restart Required"
        alert.informativeText = "Mac Shortcuts needs to restart to activate after Accessibility permission is granted. Please quit and reopen the app."
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Quit & Reopen")
        alert.addButton(withTitle: "Keep Waiting")
        if alert.runModal() == .alertFirstButtonReturn {
            // Relaunch self.
            let url = Bundle.main.bundleURL
            let config = NSWorkspace.OpenConfiguration()
            NSWorkspace.shared.openApplication(at: url, configuration: config) { _, _ in }
            NSApp.terminate(nil)
        }
    }
}
