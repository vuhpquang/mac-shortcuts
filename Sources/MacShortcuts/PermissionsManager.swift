import ApplicationServices
import AppKit
import Foundation

class PermissionsManager {

    // Plain AXIsProcessTrusted() is the most reliable check.
    // AXIsProcessTrustedWithOptions introduced caching issues on newer macOS.
    static func isAccessibilityGranted() -> Bool {
        return AXIsProcessTrusted()
    }

    // Opens System Settings → Accessibility so the user can grant permission.
    func requestAccessibilityPermission() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        AXIsProcessTrustedWithOptions(options)
    }

    // Polls until Accessibility is granted, then calls completion on the main thread.
    // NOTE: When running as a raw binary (Xcode debug build, no .app bundle), macOS
    // does NOT update AXIsProcessTrusted() for the live process after the user grants
    // permission — a restart is required in that case.
    // When running as a proper .app bundle (DMG release), detection works live.
    func pollUntilGranted(completion: @escaping () -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            var checks = 0
            while !AXIsProcessTrusted() {
                Thread.sleep(forTimeInterval: 1.0)
                checks += 1
                // After ~30 s show a restart prompt — the user has likely granted
                // but the live process can't detect it (no .app bundle).
                if checks == 30 {
                    DispatchQueue.main.async { PermissionsManager.showRestartPrompt() }
                }
            }
            DispatchQueue.main.async { completion() }
        }
    }

    static func showRestartPrompt() {
        let alert = NSAlert()
        alert.messageText = "Restart Required"
        alert.informativeText = "Permission has been granted, but Mac Shortcuts needs to restart to activate it. Click Restart to relaunch automatically."
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Restart Now")
        alert.addButton(withTitle: "Later")
        if alert.runModal() == .alertFirstButtonReturn {
            let url = Bundle.main.bundleURL
            let config = NSWorkspace.OpenConfiguration()
            NSWorkspace.shared.openApplication(at: url, configuration: config) { _, _ in }
            NSApp.terminate(nil)
        }
    }
}
