// Core/ActionExecutor.swift
// This file is responsible for actually DOING things — performing the system actions
// that correspond to detected gestures.
//
// When GestureCoordinator says "a gesture happened and its action is middleClick",
// ActionExecutor is what makes the middle click actually occur at the OS level.
//
// It uses CoreGraphics (CGEvent) to synthesize mouse and keyboard events — the same
// mechanism macOS uses internally. Accessibility permission is required for this to work,
// which is why PermissionsManager ensures it's granted before we start.

import AppKit
import CoreGraphics
import Foundation

// MARK: - ActionExecutor Singleton

class ActionExecutor {

    /// The single shared instance — access via ActionExecutor.shared.
    static let shared = ActionExecutor()

    private init() {}

    // MARK: - Main Entry Point

    /// Executes the given action immediately.
    /// This is called by GestureCoordinator whenever a gesture fires.
    func execute(_ action: GestureAction) {
        switch action {
        case .none:
            break  // Nothing to do

        case .middleClick:
            performMiddleClick()

        case .missionControl:
            performMissionControl()

        case .appExpose:
            performAppExpose()

        case .showDesktop:
            performShowDesktop()

        case .keystroke(let key, let modifiers):
            performKeystroke(key: key, modifiers: modifiers)

        case .openApp(let bundleID):
            performOpenApp(bundleID: bundleID)
        }
    }

    // MARK: - Middle Click

    /// Simulates a middle mouse button click (button 2) at the current cursor position.
    /// This is extremely useful for: opening links in new tabs, closing browser tabs,
    /// and any app that supports middle-click behavior.
    private func performMiddleClick() {
        let location = NSEvent.mouseLocation
        // CGEvent coordinates use top-left origin; NSEvent uses bottom-left.
        // Convert by flipping the Y axis using the screen height.
        let screenHeight = NSScreen.main?.frame.height ?? 0
        let cgLocation = CGPoint(x: location.x, y: screenHeight - location.y)

        let source = CGEventSource(stateID: .hidSystemState)

        // Post mouse button 2 (middle button) down.
        if let mouseDown = CGEvent(mouseEventSource: source,
                                    mouseType: .otherMouseDown,
                                    mouseCursorPosition: cgLocation,
                                    mouseButton: .center) {
            mouseDown.post(tap: .cghidEventTap)
        }

        // Post mouse button 2 up.
        if let mouseUp = CGEvent(mouseEventSource: source,
                                  mouseType: .otherMouseUp,
                                  mouseCursorPosition: cgLocation,
                                  mouseButton: .center) {
            mouseUp.post(tap: .cghidEventTap)
        }
    }

    // MARK: - Mission Control

    /// Activates Mission Control — the macOS overview of all open windows and Spaces.
    /// Uses Control+Up, the default Mission Control keyboard shortcut.
    private func performMissionControl() {
        let source = CGEventSource(stateID: .hidSystemState)
        let upArrow: CGKeyCode = 126  // kVK_UpArrow
        if let down = CGEvent(keyboardEventSource: source, virtualKey: upArrow, keyDown: true) {
            down.flags = .maskControl
            down.post(tap: .cghidEventTap)
        }
        if let up = CGEvent(keyboardEventSource: source, virtualKey: upArrow, keyDown: false) {
            up.flags = .maskControl
            up.post(tap: .cghidEventTap)
        }
    }

    // MARK: - App Exposé

    /// Shows all windows of the currently active application (App Exposé).
    /// Uses Ctrl+Down arrow, which is the default keyboard shortcut for App Exposé.
    private func performAppExpose() {
        // App Exposé shortcut: Control + Down Arrow
        let source = CGEventSource(stateID: .hidSystemState)
        let downArrowKeyCode: CGKeyCode = 125  // kVK_DownArrow

        if let keyDown = CGEvent(keyboardEventSource: source, virtualKey: downArrowKeyCode, keyDown: true) {
            keyDown.flags = .maskControl
            keyDown.post(tap: .cghidEventTap)
        }
        if let keyUp = CGEvent(keyboardEventSource: source, virtualKey: downArrowKeyCode, keyDown: false) {
            keyUp.flags = .maskControl
            keyUp.post(tap: .cghidEventTap)
        }
    }

    // MARK: - Show Desktop

    /// Moves all windows aside to show the Desktop.
    /// Uses Control+F3 (Show Desktop), falling back to the dedicated virtual key if needed.
    private func performShowDesktop() {
        // Show Desktop default shortcut on macOS: Cmd+Mission Control (Ctrl+Up mapped differently).
        // The most compatible approach is F11, which is the classic Show Desktop shortcut.
        let source = CGEventSource(stateID: .hidSystemState)
        let f11: CGKeyCode = 103  // kVK_F11
        if let down = CGEvent(keyboardEventSource: source, virtualKey: f11, keyDown: true) {
            down.post(tap: .cghidEventTap)
        }
        if let up = CGEvent(keyboardEventSource: source, virtualKey: f11, keyDown: false) {
            up.post(tap: .cghidEventTap)
        }
    }

    // MARK: - Custom Keystroke

    /// Sends a custom key press with optional modifier keys (Cmd, Shift, Option, Control).
    /// For example: key="f", modifiers=[.command] sends Cmd+F (Find).
    private func performKeystroke(key: String, modifiers: NSEvent.ModifierFlags) {
        guard !key.isEmpty, let character = key.unicodeScalars.first else { return }

        let source = CGEventSource(stateID: .hidSystemState)

        // Create a key-down event from the Unicode character.
        if let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: true) {
            var uniChar = UniChar(character.value)
            keyDown.keyboardSetUnicodeString(stringLength: 1, unicodeString: &uniChar)
            // Convert NSEvent.ModifierFlags to CGEventFlags.
            keyDown.flags = cgFlags(from: modifiers)
            keyDown.post(tap: .cghidEventTap)
        }

        if let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: false) {
            var uniChar = UniChar(character.value)
            keyUp.keyboardSetUnicodeString(stringLength: 1, unicodeString: &uniChar)
            keyUp.flags = cgFlags(from: modifiers)
            keyUp.post(tap: .cghidEventTap)
        }
    }

    /// Converts NSEvent.ModifierFlags to the equivalent CGEventFlags.
    private func cgFlags(from modifiers: NSEvent.ModifierFlags) -> CGEventFlags {
        var flags: CGEventFlags = []
        if modifiers.contains(.command) { flags.insert(.maskCommand) }
        if modifiers.contains(.shift)   { flags.insert(.maskShift) }
        if modifiers.contains(.option)  { flags.insert(.maskAlternate) }
        if modifiers.contains(.control) { flags.insert(.maskControl) }
        return flags
    }

    // MARK: - Open Application

    /// Launches or brings to the foreground an application by its bundle identifier.
    /// The bundle ID is a unique string like "com.apple.Safari" or "com.google.Chrome".
    private func performOpenApp(bundleID: String) {
        guard !bundleID.isEmpty else { return }

        // NSWorkspace handles app launching — it takes care of finding the app on disk.
        if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) {
            let config = NSWorkspace.OpenConfiguration()
            config.activates = true  // Bring the app to the front if already running.
            NSWorkspace.shared.openApplication(at: url, configuration: config) { _, error in
                if let error = error {
                    print("[MacShortcuts] ActionExecutor: Could not open \(bundleID): \(error)")
                }
            }
        } else {
            print("[MacShortcuts] ActionExecutor: App not found for bundle ID: \(bundleID)")
        }
    }
}
