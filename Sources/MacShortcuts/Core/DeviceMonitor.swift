// Core/DeviceMonitor.swift
// Registers a touch-frame observer on every connected trackpad and starts event delivery.
//
// MTDeviceStart(device, 0) is required to begin receiving touch frames.
// The second argument is the run-loop mode (0 = default). We previously called it
// with only 1 argument — that was undefined behavior and corrupted the trackpad state.

import Foundation

// MARK: - Delegate Protocol

protocol DeviceMonitorDelegate: AnyObject {
    func didReceiveFingers(_ fingers: [MTFinger], timestamp: Double)
}

// MARK: - Module-level monitor reference
private weak var _activeMonitor: DeviceMonitor?

// MARK: - DeviceMonitor

class DeviceMonitor {

    weak var delegate: DeviceMonitorDelegate?
    private var devices: [MTDevice] = []
    private(set) var isRunning = false

    func start() {
        let fw = MultitouchFramework.shared
        guard fw.isAvailable else {
            print("[MacShortcuts] DeviceMonitor: MultitouchSupport not available — gestures disabled.")
            return
        }
        guard !isRunning else { return }

        _activeMonitor = self

        guard let cfArray = fw.MTDeviceCreateList?() else {
            print("[MacShortcuts] DeviceMonitor: MTDeviceCreateList returned nil.")
            return
        }

        let count = CFArrayGetCount(cfArray)
        print("[MacShortcuts] DeviceMonitor: Found \(count) device(s).")
        guard count > 0 else { return }

        for i in 0..<count {
            guard let rawPtr = CFArrayGetValueAtIndex(cfArray, i) else { continue }
            let device = UInt(bitPattern: rawPtr)
            devices.append(device)

            // Register our callback — this adds to the existing callback chain.
            fw.MTRegisterContactFrameCallback?(device, deviceTouchCallback)

            // Start event delivery to our callback.
            // runMode = 0 is the standard default. The previous bug was calling this
            // with only 1 arg (missing runMode), causing undefined behavior.
            fw.MTDeviceStart?(device, 0)

            print("[MacShortcuts] DeviceMonitor: Registered + started device \(i).")
        }

        isRunning = true
    }

    func stop() {
        let fw = MultitouchFramework.shared
        if fw.isAvailable {
            for device in devices {
                fw.MTDeviceStop?(device, 0)
            }
        }
        devices.removeAll()
        _activeMonitor = nil
        isRunning = false
        print("[MacShortcuts] DeviceMonitor: Stopped.")
    }
}

// MARK: - C Callback

// Set to true once to dump raw bytes and figure out the real struct layout.
private var _didDumpLayout = false

private let deviceTouchCallback: MTContactFrameCallback = { _device, fingerData, fingerCount, timestamp, _ in
    guard let monitor = _activeMonitor else { return }
    guard fingerCount > 0 else { return }

    // ONE-TIME raw byte dump — prints 128 bytes of the first finger as floats and ints
    // so we can determine the correct struct layout from known fields (normalized pos = 0-1).
    if !_didDumpLayout && fingerCount >= 1 {
        _didDumpLayout = true
        let byteCount = 128
        let raw = fingerData.bindMemory(to: Float.self, capacity: byteCount / 4)
        var floats = [Float]()
        for i in 0..<(byteCount/4) { floats.append(raw[i]) }
        print("[LAYOUT DUMP] First \(byteCount) bytes as Float32:")
        for i in 0..<floats.count {
            print("  offset \(i*4): \(floats[i])  (bits: \(floats[i].bitPattern))")
        }
    }

    let fingersPtr = fingerData.assumingMemoryBound(to: MTFinger.self)
    let fingers = Array(UnsafeBufferPointer(start: fingersPtr, count: Int(fingerCount)))
    monitor.delegate?.didReceiveFingers(fingers, timestamp: timestamp)
}
