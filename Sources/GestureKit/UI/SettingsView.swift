// UI/SettingsView.swift
// This file is the Settings window where users configure their gesture→action mappings.
//
// When you click "Settings…" in the GestureKit menu bar menu, this view appears
// in a floating window. It shows six rows — one for each gesture GestureKit can detect —
// and a dropdown picker for each so you can choose what action that gesture triggers.
//
// Changes take effect immediately (no Save button needed) and are automatically
// stored so your settings are remembered after quitting and reopening the app.

import SwiftUI
import AppKit

// MARK: - SettingsView

struct SettingsView: View {

    // @State means SwiftUI automatically re-renders the view when `mapping` changes.
    // It's initialized by loading the user's saved settings (or defaults on first run).
    @State private var mapping: GestureMapping = GestureMapping.load()

    var body: some View {
        VStack(spacing: 0) {

            // MARK: Header
            headerView

            Divider()

            // MARK: Gesture Slot Rows
            gestureSlotList
                .padding(.horizontal, 24)
                .padding(.vertical, 16)

            Divider()

            // MARK: Footer
            footerView
        }
        .frame(width: 480, height: 520)
        .fixedSize()  // Prevent the window from being resized
        // Watch for any change in the mapping struct.
        // When any picker changes, save immediately and update the coordinator.
        .onChange(of: mapping) { newMapping in
            newMapping.save()
            GestureCoordinator.shared.updateMapping(newMapping)
        }
    }

    // MARK: - Header

    private var headerView: some View {
        HStack(spacing: 12) {
            // App icon — using the SF Symbol hand as a placeholder.
            Image(systemName: "hand.point.up.left")
                .resizable()
                .frame(width: 32, height: 32)
                .foregroundColor(.accentColor)

            Text("GestureKit Settings")
                .font(.title2)
                .fontWeight(.semibold)

            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
    }

    // MARK: - Gesture Slot List

    private var gestureSlotList: some View {
        VStack(spacing: 8) {
            GestureSlotRow(
                label: "Three Finger Tap",
                action: $mapping.threeFingerTap
            )
            GestureSlotRow(
                label: "Three Finger Click",
                action: $mapping.threeFingerClick
            )
            GestureSlotRow(
                label: "Force Click — Top Left",
                action: $mapping.cornerTopLeft
            )
            GestureSlotRow(
                label: "Force Click — Top Right",
                action: $mapping.cornerTopRight
            )
            GestureSlotRow(
                label: "Force Click — Bottom Left",
                action: $mapping.cornerBottomLeft
            )
            GestureSlotRow(
                label: "Force Click — Bottom Right",
                action: $mapping.cornerBottomRight
            )
        }
    }

    // MARK: - Footer

    private var footerView: some View {
        HStack {
            Spacer()
            Text("Changes take effect immediately")
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
        }
        .padding(.vertical, 12)
    }
}

// MARK: - GestureSlotRow

/// A single row in the Settings view: a gesture label on the left, an action picker on the right.
/// When the user selects a different action from the dropdown, the binding updates immediately.
private struct GestureSlotRow: View {

    /// The human-readable name of the gesture (e.g., "Three Finger Tap").
    let label: String

    /// Two-way binding to the action stored in GestureMapping.
    /// Changing this automatically triggers .onChange(of: mapping) in SettingsView.
    @Binding var action: GestureAction

    var body: some View {
        HStack {
            // Gesture label — fixed width so all pickers line up neatly.
            Text(label)
                .frame(width: 200, alignment: .leading)
                .lineLimit(1)

            Spacer()

            // Dropdown picker showing all available actions.
            // .menu style makes it a compact dropdown (not a segmented control).
            Picker("", selection: $action) {
                ForEach(GestureAction.allCases, id: \.self) { gestureAction in
                    Text(gestureAction.displayName)
                        .tag(gestureAction)
                }
            }
            .pickerStyle(.menu)
            .frame(width: 180)

            // If the user selected "Keystroke…", show an inline text field
            // where they can type the key combination.
            if case .keystroke(let key, _) = action {
                keystrokeField(currentKey: key)
            }

            // If the user selected "Open App…", show a button to pick an application.
            if case .openApp(let bundleID) = action {
                openAppButton(currentBundleID: bundleID)
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - Keystroke Inline Field

    /// A small text field shown inline when the user chooses "Keystroke…".
    /// They type the key they want to press and it updates the action.
    @ViewBuilder
    private func keystrokeField(currentKey: String) -> some View {
        // We use a local @State binding trick via a wrapper.
        KeystrokeField(action: $action)
    }

    // MARK: - Open App Button

    /// A button shown inline when the user chooses "Open App…".
    /// Clicking it opens a file picker filtered to .app bundles.
    @ViewBuilder
    private func openAppButton(currentBundleID: String) -> some View {
        AppPickerButton(action: $action, currentBundleID: currentBundleID)
    }
}

// MARK: - KeystrokeField

/// Inline text field for entering a custom keystroke key.
private struct KeystrokeField: View {
    @Binding var action: GestureAction
    @State private var keyText: String = ""

    var body: some View {
        TextField("key", text: $keyText)
            .frame(width: 60)
            .textFieldStyle(.roundedBorder)
            .onAppear {
                if case .keystroke(let key, _) = action {
                    keyText = key
                }
            }
            .onChange(of: keyText) { newKey in
                // Preserve existing modifiers, just update the key.
                if case .keystroke(_, let modifiers) = action {
                    action = .keystroke(key: newKey, modifiers: modifiers)
                } else {
                    action = .keystroke(key: newKey, modifiers: [])
                }
            }
    }
}

// MARK: - AppPickerButton

/// Button that opens a file panel to pick an app when "Open App…" is selected.
private struct AppPickerButton: View {
    @Binding var action: GestureAction
    let currentBundleID: String

    var body: some View {
        Button(action: openAppPanel) {
            Text(currentBundleID.isEmpty ? "Choose\u{2026}" : shortName(for: currentBundleID))
                .lineLimit(1)
                .truncationMode(.middle)
        }
        .frame(maxWidth: 120)
    }

    private func shortName(for bundleID: String) -> String {
        // Show just the last component of the bundle ID for readability.
        // e.g., "com.apple.Safari" → "Safari"
        return bundleID.components(separatedBy: ".").last ?? bundleID
    }

    private func openAppPanel() {
        let panel = NSOpenPanel()
        panel.title = "Choose Application"
        panel.message = "Select the app to open when this gesture fires"
        panel.allowedContentTypes = [.applicationBundle]
        panel.allowsMultipleSelection = false
        panel.directoryURL = URL(fileURLWithPath: "/Applications")

        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            // Read the bundle ID from the selected .app bundle.
            if let bundle = Bundle(url: url), let bundleID = bundle.bundleIdentifier {
                action = .openApp(bundleID: bundleID)
            }
        }
    }
}

// MARK: - Preview (for Xcode Previews)

#if DEBUG
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
#endif
