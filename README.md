# Focus Desk: Flutter desktop focus timer with backend sync

A desktop app (Windows, macOS, Linux) built with **Flutter** and **Dart**. It has a focus timer with a custom-painted ring, a task queue with tags and drag-to-reorder, a break cycle, daily goals, a stats screen with streaks, and a settings screen. Finished sessions are saved on the device first and synced to the **Relay** Dart backend (separate repo) when it is reachable, so the app works offline.

## Features
- **Timer:** focus, short break and long break, with a long break after every Nth block. Breaks can start automatically.
- **Tasks:** minutes per task, tags, remove, reorder by dragging, clear finished.
- **Stats:** today, this week vs last week, current and best streak, 14-day bars with the daily goal, minutes by tag, recent sessions.
- **Settings:** block and break lengths, daily goal, notifications, Relay URL.
- **Offline queue:** unsynced sessions are retried in order. The sidebar shows synced, waiting or offline.
- **Notifications:** a desktop notification when a block or break ends (local_notifier).

**Tech:** Flutter desktop, Dart, CustomPainter, Provider, shared_preferences, window_manager, local_notifier, http, bearer-token auth, Material 3 light editorial theme.

## Layout
```
lib/models     Task, Session, Settings, StatsCalc (pure functions)
lib/services   storage, Relay sync, notifier
lib/state      TimerModel (timer, queue, break cycle, sync)
lib/pages      home, today, stats, settings
lib/widgets    ring and bar painters
test/          stats, models, storage, sync, timer model, widget
```

## Run
```bash
flutter config --enable-macos-desktop   # or windows / linux
flutter pub get
flutter run -d macos --dart-define=RELAY_URL=http://localhost:8080 --dart-define=RELAY_USER=admin --dart-define=RELAY_PASS=admin123
flutter test
```

## Honest status
The code has not been run on a device and the tests have not been run yet. Run `flutter analyze` and `flutter test` first. Notifications need a real desktop to check. Screenshots in `docs/` are UI mockups, not recordings.

## Screens (design mockups, not recordings)
![focus-1-timer](docs/focus-1-timer.jpg)
![focus-2-stats](docs/focus-2-stats.jpg)
