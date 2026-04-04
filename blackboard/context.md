# Project: GestureKit

## Goal
A macOS menu bar app that detects multitouch trackpad gestures and maps them
to system actions (middle click, Mission Control, etc.)

## Tech stack (fixed, do not change)
- Language: Swift / SwiftUI
- Target: macOS 13+, Apple Silicon + Intel
- Distribution: Direct DMG, no App Store
- UI: SwiftUI only, no Storyboards
- Lifecycle: NSApplicationDelegate (not SwiftUI App lifecycle)

## References
- https://github.com/NullPointerDepressiveDisorder/MiddleDrag  (main reference)
- https://multitouch.app/  (UX reference)

## Phased delivery (IMPORTANT)
Deliver in this exact phase order. Each phase must be complete before next:
1. Project skeleton (AppDelegate, MenuBarController, PermissionsManager)
2. MultitouchSupport bridge (Core/MultitouchFramework, TouchModels, DeviceMonitor)
3. Gesture recognizer (Core/GestureRecognizer — tap, click, force corner)
4. Action executor (Core/ActionExecutor, GestureMapping, UserDefaults storage)
5. Wire everything (GestureCoordinator singleton, AppDelegate wiring)
6. Settings UI (SwiftUI SettingsView, all 6 gesture slots)
7. Build & distribute (build.sh, DMG, README)

## Key implementation details
- LSUIElement = YES (hide from Dock)
- MultitouchSupport loaded via dlopen/dlsym (private framework)
- Gestures: ThreeFingerTap, ThreeFingerClick, ForceClickCorner(4 corners)
- Actions: middleClick, keystroke, openApp, missionControl, appExpose, showDesktop
- Default mapping: threeFingerTap → middleClick, forceClickTopLeft → missionControl
- Settings window: 480x520, not resizable
- Stakeholder is a beginner — explain each file after creating it
