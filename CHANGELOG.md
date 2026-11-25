# Changelog

## 2.0.0
- Split the app into models, services, state, pages and widgets.
- Stats screen: today, week vs last week, current and best streak, 14-day bars with a goal marker, minutes by tag, recent sessions.
- Settings screen: focus, short and long break lengths, long break cadence, auto-start breaks, daily goal, notifications, Relay URL.
- Break cycle: a long break after every Nth focus block.
- Tasks: tags, remove, drag to reorder, clear finished.
- Offline queue: sessions are saved on the device and sent to Relay when it is reachable. The sidebar shows the sync state.
- Desktop notifications when a block or a break ends (local_notifier).
- Unit tests for stats, models, storage, sync, the timer and a widget.

## 1.0.0
- Timer with a progress ring, task queue, session sync to Relay.
