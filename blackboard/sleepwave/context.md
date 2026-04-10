# Project: SleepWave

## Goal
Android alarm app that tracks sleep cycles via accelerometer and wakes you at the lightest sleep phase within a configurable window — like Sleep as Android but leaner and open.

## Platform
Android native

## Tech stack
- Language: Kotlin
- UI: Jetpack Compose
- Sensors: SensorManager (accelerometer + gyroscope)
- Scheduling: AlarmManager + ForegroundService + WakeLock
- Storage: Room database
- Audio: MediaPlayer / ExoPlayer
