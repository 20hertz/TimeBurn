# TimeBurn

TimeBurn is a cross-platform interval timer application for iOS and watchOS. It lets users create timers with custom active and rest durations, round counts, and optional infinite runs. Timers are synchronized between iOS and watchOS, ensuring that when a user starts, pauses, or resets a timer on one device, the other device remains in sync.

---

## Table of Contents

1. [Overview](#overview)
2. [Project Structure](#project-structure)  
   2.1 [Shared Codebase](#shared-codebase)  
   2.2 [iOS Components](#ios-components)  
   2.3 [watchOS Components](#watchos-components)
3. [Data Flow](#data-flow)
4. [Synchronization Logic](#synchronization-logic)
5. [TimerEngine Details](#timerengine-details)
6. [Creating and Editing Timers](#creating-and-editing-timers)
7. [User Interface Highlights](#user-interface-highlights)

---

## 1. Overview

TimeBurn is designed around a **separation of concerns**:

- **`TimerManager`** manages permanent timer configurations (name, active/rest durations, round counts), storing them in an App Group for sharing between iOS and watchOS.
- **`TimerEngine`** manages ephemeral countdown details (remaining time, current round, active vs. rest phase), never persisting these to disk.
- **`WatchConnectivityProvider`** synchronizes user actions (play, pause, reset) between devices, ensuring minimal latency and consistent ephemeral state.

Timers can be **started** and **controlled** on either device. Whichever device initiates an action is the “Lead Device,” immediately applying the action locally, then notifying the other device to stay in sync.

---

## 2. Project Structure

### 2.1 Shared Codebase

- **`IntervalTimer.swift`**  
  A plain model type (`Identifiable`, `Codable`, `Equatable`, `Hashable`) that stores the permanent settings of an interval timer:

  - `name`, `activeDuration`, `restDuration`, `totalRounds`

- **`TimerAction.swift`**  
  An enum (`.play`, `.pause`, `.reset`) representing user actions.

- **`TimerManager.swift`**

  - A singleton (`TimerManager.shared`) that persists timers to an App Group (`group.com.slo.TimeBurn`).
  - Offers CRUD operations for adding, updating, and deleting timers.

- **`TimerEngine.swift`**

  - Maintains ephemeral countdown state (`remainingTime`, `currentRound`, `phase`).
  - Provides methods for `play()`, `pause()`, `reset()`, and transitions between active/rest phases.
  - Implements “lead device” logic by resetting any other running timers (optional) before playing a new one if desired.

- **`ActiveTimerEngines.swift`**

  - A global store returning a unique `TimerEngine` instance per timer’s UUID.

- **`WatchConnectivityProvider.swift`**
  - Manages data transfer over `WCSession`.
  - Sends/receives action events (`.play`, `.pause`, `.reset`) and full timer lists between iOS and watchOS.

### 2.2 iOS Components

- **`TimerApp_iOS.swift`**

  - Application entry point for iOS.
  - Injects `TimerManager` and `WatchConnectivityProvider` as environment objects.

- **`HomeView.swift`**

  - Displays a list of timers or a placeholder if empty.
  - Allows creation of new timers via a “+” button.

- **`RowView.swift`**

  - A single row showing timer name and a brief configuration.
  - Displays a small blue dot if the associated `TimerEngine.isRunning`.

- **`TimerView.swift`**

  - Shows the current countdown, round indicators, and main controls (Reset, Play/Pause).
  - Circular progress UI for active/rest durations.
  - Uses `applyAction(...)` for user actions so any other running timer can be reset if needed.

- **`EditView.swift`**

  - Edits an existing timer’s name/durations/round counts.

- **`CreateView.swift`**
  - Gathers data for a new timer using a wheel-based duration picker.
  - Saves to `TimerManager`.

### 2.3 watchOS Components

- **`TimerApp_watchOS.swift`**

  - Application entry point on watchOS, similarly providing environment objects.

- **`WatchHomeView.swift`**

  - Lists timers or displays a placeholder if none exist.

- **`RowView.swift`**

  - A compact watch-friendly row with a blue running indicator if `isRunning`.

- **`WatchTimerView.swift`**
  - Displays the remaining time, round indicators, and play/pause/reset controls.
  - Background color changes to green/red for active/rest phases.
  - Also calls `applyAction(...)` for local user actions, ensuring any other running timer is reset on both devices.

---

## 3. Data Flow

1. **Creation/Editing**

   - iOS `CreateView` or `EditView` modifies timers in `TimerManager`.
   - The watch is informed via `WatchConnectivityProvider.sendTimers(...)`.

2. **Selection**

   - Tapping a timer row obtains its `TimerEngine` from `ActiveTimerEngines`.
   - The user navigates to `TimerView` or `WatchTimerView`.

3. **Actions** (Play/Pause/Reset)
   - The local device applies the action immediately (the “Lead Device” approach) via `applyAction(...)`.
   - It sends an action event to the other device with the ephemeral snapshot.
   - The other device applies the same action, synchronizing the countdown.

---

## 4. Synchronization Logic

**WatchConnectivity** handles two primary data paths:

1. **Full Timer List**

   - Syncs the entire array of `IntervalTimer` objects across devices.

2. **Action Events**
   - A small payload (timestamp, `remainingTime`, `isRestPeriod`, `currentRound`).
   - Triggers `.play`, `.pause`, or `.reset` in `TimerEngine` on the receiving side.

### The Lead Device Pattern

Whichever device the user taps is the **lead device**:

- It immediately performs the local state transition by calling `applyAction(.play/.pause/.reset, …)`.
- It then sends an action message to the other device.
- The other device calls the same `applyAction(...)`, staying in sync without extra latencies.

This approach ensures minimal round-trip delays for the user’s local interactions.

---

## 5. TimerEngine Details

- **Phases**:

  - `.idle`: Timer is not started or has just been reset.
  - `.active`: Counting down the active duration.
  - `.rest`: Counting down the rest duration.
  - `.completed`: All rounds are finished.

- **Key Methods**:
  - **`play()`**: Begins or resumes the countdown, triggers `.idle → .active`.
  - **`pause()`**: Halts the countdown, finalizing `remainingTime`.
  - **`reset()`**: Returns the timer to `.idle`.
  - **`advancePeriod()`**: Moves from active → rest, or to the next round, or to `.completed` if all rounds are done.
  - Optionally, **when playing a new timer**, `TimerEngine` can **reset other running timers** so only one is active at a time, if desired.

No ephemeral state is ever persisted; it’s all in memory.

---

## 6. Creating and Editing Timers

- **CreateView (iOS)**

  - Inputs: timer name, durations, and round count (or 0 for infinite).
  - Calls `TimerManager.addTimer(...)`.
  - Immediately syncs to watch if connected.

- **EditView (iOS)**
  - Edits an existing `IntervalTimer`.
  - On save, updates `TimerManager` and syncs changes to watch.

---

## 7. User Interface Highlights

### iOS

- **HomeView**

  - Lists timers or shows a placeholder if none exist.
  - Top bar “+” for creating new timers.

- **RowView**

  - Displays the timer name and `∞ x M:SS | M:SS` or `X x M:SS | M:SS`.
  - A blue dot if `TimerEngine.isRunning`.

- **TimerView**
  - Shows a circular progress for the current countdown.
  - A Rest label is shown or hidden by opacity.
  - Round indicators, plus bottom controls (Reset on the left if active, Play/Pause).
  - Uses the “applyAction” approach for minimal code duplication.

### watchOS

- **WatchHomeView**

  - List of existing timers or placeholder if empty.

- **WatchTimerView**
  - Large monospaced countdown.
  - Background color changes to green/red for active/rest.
  - Play/Pause and Reset at the bottom.
  - Also calls `applyAction(...)` on local interactions to stay consistent with iOS.

---

### Code Style

- SwiftUI-based views
- Separate ephemeral logic (in-memory only) from persistent data.
- Keep commit messages descriptive.
- Thoroughly test on both iOS and watchOS.
