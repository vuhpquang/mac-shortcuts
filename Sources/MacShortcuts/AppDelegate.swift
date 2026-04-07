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
        // Install the click suppressor early so the CGEventTap is ready before
        // any force-click gestures are detected. Accessing the singleton is enough.
        _ = ClickSuppressor.shared

        // Step 1: Create the menu bar icon and dropdown menu.
        menuBarController = MenuBarController()

        // Step 2: Set up the permissions manager.
        permissionsManager = PermissionsManager()

        // Step 3: Check if Accessibility permission is already granted.
        if PermissionsManager.isAccessibilityGranted() {
            // Permission already granted — start gesture detection immediately.
            startGestureEngine()
        } else {
            // Permission not yet granted — show System Settings prompt and the menu warning.
            permissionsManager.requestAccessibilityPermission()
            menuBarController.showPermissionWarning()

            permissionsManager.pollUntilGranted {
                self.menuBarController.hidePermissionWarning()
                self.startGestureEngine()
            }
        }

        // Listen for machine sleep/wake so we can restart the gesture engine after wake.
        // MT device handles and CGEventTaps both become stale after sleep.
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(machineWillSleep),
            name: NSWorkspace.willSleepNotification,
            object: nil
        )
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(machineDidWake),
            name: NSWorkspace.didWakeNotification,
            object: nil
        )
    }

    @objc private func machineWillSleep(_ note: Notification) {
        print("[MacShortcuts] AppDelegate: Machine sleeping — stopping gesture engine.")
        GestureCoordinator.shared.stop()
    }

    @objc private func machineDidWake(_ note: Notification) {
        print("[MacShortcuts] AppDelegate: Machine woke — restarting gesture engine.")
        // Give the OS a moment to restore HID services before we re-enumerate devices.
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            guard PermissionsManager.isAccessibilityGranted() else { return }
            ClickSuppressor.shared.reinstall()
            GestureCoordinator.shared.start()
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
