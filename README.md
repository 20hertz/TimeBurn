# TimeBurn

TimeBurn is a cross-platform interval timer application for iOS and watchOS designed for fitness professionals and gym owners. It allows users to create, edit, and run interval timers with customizable active/rest durations, round counts (including infinite rounds), and optional bell sound cues. The app synchronizes timers between iOS and watchOS devices using a lead device pattern to ensure minimal latency and consistent state.

This README.md is written to provide a comprehensive overview of the project’s architecture, data flow, key components, and coding conventions so that a new AI coding assistant can hit the ground running with this project.

---

## Table of Contents

1. [Overview](#overview)
2. [Project Structure](#project-structure)
   - [Shared Codebase](#shared-codebase)
   - [iOS Components](#ios-components)
   - [watchOS Components](#watchos-components)
3. [Data Flow and Synchronization](#data-flow-and-synchronization)
4. [TimerEngine Details](#timerengine-details)
5. [Creating and Editing Timers](#creating-and-editing-timers)
6. [User Interface Highlights](#user-interface-highlights)
7. [Code Style and Conventions](#code-style-and-conventions)
8. [Additional Notes](#additional-notes)

---

## 1. Overview

TimeBurn is built on a clear separation of concerns:

- **Persistent Configuration:** Managed by `TimerManager` and stored in an App Group, the permanent settings (timer name, active duration, rest duration, round count, and sound setting) are maintained across sessions.
- **Ephemeral State:** Managed by `TimerEngine`, which handles countdowns, phase transitions (idle, active, rest, completed), and round management in memory.
- **Synchronization:** The `WatchConnectivityProvider` handles data transfer between iOS and watchOS. When a user performs an action on one device, that device becomes the "lead device" and immediately applies the action locally, then sends the change to the other device for synchronization.

---

## 2. Project Structure

### Shared Codebase

- **IntervalTimer.swift**  
  Defines the `IntervalTimer` model (conforming to `Identifiable`, `Codable`, `Equatable`, and `Hashable`), which stores the timer's permanent settings.

- **TimerAction.swift**  
  An enum representing user actions: `.play`, `.pause`, and `.reset`.

- **TimerManager.swift**  
  A singleton that manages a list of `IntervalTimer` configurations. It provides CRUD operations and persists data via an App Group.

- **TimerEngine.swift**  
  Manages the ephemeral countdown state for an interval timer, including the remaining time, current round, and current phase. It implements methods such as `play()`, `pause()`, `reset()`, `advancePeriod()`, and `nextRound()`.

- **ActiveTimerEngines.swift**  
  Provides a global store of `TimerEngine` instances, ensuring that each timer configuration is associated with a unique engine.

- **WatchConnectivityProvider.swift**  
  Manages data transfer over `WCSession`, sending and receiving full timer lists as well as action events (play, pause, reset) between iOS and watchOS.

- **Utilities**  
  Contains helper functions such as `formatTime(from:)` and an extension on `IntervalTimer` that generates a `configurationText` string for display in timer rows. This helps DRY up the code and maintain consistency across views.

### iOS Components

- **App_iOS.swift**  
  The entry point for the iOS app, which sets up the environment with shared objects like `TimerManager`, `WatchConnectivityProvider`, and `NavigationCoordinator`.

- **HomeView.swift**  
  Displays a list of timers (using `RowView`) or a placeholder when no timers exist. A “+” button in the toolbar navigates to `CreateView`.

- **RowView.swift**  
  Displays a single timer’s name (or, if empty, its configuration text) and a small indicator if the timer is running. Row height is fixed for consistency.

- **TimerView.swift**  
  Shows the countdown (with a circular progress bar), round indicators, and control buttons (Play/Pause, Reset). It also provides navigation to an edit screen.

- **CreateView.swift**  
  Presents a form (using `TimerForm`) for creating a new timer. It validates that the active duration is greater than 0:00 (showing an alert if not) and, upon saving, navigates directly to the newly created timer’s view.

- **EditView.swift**  
  Similar to CreateView but pre-populated with an existing timer’s configuration for editing. It also validates that the active duration is greater than 0:00.

### watchOS Components

- **App_watchOS.swift**  
  The entry point for the watchOS app, which injects shared objects into the view hierarchy and starts the WatchConnectivity session.

- **WatchHomeView.swift**  
  Lists timers or shows a placeholder if none exist. It uses a toolbar button for navigating to `WatchCreateView` and supports navigation to `WatchTimerView`.

- **RowView.swift**  
  A compact version of the timer row, optimized for the watch, showing the timer's name (or configuration text) and a running indicator.

- **WatchTimerView.swift**  
  Displays a large, monospaced countdown, round indicators, and control buttons (Play/Pause, Reset). It changes background colors based on the timer phase and provides haptic feedback for phase transitions.

- **WatchCreateView.swift**  
  Provides a swipable interface for creating a new timer directly on the watch. It allows configuration of round duration (active time), number of rounds (with an infinite option), rest time (which is hidden if rounds equal 1), and sound settings.

---

## 3. Data Flow and Synchronization

- **Creation/Editing:**  
  Timers are created or edited via CreateView/EditView on iOS (or WatchCreateView on watchOS). The changes are saved to `TimerManager` and persisted using App Groups.

- **Selection:**  
  When a timer is selected, its corresponding `TimerEngine` is obtained from `ActiveTimerEngines` and used to drive the countdown display in TimerView/WatchTimerView.

- **Action Events:**  
  Actions such as play, pause, and reset are immediately applied on the lead device by calling `applyAction(...)` on TimerEngine. The action, along with a snapshot of ephemeral state, is then sent via WatchConnectivityProvider to the paired device for synchronization.

- **Lead Device Pattern:**  
  The device that initiates an action becomes the “lead device” and updates its state immediately. The paired device applies the same action based on the received snapshot to stay in sync.

---

## 4. TimerEngine Details

- **Phases:**

  - **idle:** Timer is not started or has been reset.
  - **active:** Timer is counting down the active period.
  - **rest:** Timer is counting down the rest period.
  - **completed:** All rounds have been finished.

- **Key Methods:**
  - `play()`, `pause()`, `reset()`: Manage timer state.
  - `advancePeriod()`, `nextRound()`: Handle transitions between active and rest periods, and conclude rounds.
  - `applyAction(...)`: Synchronizes actions across devices by applying a given snapshot of timer state.

---

## 5. Creating and Editing Timers

- **Validation:**  
  Active duration must be greater than 0:00. CreateView and EditView enforce this by displaying an alert if the user attempts to save a timer with an active duration of 0:00.

- **TimerForm and DurationPicker:**  
  These shared components use wheel pickers for selecting minutes and seconds. The active duration picker disallows 0 seconds, while the rest time picker allows 0 seconds.

- **Navigation:**  
  Upon saving a timer, the app navigates directly to the timer’s view rather than simply dismissing the form.

---

## 6. User Interface Highlights

### iOS

- **HomeView & RowView:**  
  Timers are displayed in a list with a consistent row height. If a timer has no name, its configuration text (formatted using a shared utility) is left-aligned and centered vertically.

- **TimerView:**  
  Displays a circular progress indicator, a monospaced countdown, round indicators, and control buttons that adjust their appearance (e.g., play/pause vs. reset) based on the timer phase. Navigation toolbar buttons (back, gear) are styled for clarity.

- **CreateView/EditView:**  
  Forms for creating and editing timers, featuring input validation and immediate navigation to the newly created timer upon successful creation.

### watchOS

- **WatchHomeView & RowView:**  
  Display timers in a compact list optimized for the small screen, with a blue indicator for running timers.

- **WatchTimerView:**  
  Features a large, monospaced countdown, haptic feedback on phase transitions, and adaptive control buttons (showing only a reset button when the timer is completed).

  - **Volume Control:**  
    The WatchTimerView displays a music note button when audio is playing on the iPhone. Tapping this button reduces iPhone volume by 50%, and tapping again restores it. Implemented using MPVolumeView on iOS and WatchConnectivity for cross-device communication.

- **WatchCreateView:**  
  A swipable interface allowing users to configure a new timer. The view conditionally displays the rest time page only when the number of rounds is not 1, and provides clear navigation and validation.

---

## 7. Code Style and Conventions

- The project is entirely built with SwiftUI.
- There is a clear separation between persistent configuration (managed by TimerManager and IntervalTimer) and ephemeral state (managed by TimerEngine).
- Shared utility functions and extensions (e.g., formatting functions and configuration text generation) are centralized in a Utilities file.
- The code follows consistent naming conventions and uses descriptive commit messages for clarity.
- Previews are provided for rapid UI iteration.

---

## 8. Additional Notes

- **Audio Management:**  
  An AudioManager (using AVAudioPlayer) handles playback of bell sounds on iOS. It responds to notifications when timer phases change (e.g., starting a round or ending a round).

- **WatchConnectivity:**  
  A unified provider synchronizes timer configurations and action events between iOS and watchOS devices.

- **Platform-Specific Adjustments:**  
  iOS and watchOS have distinct UI components (NavigationStack vs. NavigationView, usage of WKInterfaceDevice for watch screen metrics) which are handled appropriately in their respective targets.

---

This README.md is intended to give new AI coding assistants or developers a comprehensive and context-rich overview of the TimeBurn project, enabling them to quickly understand the architecture, key components, data flow, and coding conventions in use.
