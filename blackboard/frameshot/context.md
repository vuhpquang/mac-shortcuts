# Project: FrameShot

## Goal
macOS native screenshot capture and annotation tool — capture regions, windows, or full screen, annotate with arrows/text/blur/shapes, copy or save instantly. Inspired by CleanShot X and Shottr.

## Platform
macOS native (13+)

## Tech stack
- Language: Swift
- UI: SwiftUI + AppKit (NSPanel, NSStatusItem)
- Capture: ScreenCaptureKit (macOS 12.3+)
- Drawing: Core Graphics / Core Image
- Distribution: Direct DMG, notarized
- Hotkeys: CGEventTap for global shortcuts
