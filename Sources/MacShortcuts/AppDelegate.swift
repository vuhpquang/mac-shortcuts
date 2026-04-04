// AppDelegate.swift
// This is the entry point of GestureKit — the very first code macOS runs when the app launches.
// Think of it like the "main manager" that sets everything else up:
//   1. Creates the menu bar icon and menu (MenuBarController)
//   2. Checks if we have the Accessibility permission needed to send clicks/keys
//   3. Starts listening for trackpad gestures once permission is granted (GestureCoordinator)
// It also holds on to these objects so they're never accidentally thrown away by the system.

import AppKit
import ApplicationServices

// @NSApplicationMain is replaced by a manual entry point in main.swift for SPM builds.
// This class handles app lifecycle events sent by macOS.
class AppDelegate: NSObject, NSApplicationDelegate {

    // Strong references — keeping these as properties ensures they stay alive
    // for the entire lifetime of the app.
    private var menuBarController: MenuBarController!
    private var permissionsManager: PermissionsManager!

    // Called by macOS right after the app finishes launching.
    // This is the right place to do all one-time setup.
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Step 1: Create the menu bar icon and dropdown menu.
        menuBarController = MenuBarController()

        // Step 2: Set up the permissions manager.
        permissionsManager = PermissionsManager()

        // Step 3: Check if Accessibility permission is already granted.
        if PermissionsManager.isAccessibilityGranted() {
            // Permission already granted — start gesture detection immediately.
            startGestureEngine()
        } else {
            // Permission not yet granted.
            // Show a silent warning in the menu bar — do NOT auto-open System Settings,
            // because the user may have already granted it (each debug build gets a new
            // code signature so AXIsProcessTrusted() may briefly return false even when
            // the toggle is ON). The menu bar item lets them open Settings manually if needed.
            menuBarController.showPermissionWarning()

            permissionsManager.pollUntilGranted {
                self.menuBarController.hidePermissionWarning()
                self.startGestureEngine()
            }
        }
    }

    // Starts the gesture detection engine with the user's saved (or default) settings.
    private func startGestureEngine() {
        // Load the user's gesture→action mapping from storage (or use defaults on first run).
        let mapping = GestureMapping.load()

        // Apply the mapping and begin listening for trackpad gestures.
        GestureCoordinator.shared.updateMapping(mapping)
        GestureCoordinator.shared.start()
    }

    // Called when the user chooses "Quit GestureKit" from the menu.
    // NSApp.terminate(_:) eventually calls this method; cleanup happens here if needed.
    func applicationWillTerminate(_ notification: Notification) {
        GestureCoordinator.shared.stop()
    }
}
