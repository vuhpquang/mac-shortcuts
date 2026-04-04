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

        // Release every retained self-pointer that was created in registerCallback(for:).
        // This balances each passRetained call and prevents memory leaks.
        for ptr in deviceContextPointers {
            Unmanaged<DeviceMonitor>.fromOpaque(ptr).release()
        }
        deviceContextPointers.removeAll()

        isRunning = false
        print("[GestureKit] DeviceMonitor: Stopped.")
    }

    // MARK: - Callback Registration

    // We need a way to pass `self` into a C-style callback (which can't capture Swift objects).
    //
    // Idiomatic Swift solution: use Unmanaged to create a raw pointer to `self` and pass it
    // as the userInfo/context for each device registration.  Each device gets its own retained
    // pointer so registering a second (or third) device never overwrites the first device's
    // context reference — eliminating the data race that existed with the old single global.
    //
    // Memory management contract:
    //   - passRetained increments the retain count when we register.
    //   - stop() calls release() on every stored pointer, decrementing the retain count.
    //   - The net effect is zero leaks as long as stop() is always called (or the monitor
    //     is never stopped, in which case the object stays alive intentionally).

    /// Opaque pointers kept alive for the lifetime of each device registration.
    /// Each entry is an Unmanaged-retained pointer to `self` that must be released in stop().
    private var deviceContextPointers: [UnsafeMutableRawPointer] = []

    private func registerCallback(for device: MTDevice) {
        // Retain self and convert to an opaque pointer.  This pointer is stable — it will not
        // be overwritten when the next device is registered, fixing BUG-03.
        let contextPtr = Unmanaged.passRetained(self).toOpaque()
        deviceContextPointers.append(contextPtr)

        MultitouchFramework.shared.MTRegisterContactFrameCallbackWithRefcon?(device, deviceTouchCallback, contextPtr)
    }
}

// MARK: - C-Compatible Touch Callback

// This is the actual function that MultitouchSupport calls every time
// new finger data is ready. It MUST be @convention(c) (no Swift captures).
//
// The refcon (reference context) parameter carries the opaque pointer that was
// passed to MTRegisterContactFrameCallbackWithRefcon above.  We recover the
// DeviceMonitor from it with takeUnretainedValue — we do NOT take ownership
// here because stop() is responsible for the balancing release().
private let deviceTouchCallback: MTContactFrameCallbackWithRefcon = { device, fingerData, fingerCount, timestamp, frame, refcon in
    guard let refcon = refcon else { return }
    let monitor = Unmanaged<DeviceMonitor>.fromOpaque(refcon).takeUnretainedValue()
    guard let fingerData = fingerData, fingerCount > 0 else { return }

    // Convert the raw C array of MTFinger structs into a Swift Array.
    // UnsafeBufferPointer lets us iterate over the raw memory safely.
    let fingers = Array(UnsafeBufferPointer(start: fingerData, count: Int(fingerCount)))

    // Forward to the delegate (GestureRecognizer) — still on the callback thread.
    monitor.delegate?.didReceiveFingers(fingers, timestamp: timestamp)
}
