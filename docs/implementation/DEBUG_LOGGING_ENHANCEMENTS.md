# Debug Logging Enhancements

## Overview
This document describes the comprehensive debug logging improvements made to the Ying application to address the issue of unclear "unknown" data and missing logs for various operations.

## Changes Made

### 1. Fixed "Unknown" App State
**File:** `lib/services/debug_service.dart`
- Changed default `_appState` from `'Unknown'` to `'Initializing'`
- App lifecycle states are properly tracked in `lib/main.dart` via `didChangeAppLifecycleState`
- States include: Initializing, Resumed, Inactive, Paused, Detached, Hidden

### 2. Settings Provider Debug Logging
**File:** `lib/providers/settings_provider.dart`

Added comprehensive logging for all setting changes:

#### Theme Settings
- Theme mode changes (light/dark/system)
- Theme color changes
- Dark theme index changes
- Light theme index changes

#### Display Settings
- Font size changes (both scale and pixel values)
- Date format changes
- Card display format changes
- Font family changes
- Custom font installations

#### Background Settings
- Background image set/cleared
- Background effect changes
- Background blur adjustments

#### Particle Effects
- Particle type changes (none/sakura/rain/firefly/snow)
- Particle speed adjustments
- Particle global scope toggling

#### Progress Bar Settings
- Progress style changes
- Progress color updates
- Progress calculation method changes
- Progress fixed days adjustments

#### Sorting & Layout
- Sort order changes
- Custom sort order updates
- Cards expand/collapse state

#### Widget Configuration
- Widget type changes
- Widget config updates for all widget types

#### Cloud Sync Settings
- WebDAV URL configuration
- WebDAV username updates
- WebDAV password changes (logged without exposing password)
- Auto-sync enable/disable
- Sync completion events

#### Language Settings
- Language/locale changes

#### Debug Settings
- Debug mode enable/disable

### 3. Notification Service Debug Logging
**File:** `lib/services/notification_service.dart`

Added logging for notification lifecycle events:

#### Initialization
- Notification service initialization success/failure
- Timezone configuration

#### Permissions
- Notification permission granted/denied
- Exact alarm permission status

#### Notification Operations
- Notification scheduling (with event name and count)
- Notification cancellation (with event ID and count)
- All notifications cancellation
- Notification tap events (with payload)

#### Error Handling
- Initialization failures
- Scheduling failures
- Cancellation failures
- Tap handling errors

### 4. Events Provider Debug Logging
**File:** `lib/providers/events_provider.dart`

Added logging for event CRUD operations:

#### Event Creation
- Event created with title

#### Event Updates
- Event updated with title

#### Event Deletion
- Event deleted with title

## Log Format

All debug logs follow this format:
```
[HH:mm:ss] [level] [source] message
```

Where:
- **HH:mm:ss**: Time in 24-hour format
- **level**: info, warning, error, or debug
- **source**: The component generating the log (Settings, Notification, Events, etc.)
- **message**: Descriptive message about the operation

## Log Sources

The following sources are now used:
- `Settings`: All settings-related changes
- `Notification`: All notification operations
- `Events`: Event CRUD operations
- `Main`: App startup and initialization
- `AppLifecycle`: App state changes
- `Router`: Navigation events
- `System`: System information collection
- `DebugService`: Debug service operations

## Examples

### Settings Changes
```
[14:23:45] [info] [Settings] Theme mode changed: dark
[14:23:50] [info] [Settings] Particle type changed: sakura
[14:24:12] [info] [Settings] Font size (px) changed: 18.0
[14:25:01] [info] [Settings] Cloud sync completed
```

### Notification Events
```
[09:00:00] [info] [Notification] Notification service initialized
[09:00:05] [info] [Notification] Scheduled 3 reminders for event: Birthday Party
[09:30:15] [info] [Notification] Notification tapped: event-id-123
[10:15:22] [info] [Notification] Canceled 2 notifications for event: event-id-456
```

### Event Operations
```
[11:30:00] [info] [Events] Event created: New Year 2024
[11:35:12] [info] [Events] Event updated: New Year 2024
[12:00:45] [info] [Events] Event deleted: Old Event
```

## Benefits

1. **Clear Visibility**: All major operations are now logged with clear, descriptive messages
2. **Troubleshooting**: Easy to identify when and what changes were made
3. **Source Tracking**: Each log identifies which component generated it
4. **User Actions**: Settings changes, event edits, and notification events are all tracked
5. **Error Detection**: Failures are logged with error level for easy identification
6. **No More "Unknown"**: App state is properly initialized and tracked

## Debug Console Features

The debug console (`lib/screens/settings/debug_console_screen.dart`) provides:

1. **Three Tabs**:
   - Logs: All debug logs with filtering
   - Routes: Navigation history
   - System: System information

2. **Log Filtering**:
   - Filter by level (All, Info, Warning, Error, Debug)
   - Search by message or source
   - Real-time log count per filter

3. **Log Management**:
   - Automatic circular buffer (max 500 logs)
   - Clear logs function
   - Expandable log cards with full details

4. **Real-time Updates**:
   - Logs appear immediately via listener pattern
   - UI updates automatically when new logs are added

## Testing Recommendations

To verify the logging works correctly:

1. Enable debug mode in settings
2. Open the Debug Console
3. Make various changes:
   - Change theme settings
   - Modify display options
   - Create/edit/delete events
   - Toggle notification settings
   - Configure cloud sync
4. Observe logs appearing in real-time with proper sources and messages
5. Test filtering by level and search
6. Verify no "unknown" values appear in logs

## Future Enhancements

Potential improvements for future iterations:

1. Add log export functionality
2. Add log level configuration
3. Add timestamp filtering
4. Add log persistence across app restarts
5. Add performance metrics logging
6. Add network request logging
