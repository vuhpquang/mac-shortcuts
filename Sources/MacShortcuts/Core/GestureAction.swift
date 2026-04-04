// Core/GestureAction.swift
// This file defines all the actions that GestureKit can perform when a gesture is detected.
//
// Think of each "action" as an answer to the question: "When I do THIS gesture, what should happen?"
// For example: "When I three-finger tap → simulate a middle mouse click"
//
// Actions are stored as settings and need to survive the app being quit and reopened,
// so they implement Codable (Swift's built-in way to convert data to/from JSON for storage).

import AppKit
import Foundation

// MARK: - GestureAction Enum

/// All the system actions that a gesture can trigger.
/// Each case represents one thing GestureKit can DO when a gesture fires.
enum GestureAction: Codable, Equatable, CaseIterable, Hashable {

    /// Do nothing (the gesture is disabled / unmapped).
    case none

    /// Simulate pressing the middle mouse button at the current cursor position.
    /// Useful for opening links in a new tab, closing tabs, etc.
    case middleClick

    /// Simulate pressing a key combination (e.g., Cmd+Space for Spotlight).
    /// - key: The character to press (e.g., "f", " " for space)
    /// - modifiers: The modifier keys to hold (e.g., .command, .shift)
    case keystroke(key: String, modifiers: NSEvent.ModifierFlags)

    /// Launch or focus an application by its bundle identifier.
    /// - bundleID: The app's unique identifier (e.g., "com.apple.Safari")
    case openApp(bundleID: String)

    /// Show Mission Control (overview of all windows and Spaces).
    case missionControl

    /// Show App Exposé (all windows of the currently active app).
    case appExpose

    /// Show the Desktop (move all windows out of the way temporarily).
    case showDesktop

    // MARK: - Human-Readable Name

    /// The display name shown in the Settings UI picker.
    var displayName: String {
        switch self {
        case .none:          return "None"
        case .middleClick:   return "Middle Click"
        case .keystroke:     return "Keystroke\u{2026}"
        case .openApp:       return "Open App\u{2026}"
        case .missionControl: return "Mission Control"
        case .appExpose:     return "App Exposé"
        case .showDesktop:   return "Show Desktop"
        }
    }

    // MARK: - CaseIterable Support
    // CaseIterable lets us list all cases in the Settings picker.
    // Because some cases have associated values, we must implement allCases manually.
    static var allCases: [GestureAction] {
        return [.none, .middleClick, .missionControl, .appExpose, .showDesktop,
                .keystroke(key: "", modifiers: []), .openApp(bundleID: "")]
    }

    // MARK: - Codable Implementation
    // Custom Codable because the enum has associated values (Swift doesn't auto-synthesize
    // Codable for enums with associated values that aren't themselves Codable by default).

    private enum CodingKeys: String, CodingKey {
        case type, key, modifiers, bundleID
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .none:
            try container.encode("none", forKey: .type)
        case .middleClick:
            try container.encode("middleClick", forKey: .type)
        case .keystroke(let key, let modifiers):
            try container.encode("keystroke", forKey: .type)
            try container.encode(key, forKey: .key)
            try container.encode(modifiers.rawValue, forKey: .modifiers)
        case .openApp(let bundleID):
            try container.encode("openApp", forKey: .type)
            try container.encode(bundleID, forKey: .bundleID)
        case .missionControl:
            try container.encode("missionControl", forKey: .type)
        case .appExpose:
            try container.encode("appExpose", forKey: .type)
        case .showDesktop:
            try container.encode("showDesktop", forKey: .type)
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        switch type {
        case "none":          self = .none
        case "middleClick":   self = .middleClick
        case "missionControl": self = .missionControl
        case "appExpose":     self = .appExpose
        case "showDesktop":   self = .showDesktop
        case "keystroke":
            let key = try container.decode(String.self, forKey: .key)
            let modifiersRaw = try container.decode(UInt.self, forKey: .modifiers)
            self = .keystroke(key: key, modifiers: NSEvent.ModifierFlags(rawValue: modifiersRaw))
        case "openApp":
            let bundleID = try container.decode(String.self, forKey: .bundleID)
            self = .openApp(bundleID: bundleID)
        default:
            self = .none
        }
    }

    // MARK: - Equatable
    static func == (lhs: GestureAction, rhs: GestureAction) -> Bool {
        switch (lhs, rhs) {
        case (.none, .none),
             (.middleClick, .middleClick),
             (.missionControl, .missionControl),
             (.appExpose, .appExpose),
             (.showDesktop, .showDesktop):
            return true
        case (.keystroke(let k1, let m1), .keystroke(let k2, let m2)):
            return k1 == k2 && m1 == m2
        case (.openApp(let b1), .openApp(let b2)):
            return b1 == b2
        default:
            return false
        }
    }

    // MARK: - Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(displayName)
        switch self {
        case .keystroke(let key, let modifiers):
            hasher.combine(key)
            hasher.combine(modifiers.rawValue)
        case .openApp(let bundleID):
            hasher.combine(bundleID)
        default:
            break
        }
    }
}
