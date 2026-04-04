// Core/GestureMapping.swift
// This file stores the user's gesture→action configuration.
//
// GestureMapping is basically a table with six rows — one for each gesture GestureKit
// can detect — and a "what to do" action for each. For example:
//
//   Three Finger Tap     → Middle Click
//   Three Finger Click   → None
//   Force Click Top-Left → Mission Control
//   ...and so on
//
// This mapping is saved to disk automatically whenever the user changes a setting,
// so it persists even after quitting and reopening the app.

import Foundation

// MARK: - GestureMapping Struct

/// Holds the action assignment for each of the six gesture slots.
/// Codable means it can be automatically converted to/from JSON for storage.
struct GestureMapping: Codable, Equatable {

    // One action per gesture slot.
    var threeFingerTap:    GestureAction
    var threeFingerClick:  GestureAction
    var cornerTopLeft:     GestureAction
    var cornerTopRight:    GestureAction
    var cornerBottomLeft:  GestureAction
    var cornerBottomRight: GestureAction

    // MARK: - Default Mapping (First Run)

    /// The mapping used on first launch before the user customizes anything.
    /// Three-finger tap → Middle Click is the most universally useful default.
    /// Force Click Top-Left → Mission Control mirrors a common macOS Hot Corner.
    static let defaults = GestureMapping(
        threeFingerTap:    .middleClick,
        threeFingerClick:  .none,
        cornerTopLeft:     .missionControl,
        cornerTopRight:    .none,
        cornerBottomLeft:  .none,
        cornerBottomRight: .none
    )

    // MARK: - UserDefaults Persistence

    /// The key under which the mapping is stored in UserDefaults.
    private static let storageKey = "gestureMapping"

    /// Loads the user's saved mapping from UserDefaults.
    /// Returns `GestureMapping.defaults` if nothing is saved yet or if the data is corrupted.
    static func load() -> GestureMapping {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else {
            // First launch — no saved data yet.
            return .defaults
        }
        do {
            return try JSONDecoder().decode(GestureMapping.self, from: data)
        } catch {
            // Saved data is invalid or from an old version — fall back to defaults.
            print("[GestureKit] GestureMapping: Could not decode saved mapping (\(error)). Using defaults.")
            return .defaults
        }
    }

    /// Saves this mapping to UserDefaults so it persists after the app is quit.
    /// Called automatically whenever the user changes a setting.
    func save() {
        do {
            let data = try JSONEncoder().encode(self)
            UserDefaults.standard.set(data, forKey: GestureMapping.storageKey)
        } catch {
            print("[GestureKit] GestureMapping: Could not encode mapping for saving (\(error)).")
        }
    }

    // MARK: - Gesture Lookup

    /// Returns the action mapped to a specific recognized gesture.
    /// Used by GestureCoordinator to decide what to execute.
    func action(for gesture: GestureEvent) -> GestureAction {
        switch gesture {
        case .threeFingerTap:
            return threeFingerTap
        case .threeFingerClick:
            return threeFingerClick
        case .forceClickCorner(let corner):
            switch corner {
            case .topLeft:     return cornerTopLeft
            case .topRight:    return cornerTopRight
            case .bottomLeft:  return cornerBottomLeft
            case .bottomRight: return cornerBottomRight
            }
        }
    }
}
