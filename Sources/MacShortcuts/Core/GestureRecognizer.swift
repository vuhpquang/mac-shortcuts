import AppKit
import Foundation

// MARK: - Corner / GestureEvent

enum Corner: String, CaseIterable {
    case topLeft, topRight, bottomLeft, bottomRight
}

enum GestureEvent: Equatable {
    case threeFingerTap
    case threeFingerClick
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
    var tapMaxDuration: TimeInterval = 0.25     // tap must lift within this time
    var clickMinDuration: TimeInterval = 0.25   // hold longer → click
    var forceThreshold: Float = 0.5             // zTotal to trigger force click (0–1 range)
    var cornerZoneSize: Float = 0.20            // 20% of trackpad edge = corner zone

    // Three-finger state
    private var threeFingerStart: Double?
    private var clickFired = false
    private var tapFired = false

    // Force-click state — track per identifier so each new contact can fire once
    private var forceClickFired: Set<Int32> = []

    // MARK: - DeviceMonitorDelegate

    func didReceiveFingers(_ fingers: [MTFinger], timestamp: Double) {
        // STATE-INDEPENDENT counting:
        // We count every finger the callback delivers as "present".
        // The callback fires continuously while fingers touch; when all fingers lift
        // we receive a final frame with count 0 (or the count drops).
        let count = fingers.count

        // Log state values so we can learn the real enum — remove once confirmed working.
        let states = fingers.map { $0.state }
        print("[MacShortcuts] \(count) finger(s) state=\(states) zTotal=\(fingers.map{$0.zTotal})")

        processThreeFinger(count: count, timestamp: timestamp)
        processForceClick(fingers: fingers)
    }

    // MARK: - Three-finger tap / click

    private func processThreeFinger(count: Int, timestamp: Double) {
        if count >= 3 {
            if threeFingerStart == nil {
                threeFingerStart = timestamp
                clickFired = false
                tapFired = false
            } else if let start = threeFingerStart, !clickFired {
                if timestamp - start >= clickMinDuration {
                    emit(.threeFingerClick)
                    clickFired = true
                }
            }
        } else {
            // Fingers lifted (or reduced below 3)
            if let start = threeFingerStart {
                let duration = timestamp - start
                if !tapFired && !clickFired && duration < tapMaxDuration {
                    emit(.threeFingerTap)
                    tapFired = true
                }
                // Reset once count drops to 0
                if count == 0 {
                    threeFingerStart = nil
                    clickFired = false
                    tapFired = false
                }
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
            guard finger.zTotal >= forceThreshold else { continue }
            let pos = finger.normalized.position
            if let corner = detectCorner(x: pos.x, y: pos.y) {
                print("[MacShortcuts] ForceClick corner=\(corner) zTotal=\(finger.zTotal)")
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
