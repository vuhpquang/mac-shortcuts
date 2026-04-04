// Core/TouchModels.swift
// This file defines the data structures (models) that represent raw touch data
// coming from the MacBook trackpad at the lowest level.
//
// The Mac's multitouch trackpad reports each finger as an "MTFinger" — a packet
// of numbers describing where the finger is, how fast it's moving, how hard it's
// pressing, and what state it's in (touching, moving, lifted, etc.).
//
// These structs must exactly match the memory layout that Apple's private
// MultitouchSupport framework uses internally — that's why they use plain numbers
// instead of Swift's fancy types. Think of them as "raw sensor data packets."

import Foundation

// MARK: - MTPoint
// A 2D point on the trackpad surface.
// Coordinates are in the range [0.0, 1.0] where (0,0) is the bottom-left corner
// and (1,1) is the top-right corner of the trackpad.
struct MTPoint {
    var x: Float   // Horizontal position (0 = left, 1 = right)
    var y: Float   // Vertical position (0 = bottom, 1 = top)
}

// MARK: - MTVector
// Combines a finger's position AND velocity into one structure.
// Used for each finger's normalized (0–1 range) motion data.
struct MTVector {
    var position: MTPoint   // Where the finger is right now
    var velocity: MTPoint   // How fast and in what direction it's moving
}

// MARK: - MTFinger
// All the data about a single finger touching the trackpad in one frame.
// This matches the binary layout Apple's private framework writes into memory.
struct MTFinger {
    var frame: Int32            // Which touch "frame" (snapshot) this belongs to
    var identifier: Int32       // Unique ID for this finger across frames
    var normalized: MTVector    // Position + velocity in 0–1 trackpad coordinates
    var size: Float             // How large the contact area is
    var angle: Float            // Rotation angle of the finger contact ellipse
    var majorAxis: Float        // Length of the long axis of the contact ellipse
    var minorAxis: Float        // Length of the short axis of the contact ellipse
    var zTotal: Float           // Estimated pressure / force (higher = more press)
    var state: Int32            // Raw integer state code (see FingerState below)
    var substate: Int32         // Additional state detail (used internally by Apple)
}

// MARK: - MTDevice
// An MTDevice is a reference to a physical trackpad device.
// We alias it to UInt (an integer-sized opaque handle) so it is representable
// in @convention(c) callbacks on both arm64 and x86_64.
typealias MTDevice = UInt

// MARK: - FingerState
// A human-readable Swift enum that maps the raw integer state codes
// from MTFinger.state to meaningful names.
// These constants were reverse-engineered from Apple's private framework.
enum FingerState: Int32 {
    case touching   = 1   // Finger is just making contact with the trackpad
    case moving     = 2   // Finger is sliding across the trackpad
    case stationary = 3   // Finger is resting still on the trackpad
    case lifted     = 4   // Finger has been lifted off the trackpad
    case unknown    = 0   // Any state we don't recognise
}

// MARK: - MTContactFrameCallback Type
// The function signature that MultitouchSupport calls every time a new batch
// of finger data (a "frame") arrives from the trackpad hardware.
// We register a function matching this signature via MTRegisterContactFrameCallback.
//
// All parameter types must be C-representable for @convention(c) to compile.
// MTContactFrameCallback uses UnsafeRawPointer for the finger array because
// UnsafeMutablePointer<MTFinger> is not C-ABI representable in @convention(c)
// with Swift 6. We bind the raw pointer to MTFinger inside the callback body.
typealias MTContactFrameCallback = @convention(c) (
    MTDevice,          // The trackpad device handle
    UnsafeRawPointer,  // Raw pointer to the MTFinger array (cast in callback)
    Int32,             // Number of fingers in the array
    Double,            // Timestamp (seconds since boot)
    Int32              // Frame sequence number
) -> Void
