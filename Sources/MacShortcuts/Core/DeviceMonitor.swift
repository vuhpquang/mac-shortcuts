// Core/DeviceMonitor.swift
// This file listens to your MacBook's trackpad hardware and collects raw finger data.
//
// Here's what it does step by step:
//   1. Asks MultitouchSupport for a list of all connected trackpad devices
//   2. For each device, registers a "callback" function — basically saying
//      "whenever new finger data arrives, call THIS function"
//   3. Starts the data stream from each device
//   4. Converts the raw C-style finger data into Swift-friendly arrays
//   5. Passes the finger data to its delegate (GestureRecognizer) for analysis
//
// This is the lowest level of the gesture pipeline — everything above it
// works with clean Swift data, not raw hardware callbacks.

import Foundation

// MARK: - Delegate Protocol

/// Any object that wants to receive raw finger data implements this protocol.
/// In practice, GestureRecognizer is the delegate.
protocol DeviceMonitorDelegate: AnyObject {
    /// Called every time a new batch of finger data arrives from the trackpad.
    /// - Parameters:
    ///   - fingers: Array of finger contact data for this frame.
    ///   - timestamp: When this frame was captured (seconds since boot).
    func didReceiveFingers(_ fingers: [MTFinger], timestamp: Double)
}

// MARK: - Module-level monitor reference
//
// C callbacks cannot capture Swift objects. We keep a module-level weak reference
// to the active DeviceMonitor so the @convention(c) callback can reach it safely.
// This is safe because DeviceMonitor is used as a singleton by GestureCoordinator.
private weak var _activeMonitor: DeviceMonitor?

// MARK: - DeviceMonitor

class DeviceMonitor {

    /// The object that will receive finger data. Set this to GestureRecognizer.
    weak var delegate: DeviceMonitorDelegate?

    /// All trackpad devices currently being monitored.
    private var devices: [MTDevice] = []

    /// Whether monitoring is currently active.
    private(set) var isRunning = false

    // MARK: - Lifecycle

    /// Starts listening for trackpad touch events.
    /// Does nothing if MultitouchSupport failed to load.
    func start() {
        let fw = MultitouchFramework.shared
        guard fw.isAvailable else {
            print("[MacShortcuts] DeviceMonitor: MultitouchSupport unavailable, skipping start.")
            return
        }
        guard !isRunning else { return }

        // Publish self so the C callback can find us.
        _activeMonitor = self

        // Get all connected trackpad devices.
        guard let deviceList = fw.MTDeviceCreateList?() as? [MTDevice] else {
            print("[MacShortcuts] DeviceMonitor: No trackpad devices found.")
            return
        }

        guard !deviceList.isEmpty else {
            print("[MacShortcuts] DeviceMonitor: Device list is empty.")
            return
        }

        devices = deviceList

        for device in devices {
            fw.MTRegisterContactFrameCallback?(device, deviceTouchCallback)
            fw.MTDeviceStart?(device)
        }

        isRunning = true
        print("[MacShortcuts] DeviceMonitor: Started monitoring \(devices.count) device(s).")
    }

    /// Stops listening for trackpad touch events.
    func stop() {
        let fw = MultitouchFramework.shared
        guard fw.isAvailable, isRunning else { return }

        for device in devices {
            fw.MTDeviceStop?(device)
        }

        devices.removeAll()
        _activeMonitor = nil
        isRunning = false
        print("[MacShortcuts] DeviceMonitor: Stopped.")
    }
}

// MARK: - C-Compatible Touch Callback
//
// This function is called by MultitouchSupport on every touch frame.
// It MUST be @convention(c) — it cannot capture any Swift variables.
// It reaches the DeviceMonitor through the module-level _activeMonitor reference.
private let deviceTouchCallback: MTContactFrameCallback = { _device, fingerData, fingerCount, timestamp, _ in
    guard let monitor = _activeMonitor else { return }
    guard fingerCount > 0 else { return }

    // Bind the raw pointer to MTFinger and build a Swift Array.
    let fingersPtr = fingerData.assumingMemoryBound(to: MTFinger.self)
    let fingers = Array(UnsafeBufferPointer(start: fingersPtr, count: Int(fingerCount)))

    // Forward to the delegate (GestureRecognizer) — still on the callback thread.
    monitor.delegate?.didReceiveFingers(fingers, timestamp: timestamp)
}
