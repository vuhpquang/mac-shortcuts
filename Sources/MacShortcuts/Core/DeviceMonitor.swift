// Core/DeviceMonitor.swift
// Registers a touch-frame observer on every connected trackpad.
//
// KEY RULE: We NEVER call MTDeviceStart or MTDeviceStop.
// The built-in trackpad (and Magic Trackpad) are already started by macOS.
// Calling MTDeviceStart again disrupts the system's touch pipeline and kills
// normal scrolling / cursor movement. We only ADD our callback as an extra
// observer on top of the already-running device — this is safe and non-destructive.

import Foundation

// MARK: - Delegate Protocol

protocol DeviceMonitorDelegate: AnyObject {
    func didReceiveFingers(_ fingers: [MTFinger], timestamp: Double)
}

// MARK: - Module-level monitor reference
// @convention(c) callbacks cannot capture Swift objects.
// We hold a module-level weak reference so the C callback can reach the monitor.
private weak var _activeMonitor: DeviceMonitor?

// MARK: - DeviceMonitor

class DeviceMonitor {

    weak var delegate: DeviceMonitorDelegate?
    private(set) var isRunning = false

    // MARK: - Start

    func start() {
        let fw = MultitouchFramework.shared
        guard fw.isAvailable else {
            print("[MacShortcuts] DeviceMonitor: MultitouchSupport unavailable.")
            return
        }
        guard !isRunning else { return }

        // Publish self so the C callback can find us.
        _activeMonitor = self

        // Get all connected trackpad devices from MultitouchSupport.
        // MTDeviceCreateList returns a CFArray of opaque C device references.
        // We must iterate with CFArrayGetValueAtIndex — Swift's automatic CFArray
        // bridging does not know how to convert opaque pointers to UInt.
        guard let cfArray = fw.MTDeviceCreateList?() else {
            print("[MacShortcuts] DeviceMonitor: MTDeviceCreateList returned nil.")
            return
        }

        let count = CFArrayGetCount(cfArray)
        guard count > 0 else {
            print("[MacShortcuts] DeviceMonitor: No trackpad devices found.")
            return
        }

        var registered = 0
        for i in 0..<count {
            guard let rawPtr = CFArrayGetValueAtIndex(cfArray, i) else { continue }
            // Convert the opaque C pointer to UInt (MTDevice) — same bit pattern, 64-bit safe.
            let device = UInt(bitPattern: rawPtr)
            // Register our observer. This ADDS to the existing callback chain;
            // it does NOT replace the system's touch processing.
            fw.MTRegisterContactFrameCallback?(device, deviceTouchCallback)
            registered += 1
        }

        isRunning = true
        print("[MacShortcuts] DeviceMonitor: Registered on \(registered) device(s).")
    }

    // MARK: - Stop

    func stop() {
        // We cannot easily unregister a C callback from MultitouchSupport.
        // Clearing _activeMonitor is sufficient: the C callback checks it first
        // and returns immediately if nil, so no further events are processed.
        _activeMonitor = nil
        isRunning = false
        print("[MacShortcuts] DeviceMonitor: Stopped.")
    }
}

// MARK: - C-Compatible Touch Callback

private let deviceTouchCallback: MTContactFrameCallback = { _device, fingerData, fingerCount, timestamp, _ in
    guard let monitor = _activeMonitor else { return }
    guard fingerCount > 0 else { return }

    let fingersPtr = fingerData.assumingMemoryBound(to: MTFinger.self)
    let fingers = Array(UnsafeBufferPointer(start: fingersPtr, count: Int(fingerCount)))
    monitor.delegate?.didReceiveFingers(fingers, timestamp: timestamp)
}
