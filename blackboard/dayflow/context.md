# Project: DayFlow

## Goal
Multiplatform timeline calendar app — see your full day as a vertical time axis with events at their exact times. Like TickTick's Calendar view but standalone on Android, Web, and macOS.

## Platform
Android · Web · macOS (multiplatform)

## Tech stack
- Framework: Flutter (Dart) — single codebase for all 3 platforms
- Calendar sync: Google Calendar API (OAuth 2.0)
- Local cache: SQLite (via drift or sqflite)
- State: Riverpod or Bloc
- macOS: menu bar integration via flutter_menubar
- Android: home screen widget
