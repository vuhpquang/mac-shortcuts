// Core/GestureCoordinator.swift
// This file is the central hub that connects all the pieces of GestureKit together.
//
// Think of it as an air traffic controller:
//   • DeviceMonitor sends raw finger data → GestureRecognizer
//   • GestureRecognizer recognizes gestures → GestureCoordinator (here)
//   • GestureCoordinator looks up what action the user configured → ActionExecutor
//   • ActionExecutor performs the actual system action (middle click, Mission Control, etc.)
//
// GestureCoordinator is a singleton — there's exactly one instance for the entire app,
// and it lives for the entire time the app is running. AppDelegate starts/stops it.

import Foundation

// MARK: - GestureCoordinator Singleton

class GestureCoordinator: GestureRecognizerDelegate {

    // MARK: - Singleton

    /// The single shared instance. Use GestureCoordinator.shared everywhere.
    static let shared = GestureCoordinator()

    // MARK: - Owned Components

    /// Listens to the trackpad hardware and delivers raw finger data.
    private let deviceMonitor = DeviceMonitor()

    /// Converts raw finger data into recognized gesture events.
    private let gestureRecognizer = GestureRecognizer()

    // MARK: - State

    /// The current gesture→action mapping. Updated by SettingsView when the user changes settings.
    private var mapping: GestureMapping = .defaults

    /// Whether the gesture pipeline is currently running.
    private(set) var isRunning = false

    // MARK: - Initialization

    private init() {
        // Wire up the pipeline:
        // DeviceMonitor → GestureRecognizer → GestureCoordinator
        deviceMonitor.delegate = gestureRecognizer
        gestureRecognizer.delegate = self
    }

    // MARK: - Lifecycle

    /// Starts the gesture detection pipeline.
    /// Call this after Accessibility permission is confirmed.
    func start() {
        guard !isRunning else { return }
        deviceMonitor.start()
        isRunning = true
        print("[MacShortcuts] GestureCoordinator: Started.")
    }

    /// Stops the gesture detection pipeline.
    /// Called on app quit or when you want to pause gesture detection.
    func stop() {
        guard isRunning else { return }
        deviceMonitor.stop()
        isRunning = false
        print("[MacShortcuts] GestureCoordinator: Stopped.")
    }

    // MARK: - Mapping Hot-Swap

    /// Updates the active gesture→action mapping without restarting the pipeline.
    /// Called by SettingsView whenever the user changes a gesture's assigned action,
    /// so changes take effect immediately without requiring a restart.
    func updateMapping(_ newMapping: GestureMapping) {
        mapping = newMapping
        print("[MacShortcuts] GestureCoordinator: Mapping updated.")
    }

    // MARK: - GestureRecognizerDelegate

    /// Called by GestureRecognizer whenever a gesture is recognized.
    /// Looks up the corresponding action in the current mapping and executes it.
    func didRecognize(gesture: GestureEvent) {
        let action = mapping.action(for: gesture)

        // Skip if this gesture slot is unmapped (action = .none).
        guard action != .none else { return }

        print("[MacShortcuts] GestureCoordinator: Gesture \(gesture) → Action \(action.displayName)")

        // Some actions (like opening a window) need to run on the main thread.
        // We dispatch everything to main to be safe — CGEvents work from any thread,
        // but NSWorkspace and UI calls require main.
        DispatchQueue.main.async {
            ActionExecutor.shared.execute(action)
        }
    }
}
