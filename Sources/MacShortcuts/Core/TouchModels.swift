import Foundation

struct MTPoint {
    var x: Float
    var y: Float
}

struct MTVector {
    var position: MTPoint
    var velocity: MTPoint
}

// MTFinger layout reverse-engineered from MultitouchSupport.
// The struct contains several padding/unknown fields that must be present
// or all offsets after `normalized` are wrong (causing garbage state values).
// Layout verified against working open-source implementations (80 bytes total).
struct MTFinger {
    var frame: Int32        // offset  0
    var identifier: Int32   // offset  4
    var normalized: MTVector // offset  8  (16 bytes: pos.x, pos.y, vel.x, vel.y)
    var size: Float         // offset 24
    var zero1: Int32        // offset 28  (padding — MUST be present)
    var angle: Float        // offset 32
    var majorAxis: Float    // offset 36
    var minorAxis: Float    // offset 40
    var mm: MTVector        // offset 44  (16 bytes: position in mm — MUST be present)
    var zero2a: Int32       // offset 60  (padding — MUST be present)
    var zero2b: Int32       // offset 64  (padding — MUST be present)
    var zTotal: Float       // offset 68  (pressure / force)
    var state: Int32        // offset 72
    var substate: Int32     // offset 76
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
