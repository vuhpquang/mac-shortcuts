# Project Ideas Backlog

---

## Project 1 — Boardcast

**Name:** Boardcast
**Summary:** Host the agent team's blackboard as a live web app so you can view task state, send messages to agents, and control the team from anywhere — not just localhost.

**Platform:** Web (hosted) — React frontend + lightweight Node/Python backend, deployable to Railway / Fly.io / Vercel

**Technical needs:**
- REST or WebSocket API to read/write `.agents/blackboard.md` and relay messages
- File watcher that pushes blackboard changes to clients in real-time (SSE or WebSocket)
- Auth (simple token or OAuth) to protect the control panel from public access
- Relay endpoint (`POST /send`) forwarded to the tmux agent sessions (or a persistent relay daemon)
- Deploy pipeline: Docker container or serverless functions

**Prerequisite:**
- Current blackboard system working locally (`bash start.sh`)
- A VPS or PaaS account (Railway, Fly.io, or similar)
- Reverse proxy / SSH tunnel if agents still run locally (or agent sessions moved to server)

**Features:**
- Live blackboard view — tasks, status, blocked items auto-refresh
- Project switcher — switch between projects remotely
- Send message to any agent or all agents via chat bar
- Task editor — create / update / unblock tasks directly in UI
- Decisions log viewer (`.logs/decisions.md`)
- Mobile-responsive layout for phone access

**Checklist:**
- [ ] Design API schema (GET /blackboard, POST /task, POST /relay)
- [ ] Build file-watch → SSE push for live updates
- [ ] Port dashboard UI to React (or adapt existing HTML)
- [ ] Add token-based auth middleware
- [ ] Dockerize the server
- [ ] Deploy and verify remote access
- [ ] Test relay → tmux round-trip from remote network

---

## Project 2 — SleepWave

**Name:** SleepWave
**Summary:** Android alarm app that tracks sleep cycles via accelerometer and wakes you at the lightest sleep phase within a configurable window — like Sleep as Android but leaner and open.

**Platform:** Android native (Kotlin + Jetpack Compose)

**Technical needs:**
- Accelerometer + gyroscope sampling via `SensorManager` in a foreground `Service`
- Sleep phase classification algorithm (movement intensity → light/deep sleep model)
- `AlarmManager` with exact alarm scheduling (wake lock)
- Audio playback with gradual volume ramp (`MediaPlayer` or `ExoPlayer`)
- Local `Room` DB for sleep session history
- Background battery optimization exemption handling

**Prerequisite:**
- Android Studio + Kotlin environment
- Physical Android device for testing (emulator cannot simulate sensors accurately)
- Basic understanding of sleep cycle science (90-min cycles, REM/NREM)

**Features:**
- Set alarm with smart wake window (e.g. wake anytime in the 30 min before target time)
- Live sleep phase indicator during night
- Sleep quality score + duration shown on wake
- Gentle alarm sounds with gradual volume
- Captcha or puzzle to fully dismiss alarm (prevent snooze abuse)
- Sleep history chart (weekly average quality, duration)
- Do Not Disturb / silent hour integration
- Snooze with configurable limit

**Checklist:**
- [ ] Sensor sampling service (foreground, battery-safe)
- [ ] Sleep phase detection algorithm (threshold-based MVP)
- [ ] Alarm scheduling with exact timing + wake lock
- [ ] Gradual audio ramp on alarm trigger
- [ ] Dismiss screen with captcha
- [ ] Room DB schema: sessions, phases, alarms
- [ ] Sleep history UI
- [ ] Battery optimization exemption flow
- [ ] Test on real device overnight

---

## Project 3 — DayFlow

**Name:** DayFlow
**Summary:** Multiplatform timeline calendar app — see your full day as a vertical time axis with events, tasks, and blocks at their exact times. Like TickTick's Calendar view but as a standalone app on Android, Web, and macOS.

**Platform:** Android · Web · macOS (Flutter or Kotlin Multiplatform + Compose Multiplatform)

