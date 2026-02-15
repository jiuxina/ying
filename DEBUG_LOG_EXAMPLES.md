# Debug Console Log Examples

This document provides visual examples of what users will see in the debug console after the enhancements.

## App Lifecycle Logs

```
[09:00:00] [info] [Main] App started
[09:00:01] [info] [System] System info collected
[09:00:01] [info] [DebugService] Debug service initialized
[09:00:02] [info] [AppLifecycle] App state changed: Resumed
```

## Settings Change Logs

### Theme and Appearance Changes
```
[10:15:23] [info] [Settings] Theme mode changed: dark
[10:15:30] [info] [Settings] Theme color changed: index=3
[10:15:45] [info] [Settings] Dark theme index: 2
[10:16:12] [info] [Settings] Font size (px) changed: 18.0
[10:16:20] [info] [Settings] Font family changed: system default
```

### Background and Effects
```
[10:30:15] [info] [Settings] Background image set
[10:30:22] [info] [Settings] Background effect changed: gradient
[10:30:28] [info] [Settings] Background blur changed: 15.0
[10:31:05] [info] [Settings] Particle type changed: sakura
[10:31:12] [info] [Settings] Particle speed changed: 0.7
[10:31:18] [info] [Settings] Particle global scope: enabled
```

### Progress Bar Settings
```
[11:00:00] [info] [Settings] Progress bar style changed: background
[11:00:10] [info] [Settings] Progress bar color changed
[11:00:15] [info] [Settings] Progress calculation method: fixed
[11:00:20] [info] [Settings] Progress fixed days: 30
```

### Widget Configuration
```
[11:30:00] [info] [Settings] Widget type changed: large
[11:30:05] [info] [Settings] Widget config updated: large
```

### Cloud Sync
```
[12:00:00] [info] [Settings] WebDAV URL configured
[12:00:05] [info] [Settings] WebDAV username configured
[12:00:10] [info] [Settings] WebDAV password updated
[12:00:15] [info] [Settings] Auto sync enabled
[12:05:30] [info] [Settings] Cloud sync completed
```

### Other Settings
```
[13:00:00] [info] [Settings] Language changed: en
[13:00:10] [info] [Settings] Date format changed: MM/dd/yyyy
[13:00:20] [info] [Settings] Card display format changed: detailed
[13:00:30] [info] [Settings] Sort order changed: daysDesc
[13:00:40] [info] [Settings] Cards expanded
[13:00:50] [info] [Settings] Debug mode enabled
```

## Notification Event Logs

### Initialization
```
[09:00:02] [info] [Notification] Notification service initialized
```

### Permission Events
```
[09:00:05] [warning] [Notification] Notification permission denied
```

### Scheduling Notifications
```
[14:00:00] [info] [Notification] Scheduled 3 reminders for event: Birthday Party
[14:00:15] [info] [Notification] Scheduled 1 reminders for event: Anniversary
[14:00:30] [warning] [Notification] Failed to schedule 1 reminders for: Old Event
```

### Canceling Notifications
```
[14:30:00] [info] [Notification] Canceled 2 notifications for event: abc-123
[14:30:15] [info] [Notification] All notifications canceled
```

### Notification Interactions
```
[15:00:00] [info] [Notification] Notification tapped: event-id-456
[15:00:05] [error] [Notification] Failed to handle notification tap: Event not found
```

## Event Operation Logs

### Creating Events
```
[16:00:00] [info] [Events] Event created: New Year 2024
[16:00:15] [info] [Notification] Scheduled 2 reminders for event: New Year 2024
```

### Updating Events
```
[16:30:00] [info] [Events] Event updated: Birthday Party
[16:30:01] [info] [Notification] Canceled 3 notifications for event: xyz-789
[16:30:02] [info] [Notification] Scheduled 4 reminders for event: Birthday Party
```

