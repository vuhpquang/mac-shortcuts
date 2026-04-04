// main.swift
// This is the true entry point for a Swift Package Manager executable target.
// It manually boots the macOS application runtime and hands control to AppDelegate.
// (In an Xcode project you'd use @NSApplicationMain on AppDelegate, but SPM requires
// this explicit setup instead.)

import AppKit

// Create the shared NSApplication instance (the macOS app runtime).
let app = NSApplication.shared

// Create our AppDelegate and assign it as the handler for app lifecycle events.
let delegate = AppDelegate()
app.delegate = delegate

// Hide the app from the Dock — LSUIElement=YES in Info.plist should handle this,
// but we also set it here as a safety net so the Dock icon never appears.
app.setActivationPolicy(.accessory)

// Hand over control to the macOS run loop. This call never returns while the app is running.
app.run()
