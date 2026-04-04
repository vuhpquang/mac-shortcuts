// MenuBarController.swift
// This file controls the little icon that appears in the macOS menu bar (top-right area).
// When you click the icon, a dropdown menu appears with three options:
//   • "Settings…" — opens the settings window where you configure gestures
//   • A separator line
//   • "Quit GestureKit" — exits the app
// If Accessibility permission is missing, an extra "Enable Accessibility…" item
// appears at the top as a warning, and the icon gets an amber tint.

import AppKit
import SwiftUI

class MenuBarController {

    // NSStatusItem is the actual object that lives in the menu bar.
    // "variableLength" means macOS decides how wide to make the icon slot.
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

    // The dropdown menu that appears when the user clicks the icon.
    private let menu = NSMenu()

    // The "Enable Accessibility…" warning item — only shown when permission is missing.
    private var accessibilityWarningItem: NSMenuItem?

    // Reference to the Settings window — kept weak so it can be released when closed.
    private weak var settingsWindow: NSWindow?

    init() {
        setupIcon()
        setupMenu()
    }

    // MARK: - Icon Setup

    private func setupIcon() {
        guard let button = statusItem.button else { return }

        // Use an SF Symbol hand icon as the menu bar icon.
        // "hand.point.up.left" looks like a pointing finger — fitting for a gesture app.
        // .template rendering mode makes it automatically adapt to light/dark menu bars.
        if let image = NSImage(systemSymbolName: "hand.point.up.left", accessibilityDescription: "GestureKit") {
            image.isTemplate = true  // Allows macOS to tint it automatically
            button.image = image
        }

        button.toolTip = "GestureKit — Trackpad Gesture Manager"
        button.action = #selector(statusItemClicked)
        button.target = self
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
    }

    // MARK: - Menu Setup

    private func setupMenu() {
        // "Settings…" opens the configuration window.
        let settingsItem = NSMenuItem(title: "Settings\u{2026}", action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)

        // Visual separator between settings and quit.
        menu.addItem(NSMenuItem.separator())

        // "Quit GestureKit" exits the app cleanly.
        let quitItem = NSMenuItem(title: "Quit GestureKit", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
    }

    // MARK: - Permission Warning

    // Shows an amber-tinted icon and an "Enable Accessibility…" menu item
    // when the app hasn't been granted Accessibility permission yet.
    func showPermissionWarning() {
        guard accessibilityWarningItem == nil else { return }

        // Tint the icon amber to indicate something needs attention.
        tintIcon(color: .systemOrange)

        // Insert the warning item at the very top of the menu.
        let warningItem = NSMenuItem(
            title: "Enable Accessibility\u{2026}",
            action: #selector(openAccessibilitySettings),
            keyEquivalent: ""
        )
        warningItem.target = self
        // Add a warning symbol to make it visually distinct.
        warningItem.image = NSImage(systemSymbolName: "exclamationmark.triangle.fill",
                                     accessibilityDescription: "Warning")
        menu.insertItem(warningItem, at: 0)
        menu.insertItem(NSMenuItem.separator(), at: 1)
        accessibilityWarningItem = warningItem
    }

    // Removes the warning once the user grants Accessibility permission.
    func hidePermissionWarning() {
        guard let warningItem = accessibilityWarningItem else { return }

        // Remove the warning item and the separator below it.
        if let index = menu.items.firstIndex(of: warningItem) {
            menu.removeItem(at: index)
            if index < menu.items.count && menu.items[index].isSeparatorItem {
                menu.removeItem(at: index)
            }
        }
        accessibilityWarningItem = nil

        // Restore the neutral icon tint.
        resetIconTint()
    }

    // MARK: - Icon Tinting

    private func tintIcon(color: NSColor) {
        guard let button = statusItem.button else { return }
        button.contentTintColor = color
    }

    private func resetIconTint() {
        guard let button = statusItem.button else { return }
        button.contentTintColor = nil  // nil = use the system default (adapts to dark/light)
    }

    // MARK: - Actions

    @objc private func statusItemClicked() {
        // Menu is attached directly, so clicking automatically shows it.
        // This action handler exists for future customisation if needed.
    }

    // Opens the GestureKit Settings window (480x520, floating, single instance).
    @objc func openSettings() {
        if let existing = settingsWindow, existing.isVisible {
            // Bring the existing window to the front instead of opening a second one.
            existing.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        // Create the SwiftUI settings view hosted inside an AppKit window.
        let settingsView = SettingsView()
        let hostingController = NSHostingController(rootView: settingsView)

        // Fixed 480x520 window — no resize, no minimize, no full-screen.
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 520),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "GestureKit Settings"
        window.contentViewController = hostingController
        window.level = .floating     // Stays above normal windows
        window.center()              // Center on screen
        window.isReleasedWhenClosed = false  // Keep the window object alive

        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        settingsWindow = window
    }

    // Opens System Settings directly to the Accessibility pane.
    @objc private func openAccessibilitySettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(url)
    }

    // Exits the application.
    @objc private func quitApp() {
        NSApp.terminate(nil)
    }
}