### Deleting Events
```
[17:00:00] [info] [Notification] Canceled 2 notifications for event: old-event-id
[17:00:01] [info] [Events] Event deleted: Old Event
```

## Navigation Logs

```
[10:00:00] [debug] [Router] Navigation: /
[10:05:00] [debug] [Router] Navigation: /settings
[10:10:00] [debug] [Router] Navigation: /settings/debug_console
[10:15:00] [debug] [Router] Navigation: /event_detail
```

## Error Examples

```
[18:00:00] [error] [Notification] Notification service init failed: Permission denied
[18:05:00] [error] [Notification] Failed to cancel notifications: Database error
[18:10:00] [warning] [Notification] Notification permission denied
```

## Complete User Journey Example

Here's what a typical user session might look like in the debug console:

```
[09:00:00] [info] [Main] App started
[09:00:01] [info] [System] System info collected
[09:00:01] [info] [DebugService] Debug service initialized
[09:00:02] [info] [Notification] Notification service initialized
[09:00:02] [info] [AppLifecycle] App state changed: Resumed
[09:00:03] [debug] [Router] Navigation: /

[09:05:00] [debug] [Router] Navigation: /settings
[09:05:30] [info] [Settings] Theme mode changed: dark
[09:06:00] [info] [Settings] Particle type changed: sakura
[09:06:15] [info] [Settings] Particle speed changed: 0.5

[09:10:00] [debug] [Router] Navigation: /
[09:10:30] [info] [Events] Event created: Team Meeting
[09:10:31] [info] [Notification] Scheduled 2 reminders for event: Team Meeting

[09:15:00] [debug] [Router] Navigation: /event_detail
[09:15:30] [info] [Events] Event updated: Team Meeting
[09:15:31] [info] [Notification] Canceled 2 notifications for event: abc-123
[09:15:32] [info] [Notification] Scheduled 3 reminders for event: Team Meeting

[09:20:00] [info] [Notification] Notification tapped: abc-123
[09:20:01] [debug] [Router] Navigation: /event_detail

[09:25:00] [debug] [Router] Navigation: /settings
[09:25:30] [info] [Settings] Auto sync enabled
[09:25:35] [info] [Settings] WebDAV URL configured
[09:25:40] [info] [Settings] WebDAV username configured
[09:25:45] [info] [Settings] WebDAV password updated

[09:30:00] [info] [Settings] Cloud sync completed

[09:35:00] [info] [AppLifecycle] App state changed: Paused
```

## Debug Console UI

When users open the Debug Console, they will see:

### Logs Tab
- Filter chips: All (46), Info (40), Warning (3), Error (2), Debug (1)
- Search bar with placeholder "搜索日志..."
- Log count: "显示 46 / 46 条日志"
- Clear button: "清空日志"
- Scrollable list of log cards showing:
  - Level badge (colored)
  - Timestamp
  - Source tag
  - Message
  - Expandable for full details

### Routes Tab
- List of navigation history:
  ```
  09:00:03 -> /
  09:05:00 -> /settings
  09:10:00 -> /
  09:15:00 -> /event_detail
  09:20:01 -> /event_detail
  09:25:00 -> /settings
  ```

### System Tab
- Platform information:
  ```
  Platform: android
  Platform Version: Android 13
  Dart Version: 3.x.x
  Processors: 8
  Locale: zh_CN
  OS: Android
  App State: Resumed
  ```

## Benefits for Users

1. **Transparency**: Users can see exactly what the app is doing
2. **Troubleshooting**: Easy to identify what changed and when
3. **Verification**: Confirm that settings changes took effect
4. **Support**: Detailed logs help with bug reports
5. **Learning**: Understand how the app works internally

## Benefits for Developers

1. **Debugging**: Quick identification of issues
2. **Testing**: Verify feature functionality
3. **Monitoring**: Track user actions and app behavior
4. **Optimization**: Identify unnecessary operations
5. **Documentation**: Logs serve as runtime documentation
