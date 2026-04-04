// Core/DeviceMonitor.swift
// This file listens to your MacBook's trackpad hardware and collects raw finger data.
//
// It asks MultitouchSupport for all connected trackpad devices, registers a C callback
// on each, and forwards raw MTFinger arrays to its delegate (GestureRecognizer).

import Foundation

// MARK: - Delegate Protocol

protocol DeviceMonitorDelegate: AnyObject {
    func didReceiveFingers(_ fingers: [MTFinger], timestamp: Double)
}

// MARK: - Module-level monitor reference
// C callbacks cannot capture Swift objects. We keep a module-level weak reference
// to the active DeviceMonitor so the @convention(c) callback can reach it safely.
private weak var _activeMonitor: DeviceMonitor?

// MARK: - DeviceMonitor

class DeviceMonitor {

    weak var delegate: DeviceMonitorDelegate?

    /// Stored as UInt because MTDevice = UInt (the integer bit-pattern of the C pointer).
    private var devices: [MTDevice] = []
    private(set) var isRunning = false

    // MARK: - Lifecycle

    func start() {
        let fw = MultitouchFramework.shared
        guard fw.isAvailable else {
            print("[MacShortcuts] DeviceMonitor: MultitouchSupport unavailable.")
            return
        }
        guard !isRunning else { return }

        _activeMonitor = self

        // MTDeviceCreateList returns a CFArray whose elements are opaque C device pointers.
        // We cannot bridge CFArray → [UInt] automatically; instead we iterate with
        // CFArrayGetValueAtIndex and convert each raw pointer to UInt (same bit width).
        guard let cfArray = fw.MTDeviceCreateList?() else {
            print("[MacShortcuts] DeviceMonitor: MTDeviceCreateList returned nil.")
            return
        }

        let count = CFArrayGetCount(cfArray)
        guard count > 0 else {
            print("[MacShortcuts] DeviceMonitor: No trackpad devices found.")
            return
        }

        for i in 0..<count {
            // CFArrayGetValueAtIndex gives us an UnsafeRawPointer to the C device ref.
            guard let rawPtr = CFArrayGetValueAtIndex(cfArray, i) else { continue }
            // Reinterpret the pointer as UInt — same bit pattern, different Swift type.
            // MTDevice = UInt, so the C functions receive the correct pointer value.
            let device = UInt(bitPattern: rawPtr)
            devices.append(device)
            fw.MTRegisterContactFrameCallback?(device, deviceTouchCallback)
            fw.MTDeviceStart?(device)
        }

        isRunning = true
        print("[MacShortcuts] DeviceMonitor: Started monitoring \(devices.count) device(s).")
    }

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

private let deviceTouchCallback: MTContactFrameCallback = { _device, fingerData, fingerCount, timestamp, _ in
    guard let monitor = _activeMonitor else { return }
    guard fingerCount > 0 else { return }

    let fingersPtr = fingerData.assumingMemoryBound(to: MTFinger.self)
    let fingers = Array(UnsafeBufferPointer(start: fingersPtr, count: Int(fingerCount)))
    monitor.delegate?.didReceiveFingers(fingers, timestamp: timestamp)
}
