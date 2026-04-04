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
            print("[GestureKit] DeviceMonitor: MultitouchSupport unavailable, skipping start.")
            return
        }
        guard !isRunning else { return }

        // Get all connected trackpad devices.
        guard let deviceList = fw.MTDeviceCreateList?() as? [MTDevice] else {
            print("[GestureKit] DeviceMonitor: No trackpad devices found.")
            return
        }

        guard !deviceList.isEmpty else {
            print("[GestureKit] DeviceMonitor: Device list is empty.")
            return
        }

        devices = deviceList

        for device in devices {
            registerCallback(for: device)
            fw.MTDeviceStart?(device)
        }

        isRunning = true
        print("[GestureKit] DeviceMonitor: Started monitoring \(devices.count) device(s).")
    }

    /// Stops listening for trackpad touch events.
    func stop() {
        let fw = MultitouchFramework.shared
        guard fw.isAvailable, isRunning else { return }

        for device in devices {
            fw.MTDeviceStop?(device)
        }

        devices.removeAll()
        isRunning = false
        print("[GestureKit] DeviceMonitor: Stopped.")
    }

    // MARK: - Callback Registration

    // We need a way to pass `self` into a C-style callback (which can't capture Swift objects).
    // The trick: store a pointer to `self` in a global box, then read it from inside the callback.
    //
    // Note: This approach works for a single DeviceMonitor instance (the singleton pattern
    // used by GestureCoordinator). For multiple instances you'd need a more complex context map.

    private func registerCallback(for device: MTDevice) {
        // Store a raw pointer to this DeviceMonitor in the global bridge.
        DeviceMonitorBridge.instance = self

        MultitouchFramework.shared.MTRegisterContactFrameCallback?(device, deviceTouchCallback)
    }
}

// MARK: - Global Callback Bridge

// C-style callbacks cannot capture Swift class instances (no closures in C).
// We work around this by storing the DeviceMonitor in a global variable
// and reading it from inside the @convention(c) callback function.
private class DeviceMonitorBridge {
    static weak var instance: DeviceMonitor?
}

// MARK: - C-Compatible Touch Callback

// This is the actual function that MultitouchSupport calls every time
// new finger data is ready. It MUST be @convention(c) (no Swift captures).
private let deviceTouchCallback: MTContactFrameCallback = { device, fingerData, fingerCount, timestamp, frame in
    guard let monitor = DeviceMonitorBridge.instance else { return }
    guard let fingerData = fingerData, fingerCount > 0 else { return }

    // Convert the raw C array of MTFinger structs into a Swift Array.
    // UnsafeBufferPointer lets us iterate over the raw memory safely.
    let fingers = Array(UnsafeBufferPointer(start: fingerData, count: Int(fingerCount)))

    // Forward to the delegate (GestureRecognizer) — still on the callback thread.
    monitor.delegate?.didReceiveFingers(fingers, timestamp: timestamp)
}
