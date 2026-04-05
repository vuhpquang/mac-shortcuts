import AppKit
import Foundation

// MARK: - Corner / GestureEvent

enum Corner: String, CaseIterable {
    case topLeft, topRight, bottomLeft, bottomRight
}

enum GestureEvent: Equatable {
    case threeFingerTap
    case forceClickCorner(Corner)
}

// MARK: - Delegate

protocol GestureRecognizerDelegate: AnyObject {
    func didRecognize(gesture: GestureEvent)
}

// MARK: - GestureRecognizer

class GestureRecognizer: DeviceMonitorDelegate {

    weak var delegate: GestureRecognizerDelegate?

    // Thresholds
    var tapMaxDuration: TimeInterval = 0.50     // tap must lift within this time
    var tapCooldown: Double = 0.50              // minimum seconds between successive taps
    var forceThreshold: Float = 0.85            // zTotal to trigger force click; normal touch = ~0.71–0.79
    var cornerZoneSize: Float = 0.30            // 30% of trackpad edge = corner zone
    // Velocity (normalized units/sec) above which a finger is considered to be dragging.
    // Force-click detection is skipped while dragging to avoid mid-drag corner misfires.
    var dragVelocityThreshold: Float = 0.8

    // Palm rejection: contacts with size > this are treated as palms and ignored.
    // A normal fingertip has size ~0.30; a palm is typically > 1.0.
    // Matches MiddleDrag's "Strict (1.0)" preset.
    var palmSizeThreshold: Float = 1.0

    // Three-finger tap state
    private var threeFingerStart: Double?
    private var tapFired = false
    private var lastTapTimestamp: Double = 0

    // Force-click state — track per identifier so each new contact can fire once
    private var forceClickFired: Set<Int32> = []
    // Pre-arm threshold: arm the click suppressor as soon as pressure exceeds
    // normal-touch range (~0.79 max), before the OS "click" haptic fires.
    // The gesture fires at forceThreshold (0.85). The gap gives the suppressor
    // time to intercept the leftMouseDown before our gesture fires.
    private let forcePreArmThreshold: Float = 0.81

    // MARK: - DeviceMonitorDelegate

    func didReceiveFingers(_ fingers: [MTFinger], timestamp: Double) {
        // Palm rejection: filter out large contacts (palms, wrists).
        // A normal fingertip has size ~0.30; palms are typically > 1.0.
        let validFingers = fingers.filter { $0.size <= palmSizeThreshold }
        let count = validFingers.count

        processThreeFinger(count: count, timestamp: timestamp)
        processForceClick(fingers: validFingers)
    }

    // MARK: - Three-finger tap / click

    private func processThreeFinger(count: Int, timestamp: Double) {
        if count >= 3 {
            // Don't re-arm within the cooldown window — this prevents double-fire
            // when fingers briefly re-register during the lift phase.
            let sinceLastTap = timestamp - lastTapTimestamp
            if threeFingerStart == nil && sinceLastTap > tapCooldown {
                threeFingerStart = timestamp
                tapFired = false
            }
        } else {
            // Fingers dropped below 3 — evaluate and always reset.
            // Do NOT wait for count==0: the callback filters out zero-count frames,
            // so that frame never arrives and the state machine would stay stuck.
            if let start = threeFingerStart {
                let duration = timestamp - start
                if !tapFired && duration < tapMaxDuration {
                    emit(.threeFingerTap)
                    lastTapTimestamp = timestamp
                }
                threeFingerStart = nil
                tapFired = false
            }
        }
    }

    // MARK: - Force click corner

    private func processForceClick(fingers: [MTFinger]) {
        // Clean up tracking for fingers no longer present
        let activeIDs = Set(fingers.map { $0.identifier })
        forceClickFired = forceClickFired.intersection(activeIDs)

        for finger in fingers {
            guard !forceClickFired.contains(finger.identifier) else { continue }

            // Skip if the finger is moving (dragging).
            let vel = finger.normalized.velocity
            let speed = (vel.x * vel.x + vel.y * vel.y).squareRoot()
            guard speed < dragVelocityThreshold else { continue }

            let pos = finger.normalized.position
            guard let corner = detectCorner(x: pos.x, y: pos.y) else { continue }

            // Pre-arm the click suppressor as soon as pressure clears normal-touch
            // range. This beats the OS leftMouseDown which fires at ~the same level
            // as our gesture threshold. The suppressor safely disarms after 300ms
            // if no click follows.
            if finger.zTotal >= forcePreArmThreshold {
                ClickSuppressor.shared.arm()
            }

            // Fire the gesture once pressure crosses the confirmed force threshold.
            if finger.zTotal >= forceThreshold {
                emit(.forceClickCorner(corner))
                forceClickFired.insert(finger.identifier)
            }
        }
    }

    private func detectCorner(x: Float, y: Float) -> Corner? {
        let z = cornerZoneSize
        let inLeft   = x < z
        let inRight  = x > (1 - z)
        let inTop    = y > (1 - z)
        let inBottom = y < z

        if inLeft  && inTop    { return .topLeft }
        if inRight && inTop    { return .topRight }
        if inLeft  && inBottom { return .bottomLeft }
        if inRight && inBottom { return .bottomRight }
        return nil
    }

    // MARK: - Emit

    private func emit(_ gesture: GestureEvent) {
        print("[MacShortcuts] Gesture detected: \(gesture)")
        delegate?.didRecognize(gesture: gesture)
    }
}