**Technical needs:**
- Multiplatform framework: Flutter (fastest) or Compose Multiplatform (native feel)
- Calendar data source: Google Calendar API (OAuth 2.0) + optional CalDAV for Apple Calendar
- Timeline scroll UI: custom canvas or `LazyColumn` with time slot rendering
- Local cache layer for offline access
- Drag-and-drop event rescheduling
- Platform-specific: Android notifications, macOS menu bar integration

**Prerequisite:**
- Google Cloud project with Calendar API enabled + OAuth credentials
- Flutter SDK or Compose Multiplatform setup
- Apple Developer account (for macOS distribution)
- Google Play account (for Android distribution)

**Features:**
- Vertical timeline day view (hour slots, current time indicator)
- Week view with day columns
- Tap slot to create event
- Drag-and-drop to reschedule
- Google Calendar sync (read + write)
- Multiple calendar overlays with color coding
- Task list sidebar (optional integration with task apps)
- Dark mode
- macOS: lives in menu bar, shows today's timeline on click
- Android: home screen widget with today's timeline

**Checklist:**
- [ ] Set up multiplatform project structure
- [ ] Google Calendar OAuth flow (all 3 platforms)
- [ ] Timeline scroll UI component
- [ ] Event rendering at correct time positions
- [ ] Create / edit / delete event flows
- [ ] Drag-and-drop rescheduling
- [ ] Local cache + offline mode
- [ ] macOS menu bar integration
- [ ] Android widget
- [ ] Web PWA manifest + install prompt
- [ ] Sync conflict resolution

---

## Project 4 — FrameShot

**Name:** FrameShot
**Summary:** macOS native screenshot capture and annotation tool — capture regions, windows, or full screen, annotate with arrows/text/blur/shapes, and copy or save instantly. Inspired by CleanShot X and Shottr.

**Platform:** macOS native (Swift + SwiftUI + AppKit where needed)

**Technical needs:**
- `ScreenCaptureKit` (macOS 12.3+) for capture — region, window, full screen
- `Core Image` + `NSBezierPath` / `CGContext` for annotation rendering
- `NSStatusItem` for menu bar icon + global hotkey registration (`CGEventTap` or `NSEvent.addGlobalMonitorForEvents`)
- `NSPasteboard` for clipboard copy
- `NSPanel` floating annotation window (stays above other windows)
- Scrolling capture: stitch multiple screenshots via scroll simulation

**Prerequisite:**
- Xcode 15+ on macOS 13+
- Apple Developer account (for notarization + distribution outside App Store)
- Screen Recording permission in System Settings (user must grant)
- Basic CoreGraphics knowledge

**Features:**
- Capture modes: region (crosshair), window (click to select), full screen
- Annotation tools: arrow, line, rectangle, circle, text label, freehand
- Blur / pixelate tool for redacting sensitive content
- Highlight tool (colored overlay)
- Undo/redo for annotations
- Copy to clipboard instantly
- Save to file (PNG, JPG) with configurable default folder
- Pin screenshot to screen (floating overlay)
- Scrolling capture (auto-scroll and stitch)
- Menu bar icon with hotkey (default: ⌘⇧4 style)
- Delay capture (1s / 3s / 5s timer)
- History panel — recent captures in-app

**Checklist:**
- [ ] Menu bar app scaffold (LSUIElement, NSStatusItem)
- [ ] Global hotkey registration
- [ ] Region capture with crosshair overlay (ScreenCaptureKit)
- [ ] Window capture (window picker)
- [ ] Annotation canvas (NSPanel floating)
- [ ] Arrow, rectangle, circle, text tools
- [ ] Blur/pixelate tool
- [ ] Undo/redo stack
- [ ] Copy to clipboard
- [ ] Save to file with folder picker
- [ ] Pin to screen (floating NSPanel, always on top)
- [ ] Scrolling capture
- [ ] Capture history panel
- [ ] Notarize + package for distribution
