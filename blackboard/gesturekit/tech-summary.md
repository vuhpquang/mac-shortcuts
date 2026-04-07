# GestureKit — Technical Summary

## What It Is

A macOS menu bar app (Swift, macOS 13+) that maps raw multitouch trackpad gestures to system actions. No Dock icon. Distributed as a DMG. No internet connection, no data collection.

---

## The Core Problem

Apple exposes no public API for raw multitouch finger data. GestureKit bypasses this by loading Apple's **private `MultitouchSupport.framework`** at runtime using `dlopen` / `dlsym`.

---

## Architecture — Pipeline Pattern

```
Trackpad Hardware
      ↓
MultitouchSupport.framework  (private, loaded via dlopen)
      ↓
DeviceMonitor                (C callback, raw MTFinger frames)
      ↓
GestureRecognizer            (stateful recognizer, emits GestureEvents)
      ↓
GestureCoordinator           (maps gesture → action, dispatches to main thread)
      ↓
ActionExecutor               (synthesizes OS events via CGEvent / NSWorkspace)
```

Each layer is separated by delegate protocols. `GestureCoordinator` is a singleton; no layer knows about UI.

---

## Key Technical Decisions

### 1. Private Framework via `dlopen` / `dlsym`

- Path: `/System/Library/PrivateFrameworks/MultitouchSupport.framework/MultitouchSupport`
- Functions loaded: `MTDeviceCreateList`, `MTRegisterContactFrameCallback`, `MTDeviceStart`, `MTDeviceStop`
- `RTLD_NOW` — fail-fast symbol resolution
- Degrades gracefully if the framework moves in a future macOS version

### 2. Reverse-Engineered `MTFinger` Struct

Struct layout derived from **raw byte dump analysis**, not documentation:

- `offset 32/36` — normalized position (0.0–1.0 floats)
- `offset 20` — touch state (integers 1–7)
- `offset 48` — contact size (used for palm rejection)
- `offset 92` — `zTotal` — pressure value (0.0–1.0), key to force-click detection

### 3. Gesture State Machines

**Three-finger tap:**
- Arms on 3+ contacts, fires if fingers lift within `tapMaxDuration` (500ms)
- Cooldown window prevents double-fire during the lift phase
- Palm rejection: contacts with `size > 1.0` discarded

**Force-click corner:**
- `zTotal >= 0.85` fires the gesture
- Corner zones: 30% of each trackpad edge (top-left, top-right, bottom-left, bottom-right)
- Drag guard: skips fingers with velocity magnitude above threshold
- Per-identifier `Set<Int32>` ensures one-fire-per-contact

### 4. Click Suppressor (`CGEventTap`)

Force-clicking generates a natural `leftMouseDown`. `ClickSuppressor` intercepts it:

- Installs a `CGEventTap` at `.cghidEventTap` (HID level, before apps)
- **Pre-arms** at `zTotal >= 0.81` (before gesture fires at 0.85) to guarantee interception timing
- Auto-disarms after 300ms if no click arrives
- Thread-safe via `NSLock`
- Handles macOS disabling taps after sleep via `reinstall()`

### 5. Action Execution

Uses `CoreGraphics` `CGEvent` to synthesize:

- **Middle click** — `otherMouseDown/Up` at cursor position (Y-axis flip: NSEvent uses bottom-left origin, CGEvent uses top-left)
- **Mission Control** — `Ctrl+Up`
- **App Expose** — `Ctrl+Down`
- **Show Desktop** — `F11`
- **Custom keystrokes** — Unicode char injection via `keyboardSetUnicodeString`
- **App launch** — `NSWorkspace.shared.openApplication` by bundle ID

### 6. Settings Persistence

`GestureAction` is a `Codable` enum with associated values. Custom `encode`/`decode` because Swift does not auto-synthesize `Codable` for enums with associated values. Stored in `~/Library/Preferences/` via `UserDefaults`. Hot-swapped at runtime via `GestureCoordinator.updateMapping()` — no restart needed.

---

## Stack

| Layer | Technology |
|---|---|
| Language | Swift 5.9, Swift Package Manager |
| UI | SwiftUI (Settings), AppKit (menu bar, `NSStatusItem`) |
| Gesture input | Private `MultitouchSupport.framework` via `dlopen` |
| Event synthesis | CoreGraphics `CGEvent`, `NSWorkspace` |
| Event interception | `CGEventTap` at HID level |
| Persistence | `UserDefaults` + custom `Codable` |
| Minimum OS | macOS 13 (Ventura) |

---

## Interview Talking Points

- **Why `dlopen`?** Apple's multitouch API is private — not in the SDK. `dlopen` loads it at runtime with graceful fallback if the path changes in future macOS.
- **How is force-click detected?** The `zTotal` field at offset 92 in `MTFinger` reliably crosses 0.85 only under deliberate pressure — confirmed via byte dump analysis.
- **Why pre-arm at 0.81, fire at 0.85?** The OS fires `leftMouseDown` at nearly the same pressure as the gesture threshold. The 4-point gap gives the `CGEventTap` time to be active before the OS click arrives.
- **Thread safety?** `ClickSuppressor` uses `NSLock`. All gesture actions dispatched to `DispatchQueue.main` since `NSWorkspace` and some CGEvent calls are main-thread sensitive.
- **No Xcode project?** Correct — pure Swift Package Manager. `open Package.swift` is enough for Xcode to resolve and open the full source tree.
