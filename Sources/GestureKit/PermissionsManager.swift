// PermissionsManager.swift
// This file handles the Accessibility permission that GestureKit needs to work.
// macOS requires apps to have "Accessibility" access before they can simulate
// mouse clicks or keyboard shortcuts on your behalf.
//
// What this file does:
//   - Checks whether permission has already been granted
//   - Shows the system dialog asking the user to grant permission
//   - Polls (checks every 2 seconds) until the user grants permission,
//     then calls a completion callback so the app can start gesture detection

import ApplicationServices
import Foundation

class PermissionsManager {

    // Checks right now whether Accessibility permission is granted.
    // Returns true if the app can post CGEvents; false if permission is missing.
    static func isAccessibilityGranted() -> Bool {
        return AXIsProcessTrusted()
    }

    // Shows the macOS "GestureKit would like to control this computer" permission dialog.
    // This does NOT block — it just triggers the system prompt to appear.
    // The user still has to manually go to System Settings to toggle the switch.
    func requestAccessibilityPermission() {
        // kAXTrustedCheckOptionPrompt = true tells macOS to show the permission dialog.
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        AXIsProcessTrustedWithOptions(options)
    }

    // Repeatedly checks every 2 seconds (on a background thread) whether
    // Accessibility permission has been granted. Once it is, calls `completion`
    // on the main thread so the app can safely update the UI and start gestures.
    //
    // Usage:
    //   permissionsManager.pollUntilGranted {
    //       // This runs on the main thread when permission is confirmed
    //       self.startGestureEngine()
    //   }
    func pollUntilGranted(completion: @escaping () -> Void) {
        // Run the polling loop on a background queue so it doesn't block the UI.
        DispatchQueue.global(qos: .background).async {
            while !PermissionsManager.isAccessibilityGranted() {
                // Wait 2 seconds before checking again.
                Thread.sleep(forTimeInterval: 2.0)
            }

            // Permission granted! Jump back to the main thread for UI/app updates.
            DispatchQueue.main.async {
                completion()
            }
        }
    }
}
