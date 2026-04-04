// Core/MultitouchFramework.swift
// This file loads Apple's hidden (private) MultitouchSupport framework at runtime.
//
// Why is this necessary? Apple's trackpad multitouch API is not public — there's no
// official Swift or Objective-C way to ask "how many fingers are touching the trackpad
// right now at the raw level." However, macOS itself uses an internal framework called
// MultitouchSupport for this purpose. This file finds that framework, loads it into
// memory at runtime, and pulls out the specific functions we need.
//
// If the framework isn't available (future macOS versions might move it), the app
// degrades gracefully — no crash, just no gesture detection.

import Foundation

// MARK: - Function Pointer Type Aliases
// These are the types for each function we'll load from MultitouchSupport.
// Think of them as "slots" that will hold the actual function once loaded.

// Returns a list of all connected trackpad devices.
typealias MTDeviceCreateListFn = @convention(c) () -> CFArray?

// Registers a callback function to receive touch data from a specific device.
typealias MTRegisterContactFrameCallbackFn = @convention(c) (MTDevice, MTContactFrameCallback) -> Void

// Starts delivering touch events from a device (like pressing "play").
typealias MTDeviceStartFn = @convention(c) (MTDevice) -> Void

// Stops delivering touch events from a device (like pressing "stop").
typealias MTDeviceStopFn = @convention(c) (MTDevice) -> Void

// MARK: - MultitouchFramework Singleton

/// Loads the private MultitouchSupport framework and exposes its key functions.
/// Access via `MultitouchFramework.shared`.
class MultitouchFramework {

    // The one and only instance — created lazily the first time it's accessed.
    static let shared = MultitouchFramework()

    // Whether the framework was successfully loaded.
    // If false, gesture detection is unavailable on this system.
    private(set) var isAvailable: Bool = false

    // The raw handle returned by dlopen (a reference to the loaded framework binary).
    private var frameworkHandle: UnsafeMutableRawPointer?

    // The four functions we need, stored as typed Swift variables.
    // They start as nil and are filled in during init() if loading succeeds.
    var MTDeviceCreateList: MTDeviceCreateListFn?
    var MTRegisterContactFrameCallback: MTRegisterContactFrameCallbackFn?
    var MTDeviceStart: MTDeviceStartFn?
    var MTDeviceStop: MTDeviceStopFn?

    private init() {
        loadFramework()
    }

    // MARK: - Private Loading Logic

    private func loadFramework() {
        // The path to Apple's private MultitouchSupport framework on disk.
        let frameworkPath = "/System/Library/PrivateFrameworks/MultitouchSupport.framework/MultitouchSupport"

        // dlopen loads a dynamic library (.dylib / framework) into memory at runtime.
        // RTLD_NOW means: resolve all symbols immediately (fail fast if something's wrong).
        guard let handle = dlopen(frameworkPath, RTLD_NOW) else {
            let error = String(cString: dlerror())
            print("[GestureKit] MultitouchSupport could not be loaded: \(error)")
            print("[GestureKit] Gesture detection will be unavailable.")
            return
        }

        frameworkHandle = handle

        // dlsym looks up a symbol (function) by name inside the loaded framework.
        // We cast the raw pointer to the typed function signature we defined above.
        guard let createListPtr = dlsym(handle, "MTDeviceCreateList") else {
            print("[GestureKit] Could not find MTDeviceCreateList")
            return
        }
        MTDeviceCreateList = unsafeBitCast(createListPtr, to: MTDeviceCreateListFn.self)

        guard let registerCallbackPtr = dlsym(handle, "MTRegisterContactFrameCallback") else {
            print("[GestureKit] Could not find MTRegisterContactFrameCallback")
            return
        }
        MTRegisterContactFrameCallback = unsafeBitCast(registerCallbackPtr, to: MTRegisterContactFrameCallbackFn.self)

        guard let startPtr = dlsym(handle, "MTDeviceStart") else {
            print("[GestureKit] Could not find MTDeviceStart")
            return
        }
        MTDeviceStart = unsafeBitCast(startPtr, to: MTDeviceStartFn.self)

        guard let stopPtr = dlsym(handle, "MTDeviceStop") else {
            print("[GestureKit] Could not find MTDeviceStop")
            return
        }
        MTDeviceStop = unsafeBitCast(stopPtr, to: MTDeviceStopFn.self)

        // All four symbols loaded successfully.
        isAvailable = true
        print("[GestureKit] MultitouchSupport loaded successfully.")
    }

    deinit {
        // Clean up the framework handle when this object is released (app quit).
        if let handle = frameworkHandle {
            dlclose(handle)
        }
    }
}
