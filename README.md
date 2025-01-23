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
9. [License](#license)

---

## 1. Overview

Gym Time is designed around a **separation of concerns**:

- **`TimerManager`** manages permanent timer configurations (name, active/rest durations, round counts), storing them in an App Group for sharing between iOS and watchOS.  
- **`TimerEngine`** manages ephemeral countdown details (remaining time, current round, active vs. rest phase), never persisting these to disk.  
- **`WatchConnectivityProvider`** synchronizes user actions (play, pause, reset) between devices, ensuring minimal latency.

---

## 2. Project Structure
### 2.1 Shared Codebase

- **`IntervalTimer.swift`**  
  A plain model type (`Identifiable`, `Codable`, `Equatable`, `Hashable`) that stores the permanent settings of an interval timer: name, activeDuration, restDuration, totalRounds.

- **`TimerAction.swift`**  
  An enum (`.play`, `.pause`, `.reset`) representing user actions.

- **`TimerManager.swift`**  
  - A singleton (`TimerManager.shared`) that persists timers to an App Group (`group.com.slo.Gym-Time`).  
  - Offers CRUD operations for adding/updating/deleting timers.

- **`TimerEngine.swift`**  
  - Maintains ephemeral countdown state (remainingTime, currentRound, phase).  
  - Provides methods for play, pause, reset, and transitions between active/rest phases.

- **`ActiveTimerEngines.swift`**  
  - A global store that returns the same `TimerEngine` instance for a given timer’s UUID.

- **`WatchConnectivityProvider.swift`**  
  - Manages data transfer over `WCSession`.  
  - Sends/receives action events and full timer lists between iOS and watchOS.

### 2.2 iOS Components

- **`TimerApp_iOS.swift`**  
  - Application entry point for iOS, injecting `TimerManager` and `WatchConnectivityProvider` into the environment.

- **`HomeView.swift`**  
  - Displays a list of timers.  
  - Shows a placeholder if empty.  
  - Allows creation of new timers via a “+” button.

- **`RowView.swift`**  
  - A single row in the list, showing name and a brief configuration.  
  - If `TimerEngine.isRunning`, displays a blue dot on the right.

- **`TimerView.swift`**  
  - Displays the current countdown, round indicators, and control buttons.  
  - Reset button appears on the left if not idle; Play/Pause button is either on the right or centered if idle.

- **`EditView.swift`**  
  - Edits an existing timer’s name/durations/round counts.

- **`CreateView.swift`**  
  - Gathers data for a new timer, using a wheel-based `DurationPicker` for easy minute/second selection.  
  - Persists to `TimerManager` on save.

### 2.3 watchOS Components

- **`TimerApp_watchOS.swift`**  
  - Application entry point on watchOS, similarly providing environment objects.

- **`WatchHomeView.swift`**  
  - Lists timers or displays a placeholder message if none exist.

- **`RowView.swift`**  
  - Minimal watch-friendly row with a possible blue dot if running.

- **`WatchTimerView.swift`**  
  - Displays the remaining time, round indicators, and two controls (play/pause and reset).  
  - Background color changes to green/red for active/rest phases.

---

## 3. Data Flow

1. **Creation/Editing**: iOS `CreateView` or `EditView` modifies timers in `TimerManager`. The watch is informed via `WatchConnectivityProvider.sendTimers(...)`.  
2. **Selection**: Tapping a timer row obtains a `TimerEngine` from `ActiveTimerEngines` and navigates to `TimerView` or `WatchTimerView`.  
3. **Actions**: Start/pause/reset. The local device updates its `TimerEngine` and sends an action event. The other device receives the event and updates its `TimerEngine` accordingly, compensating for network delay.

---

## 4. Synchronization Logic

**WatchConnectivity** handles two main data paths:

1. **Full Timer List**: Syncs the entire array of `IntervalTimer` objects.  
2. **Action Events**: A small payload (timestamp, remainingTime, isRestPeriod, currentRound) that triggers `.play`, `.pause`, or `.reset`.

**applyAction Method**:  
- Adjusts local ephemeral state to match the remote snapshot.  
- Recalculates any needed offsets to account for transmission delay.

---

## 5. TimerEngine Details

- **Phases**:
  - `.idle`: Not started or reset.  
  - `.active`: Counting down the active duration.  
  - `.rest`: Counting down the rest duration.  
  - `.completed`: All rounds finished.

- **Key Methods**:
  - **`play()`**: Starts or resumes the countdown.  
  - **`pause()`**: Temporarily halts the countdown and finalizes `remainingTime`.  
  - **`reset()`**: Returns to idle, setting `remainingTime` to the active duration.  
  - **`advancePeriod()`**: Moves from active to rest, or onto the next round, or to completed if all rounds are done.

---

## 6. Creating and Editing Timers

- **CreateView (iOS)**:  
  - Collects name, durations (via `DurationPicker`), and round count.  
  - Saves via `timerManager.addTimer(...)`.  
  - Immediately syncs to watch if connected.

- **EditView (iOS)**:  
  - Pre-fills current values.  
  - On save, updates existing timers via `timerManager.updateTimer(...)` and syncs changes.

No ephemeral state (like `remainingTime` or `currentRound`) is persisted; only the basic config.

---

## 7. User Interface Highlights

### iOS

- **HomeView**:  
  - List or placeholder.  
  - Navigation bar with a “+” to create new timers.

- **RowView**:  
  - Shows name and “∞ x M:SS | M:SS” or “X x M:SS | M:SS”.  
  - Tiny dot if running.

- **TimerView**:  
  - CircularProgressBar showing the countdown.  
  - Rest label toggled by opacity.  
  - Round indicators below.  
  - HStack for bottom controls:  
    - **Reset** (left) visible unless idle.  
    - **Play/Pause** (center if idle, right if not).  

### watchOS

- **WatchHomeView**:  
  - List or placeholder text.  
  - Tapping a row navigates to `WatchTimerView`.

- **WatchTimerView**:  
  - Remaining time on top, monospaced.  
  - White round indicators.  
  - Red/green background for rest/active.  
  - Buttons at bottom for play/pause & reset.

---

## 8. How to Contribute

1. **Fork** or **Branch** from the main repo.  
2. **Implement** features or bug fixes within the existing architectural guidelines:  
   - All persistent config in `TimerManager`.  
   - Ephemeral state in `TimerEngine`.  
   - Cross-device sync via `WatchConnectivityProvider`.  
3. **Submit a Pull Request**, ensuring your changes pass any CI checks (if enabled) and are well-tested.

### Code Style

- SwiftUI-based views.  
- Keep ephemeral vs. persistent logic separate.  
- Provide meaningful commit messages.  
- Test thoroughly on both iOS and watchOS simulators.

---

## 9. License

Gym Time is released under the [MIT License](LICENSE). Feel free to use, modify, and distribute this software in accordance with the license terms. We welcome feedback, contributions, and feature requests to continue improving the app’s cross-platform interval training experience.
