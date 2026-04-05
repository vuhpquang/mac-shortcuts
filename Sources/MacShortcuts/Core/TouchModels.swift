import Foundation

struct MTPoint {
    var x: Float
    var y: Float
}

struct MTVector {
    var position: MTPoint
    var velocity: MTPoint
}

// MTFinger layout reverse-engineered from raw byte dumps.
// Layout confirmed by running the app and observing:
//   - offsets 32/36 produce 0.0–1.0 floats (normalized position)
//   - offset 20 produces small integers 1–7 (state)
//   - offset 92 produces 0.0–1.0 float that varies with touch pressure (zTotal)
//   - offsets 96+ show 0xAAAAAAAA (uninitialized marker) → struct ends at 96 bytes
struct MTFinger {
    var frame: Int32        // offset  0
    var identifier: Int32   // offset  4
    var pad1: Int32         // offset  8  (unknown)
    var pad2: Float         // offset 12  (unknown, constant ~10.19)
    var pad3: Int32         // offset 16  (unknown, constant 10)
    var state: Int32        // offset 20  ← confirmed: small integers 1–7
    var substate: Int32     // offset 24
    var pad4: Int32         // offset 28  (unknown, constant 1)
    var normalized: MTVector // offset 32 (16 bytes: pos.x, pos.y, vel.x, vel.y)
    var size: Float         // offset 48
    var pad5: Float         // offset 52  (unknown)
    var angle: Float        // offset 56
    var majorAxis: Float    // offset 60
    var minorAxis: Float    // offset 64
    var mm: MTVector        // offset 68  (16 bytes: position in mm)
    var zero1: Int32        // offset 84  (padding)
    var zero2: Int32        // offset 88  (padding)
    var zTotal: Float       // offset 92  ← confirmed: 0.0–1.0, varies with pressure
}

// MTDevice handle — UInt so it is @convention(c) representable on both arm64 and x86_64.
typealias MTDevice = UInt

// The touch-frame callback type.
// UnsafeRawPointer is used for the finger array because UnsafeMutablePointer<MTFinger>
// is not representable in @convention(c) with Swift 6.
typealias MTContactFrameCallback = @convention(c) (
    MTDevice,          // device handle
    UnsafeRawPointer,  // pointer to MTFinger array (bound in the callback body)
    Int32,             // finger count
    Double,            // timestamp (seconds since boot)
    Int32              // frame number
) -> Void
