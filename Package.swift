// Package.swift
// This file tells Swift Package Manager (SPM) how to build the GestureKit app.
// SPM is Apple's command-line build tool — it replaces the need to open Xcode
// for compiling the project. Run `swift build -c release` from this folder to build.

// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "GestureKit",
    platforms: [
        .macOS(.v13)   // Requires macOS 13 (Ventura) or later
    ],
    targets: [
        .executableTarget(
            name: "GestureKit",
            path: "Sources/GestureKit",
            resources: [
                .copy("Resources/Info.plist")
            ],
            swiftSettings: []
        )
    ]
)
