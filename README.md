# GestureKit

A macOS menu bar app that lets you map multitouch trackpad gestures to system actions — like middle-clicking, opening Mission Control, or launching apps — without lifting your fingers from the trackpad.

---

## System Requirements

- **macOS 13 (Ventura) or later**
- A MacBook with a built-in trackpad (or an external Apple Magic Trackpad)
- Apple Silicon (M1/M2/M3) or Intel processor

---

## Installation

1. **Download** `GestureKit.dmg` from the releases page.
2. **Open the DMG** by double-clicking it — a window appears with the GestureKit icon.
3. **Drag GestureKit** to the **Applications** folder shortcut in the DMG window.
4. **Eject the DMG** by right-clicking it in Finder and choosing "Eject".
5. **Open GestureKit** from your Applications folder.

> If macOS says "GestureKit cannot be opened because the developer cannot be verified", go to
> **System Settings → Privacy & Security → scroll down → click "Open Anyway"**.

---

## Granting Accessibility Permission

GestureKit needs **Accessibility access** to simulate mouse clicks and keyboard shortcuts on your behalf. Without it, gestures won't do anything.

**How to grant permission:**

1. Open **GestureKit** — you'll see its hand icon appear in the menu bar (top right of your screen).
2. A dialog may appear automatically asking for Accessibility access. Click **"Open System Settings"**.
3. If no dialog appears, go to:
   **System Settings → Privacy & Security → Accessibility**
4. Find **GestureKit** in the list and **toggle it ON**.
5. You may need to enter your Mac password.

Once granted, GestureKit activates automatically — no restart needed.

---

## Default Gesture Mappings

Out of the box, GestureKit comes pre-configured with two gestures:

| Gesture                    | Default Action    |
|----------------------------|-------------------|
| Three Finger Tap           | Middle Click      |
| Three Finger Click (hold)  | None              |
| Force Click — Top Left     | Mission Control   |
| Force Click — Top Right    | None              |
| Force Click — Bottom Left  | None              |
| Force Click — Bottom Right | None              |

**Three Finger Tap** — Quickly touch the trackpad with three fingers and lift them. Great for middle-clicking links to open them in new browser tabs.

**Three Finger Click** — Touch the trackpad with three fingers and hold for about 0.2 seconds. Configure this to whatever you use most.

**Force Click Corner** — Press firmly with one finger in a corner of the trackpad. The four corners (top-left, top-right, bottom-left, bottom-right) each have their own configurable action.

---

## How to Customise Your Gestures

1. Click the **hand icon** in the menu bar.
2. Choose **Settings...** from the dropdown menu.
3. The Settings window opens. You'll see six rows — one for each gesture.
4. Click the **dropdown picker** on the right side of any row to choose an action.
5. Changes take effect **immediately** — no Save button needed.
6. Close the window when you're done (the app keeps running in the menu bar).

### Available Actions

| Action          | What it does                                                      |
|-----------------|-------------------------------------------------------------------|
| None            | The gesture is disabled / does nothing                            |
| Middle Click    | Simulates pressing the middle mouse button at the cursor position |
| Mission Control | Shows all open windows and Spaces (same as pressing F3)          |
| App Expose      | Shows all windows of the currently active app                    |
| Show Desktop    | Moves all windows aside to reveal the Desktop                    |
| Keystroke...    | Sends a custom key combination (e.g., Cmd+Space for Spotlight)   |
| Open App...     | Launches or focuses an application you choose from a file picker |

---

## Quitting GestureKit

1. Click the **hand icon** in the menu bar.
2. Choose **Quit GestureKit**.

Your settings are automatically saved and will be restored next time you launch.

---

## Troubleshooting

**Gestures aren't working**
→ Make sure Accessibility permission is granted (see above). The menu bar icon will show an orange tint and an "Enable Accessibility..." item if permission is missing.

**The app doesn't appear in the Dock**
→ That's normal! GestureKit is designed to live only in the menu bar, not the Dock. Look for the hand icon in the top-right area of your screen.

**I don't see the GestureKit icon in the menu bar**
→ On Macs with a notch or many menu bar icons, some icons may be hidden. Try scrolling with two fingers in the menu bar area, or use a menu bar manager app to make room.

**App Expose or Show Desktop isn't responding**
→ These actions use the system keyboard shortcuts (Control+Down, F11). Make sure you haven't disabled those in System Settings → Keyboard → Keyboard Shortcuts → Mission Control.

---

## Privacy

GestureKit does not connect to the internet, does not send any data anywhere, and does not log your gestures. All settings are stored locally on your Mac in your user preferences (`~/Library/Preferences/`).

---

## Building from Source

If you want to build GestureKit yourself:

```bash
# Clone the repository
git clone https://github.com/vuhpquang/mac-shortcuts.git
cd mac-shortcuts

# Build using Swift Package Manager
swift build -c release

# Or build a distributable DMG (requires Xcode + Developer ID certificate)
./build.sh
```

See `build.sh` for full distribution build instructions including code signing and notarization.

### Running Locally (development build)

```bash
# Debug build (faster compile, verbose logs)
swift build

# Run directly from the build output
.build/debug/GestureKit
```

When running a debug build, GestureKit behaves exactly like the release version. It will appear in the menu bar and request Accessibility permission as normal. To quit, use the menu bar icon → **Quit GestureKit**, or press `Ctrl+C` in the terminal.

> **Tip:** You can run multiple instances from different branches by building each one and launching from its own `.build/` path.

### Coding & Debugging in Xcode

GestureKit uses Swift Package Manager, so Xcode opens it without any extra setup:

```bash
# Open the package in Xcode
open Package.swift
```

Xcode will resolve the package and show the full source tree under **Sources/GestureKit/**.

**Useful debug tips:**

- **Print logging** — every major component (`DeviceMonitor`, `GestureRecognizer`, `GestureCoordinator`) emits `[GestureKit]`-prefixed log lines. Run the app from Xcode and watch the console (View → Debug Area → Activate Console).
- **Breakpoints** — set breakpoints inside `GestureRecognizer.swift` on `didReceiveFingers` or the gesture-emit calls to inspect live finger data as you move on the trackpad.
- **Accessibility in the debugger** — macOS may require you to add `Xcode` (or your terminal app) to the Accessibility list, not just GestureKit, when running under the debugger. Go to **System Settings → Privacy & Security → Accessibility** and add both.
- **Simulating gestures without a trackpad** — there is no simulator for MultitouchSupport. You need a physical trackpad. A Magic Trackpad connected via USB or Bluetooth works the same as a built-in one.
- **Scheme settings** — in Xcode, select the **GestureKit** scheme and go to **Edit Scheme → Run → Arguments** to pass environment variables (e.g., `NOTARIZE=1` for a full distribution build test).

---

*GestureKit — making your trackpad work harder for you.*
