# Gym Time

Gym Time is a cross-platform interval timer application for iOS and watchOS. It lets users create timers with custom active and rest durations, round counts, and optional infinite runs. Timers are synchronized between iOS and watchOS, ensuring that when a user starts, pauses, or resets a timer on one device, the other device remains in sync.

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
8. [How to Contribute](#how-to-contribute)

---

## 1. Overview

Gym Time is designed around a **separation of concerns**:

- **`TimerManager`** manages permanent timer configurations (name, active/rest durations, round counts), storing them in an App Group for sharing between iOS and watchOS.
- **`TimerEngine`** manages ephemeral countdown details (remaining time, current round, active vs. rest phase), never persisting these to disk.
- **`WatchConnectivityProvider`** synchronizes user actions (play, pause, reset) between devices, ensuring minimal latency and consistent ephemeral state.

---

## 2. Project Structure

### 2.1 Shared Codebase

- **`IntervalTimer.swift`**  
  A plain model type (`Identifiable`, `Codable`, `Equatable`, `Hashable`) that stores the permanent settings of an interval timer:

  - `name`, `activeDuration`, `restDuration`, `totalRounds`

- **`TimerAction.swift`**  
  An enum (`.play`, `.pause`, `.reset`) representing user actions.

- **`TimerManager.swift`**

  - A singleton (`TimerManager.shared`) that persists timers to an App Group (`group.com.slo.Gym-Time`).
  - Offers CRUD operations for adding, updating, and deleting timers.

- **`TimerEngine.swift`**

  - Maintains ephemeral countdown state (`remainingTime`, `currentRound`, `phase`).
  - Provides methods for `play()`, `pause()`, `reset()`, and transitions between active/rest phases.

- **`ActiveTimerEngines.swift`**

  - A global store returning a unique `TimerEngine` instance per timer’s UUID.

- **`WatchConnectivityProvider.swift`**
  - Manages data transfer over `WCSession`.
  - Sends/receives action events and full timer lists between iOS and watchOS.

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

---

## 3. Data Flow

1. **Creation/Editing**

   - iOS views (`CreateView` or `EditView`) modify timers in `TimerManager`.
   - The watch is informed via `WatchConnectivityProvider.sendTimers(...)`.

2. **Selection**

   - Tapping on a timer row fetches its `TimerEngine` from `ActiveTimerEngines`.
   - The user navigates to the timer view (iOS or watchOS).

3. **Actions** (Play/Pause/Reset)
   - The local device updates its `TimerEngine` immediately (the **Lead Device** approach).
   - It sends an action event to the other device, including a snapshot of ephemeral state.
   - The other device applies that action (`applyAction(...)`) to stay in sync, compensating for network delay.

---

## 4. Synchronization Logic

**WatchConnectivity** handles two primary data paths:

1. **Full Timer List**
   - Syncs the entire array of `IntervalTimer` objects across devices.
2. **Action Events**
   - A small payload with timestamp, `remainingTime`, `isRestPeriod`, and `currentRound`.
   - Triggers `.play`, `.pause`, or `.reset` on the receiving side.

### The Lead Device Pattern

Whichever device the user interacts with (iOS or watchOS) becomes the **lead device**:

- It immediately performs the local state transition by calling `play()`, `pause()`, or `reset()`, so there’s no latency for the user.
- It then sends an action message to the other device.
- The receiving device calls `applyAction(...)` without forcibly setting `phase`, allowing its own `play()` or `pause()` logic to execute any first‐transition bell or haptic feedback.

This ensures minimal round-trip delays and consistent ephemeral state on both watchOS and iOS.

---

## 5. TimerEngine Details

- **Phases**:

  - `.idle`: Timer is not started or has just been reset.
  - `.active`: Counting down the active duration.
  - `.rest`: Counting down the rest duration.
  - `.completed`: All rounds are finished.

- **Key Methods**:
  - **`play()`**: Starts or resumes the countdown. Triggers `.idle → .active` transitions.
  - **`pause()`**: Halts the countdown, finalizing `remainingTime`.
  - **`reset()`**: Returns the timer to `.idle`.
  - **`advancePeriod()`**: Moves from active → rest, or to the next round, or to `.completed` if all rounds are done.

No ephemeral state is persisted; all runtime tracking is purely in memory.

---

## 6. Creating and Editing Timers

- **CreateView (iOS)**

  - Inputs: timer name, active/rest durations, and round count (or 0 for infinite).
  - Calls `TimerManager.addTimer(...)` to store the new `IntervalTimer`.
  - Immediately syncs the new list to watch if connected.

- **EditView (iOS)**
  - Edits an existing `IntervalTimer`.
  - On save, updates `TimerManager` and sends the revised list to watch.

---

## 7. User Interface Highlights

### iOS

- **HomeView**
  - List of timers or a placeholder if none exist.
  - A “+” button in the navigation bar to create a new timer.
- **RowView**
  - Displays timer name and summary (“∞ x M:SS | M:SS” or “X x M:SS | M:SS”).
  - Blue dot if `TimerEngine.isRunning`.
- **TimerView**
  - Circular progress for the countdown.
  - Rest label shown/hidden by opacity.
  - Round indicators, then a bottom bar with **Reset** (on the left if active) and **Play/Pause**.

### watchOS

- **WatchHomeView**
  - List of timers or a placeholder if none exist.
- **WatchTimerView**
  - Remaining time in a large monospaced font.
  - Background changes color for active vs. rest.
  - **Play/Pause** and **Reset** buttons at the bottom.

---

## 8. How to Contribute

1. **Fork** or **Branch** from the main repo.
2. **Implement** features or bug fixes within the existing architectural guidelines:
   - All persistent config in `TimerManager`.
   - Ephemeral state in `TimerEngine`.
   - Cross-device sync via `WatchConnectivityProvider`.
3. **Submit a Pull Request**
   - Make sure your changes pass any Continuous Integration checks (if enabled).
   - Provide meaningful commit messages and test thoroughly on both iOS and watchOS simulators.

### Code Style

- SwiftUI-based views.
- Keep ephemeral (in-memory) logic separate from persistent data.
- Provide descriptive commit messages.
- Thoroughly test any changes on both platforms.
