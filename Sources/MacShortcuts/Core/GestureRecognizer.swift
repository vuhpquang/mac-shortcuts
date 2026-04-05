// Core/GestureRecognizer.swift
// This file is the "brain" that turns raw finger position data into meaningful gestures.
//
// It watches incoming finger frames from DeviceMonitor and recognizes three gesture types:
//
//   • ThreeFingerTap    — Three fingers touch and lift quickly (< 0.18 seconds)
//   • ThreeFingerClick  — Three fingers hold contact for longer (>= 0.18 seconds)
//   • ForceClickCorner  — One finger presses hard in a screen corner
//
// Think of this like a translator: raw sensor numbers go in, human-readable gesture
// events come out. Those events then flow to GestureCoordinator to trigger actions.

import AppKit
import Foundation

// MARK: - Corner Enum

/// The four corners of the screen where force-click gestures can be triggered.
enum Corner: String, CaseIterable {
    case topLeft
    case topRight
    case bottomLeft
    case bottomRight
}

// MARK: - GestureEvent Enum

/// The recognized gesture types that GestureKit can detect.
enum GestureEvent: Equatable {
    case threeFingerTap               // Quick three-finger touch and lift
    case threeFingerClick             // Sustained three-finger press
    case forceClickCorner(Corner)     // Hard press in a specific screen corner
}

// MARK: - GestureRecognizerDelegate Protocol

/// Implement this protocol to receive recognized gesture events.
/// GestureCoordinator is the delegate in normal operation.
protocol GestureRecognizerDelegate: AnyObject {
    func didRecognize(gesture: GestureEvent)
}

// MARK: - GestureRecognizer

class GestureRecognizer: DeviceMonitorDelegate {

    // MARK: - Configuration

    /// Maximum duration (seconds) for a three-finger touch to count as a TAP.
    /// Touches shorter than this = tap. Touches longer = click/hold.
    var tapMaxDuration: TimeInterval = 0.18

    /// Minimum duration (seconds) for a three-finger touch to count as a CLICK.
    /// Same threshold as tapMaxDuration — crossing it triggers the click event.
    var clickMinDuration: TimeInterval = 0.18

    /// Minimum force (zTotal) required to trigger a force-click corner gesture.
    /// Range is approximately 0.0 (no press) to 1.0 (maximum press).
    var forceThreshold: Float = 0.30

    /// How close to the edge of the trackpad counts as "in a corner" (0–1 range).
    /// 0.15 means the corner zone covers 15% of the trackpad width/height.
    var cornerZoneSize: Float = 0.15

    // MARK: - Delegate

    weak var delegate: GestureRecognizerDelegate?

    // MARK: - Three-Finger Gesture State

    /// When the current three-finger contact started (nil = no contact).
    private var threeFingerContactStart: Double?

    /// Whether we already fired a threeFingerClick event for the current contact.
    /// Prevents firing the click event repeatedly while fingers stay down.
    private var threeFingerClickFired = false

    /// Whether we already fired a threeFingerTap event for this gesture cycle.
    private var threeFingerTapFired = false

    // MARK: - Force Click State

    /// Tracks whether a force click was already fired for the current finger contact.
    /// Key = finger identifier, Value = whether force click was fired.
    private var forceClickFiredForFinger: [Int32: Bool] = [:]

    // MARK: - DeviceMonitorDelegate

    /// Called by DeviceMonitor every time a new frame of finger data arrives.
    /// This is the main entry point — all gesture logic starts here.
    func didReceiveFingers(_ fingers: [MTFinger], timestamp: Double) {
        let states = fingers.map { $0.state }
        print("[MacShortcuts] GestureRecognizer: \(fingers.count) finger(s), states=\(states)")

        let touchingFingers = fingers.filter { FingerState(rawValue: $0.state) == .touching ||
                                               FingerState(rawValue: $0.state) == .moving ||
                                               FingerState(rawValue: $0.state) == .stationary }

        let liftedFingers = fingers.filter { FingerState(rawValue: $0.state) == .lifted }

        processThreeFingerGesture(touchingFingers: touchingFingers,
                                   liftedFingers: liftedFingers,
                                   timestamp: timestamp)

        processForceClickCorner(fingers: touchingFingers)

        // Clean up force-click tracking for lifted fingers.
        for finger in liftedFingers {
            forceClickFiredForFinger.removeValue(forKey: finger.identifier)
        }
    }

    // MARK: - Three-Finger Tap / Click Detection

    private func processThreeFingerGesture(touchingFingers: [MTFinger],
                                            liftedFingers: [MTFinger],
                                            timestamp: Double) {
        let count = touchingFingers.count

        if count == 3 {
            if threeFingerContactStart == nil {
                // First frame with exactly 3 fingers — record the start time.
                threeFingerContactStart = timestamp
                threeFingerClickFired = false
                threeFingerTapFired = false
            } else if let start = threeFingerContactStart, !threeFingerClickFired {
                let duration = timestamp - start
                if duration >= clickMinDuration {
                    // Fingers have been held long enough — this is a CLICK, not a tap.
                    emit(.threeFingerClick)
                    threeFingerClickFired = true
                }
            }
        } else if count < 3 {
            if let start = threeFingerContactStart {
                let duration = timestamp - start

                if !threeFingerTapFired && !threeFingerClickFired && duration < tapMaxDuration {
                    // Fingers lifted quickly without triggering a click → TAP.
                    emit(.threeFingerTap)
                    threeFingerTapFired = true
                }

                // Reset state after fingers lift.
                if count == 0 || liftedFingers.count > 0 {
                    threeFingerContactStart = nil
                    threeFingerClickFired = false
                    threeFingerTapFired = false
                }
            }
        }
    }

    // MARK: - Force Click Corner Detection

    private func processForceClickCorner(fingers: [MTFinger]) {
        guard fingers.count == 1, let finger = fingers.first else { return }

        // Skip if we already fired for this finger contact.
        if forceClickFiredForFinger[finger.identifier] == true { return }

        // Check if the pressure/force exceeds the threshold.
        guard finger.zTotal >= forceThreshold else { return }

        // Check if the finger is in a corner zone.
        let pos = finger.normalized.position
        if let corner = corner(for: pos) {
            emit(.forceClickCorner(corner))
            forceClickFiredForFinger[finger.identifier] = true
        }
    }

    /// Maps a normalized (0–1) trackpad position to a corner, if it falls within the corner zone.
    /// Returns nil if the position is not in any corner zone.
    private func corner(for position: MTPoint) -> Corner? {
        let zone = cornerZoneSize
        let x = position.x
        let y = position.y   // 0 = bottom of trackpad, 1 = top

        // Map trackpad coordinates to screen corners.
        // Trackpad top (y≈1) corresponds to screen top; trackpad left (x≈0) = screen left.
        let inLeft   = x < zone
        let inRight  = x > (1.0 - zone)
        let inTop    = y > (1.0 - zone)   // trackpad y is 0=bottom, 1=top
        let inBottom = y < zone

        if inLeft  && inTop    { return .topLeft }
        if inRight && inTop    { return .topRight }
        if inLeft  && inBottom { return .bottomLeft }
        if inRight && inBottom { return .bottomRight }

        return nil
    }

    // MARK: - Event Emission

    /// Notifies the delegate of a recognized gesture.
    /// All events are emitted on the callback thread; callers that need the main thread
    /// (e.g., for UI updates) must dispatch themselves.
    private func emit(_ gesture: GestureEvent) {
        delegate?.didRecognize(gesture: gesture)
    }
}
