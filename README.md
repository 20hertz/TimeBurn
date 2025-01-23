# Gym Time

Gym Time is a cross-platform interval timer application designed for iOS and watchOS. It allows users to create timers with custom active and rest durations, round counts, and optional infinite runs. The app synchronizes between iOS and watchOS, ensuring that when a user starts, pauses, or resets a timer on one device, the other device stays in sync.

Table of Contents
	1.	Overview
	2.	Project Structure
2.1 Shared Codebase
2.2 iOS Components
2.3 watchOS Components
	3.	Data Flow
	4.	Synchronization Logic
	5.	TimerEngine Details
	6.	Creating and Editing Timers
	7.	User Interface Highlights
	8.	How to Contribute
	9.	License

1. Overview

Gym Time is an interval timer app that:
	•	Persists user-defined configurations (name, active/rest durations, round counts) using an App Group, making these available to both iOS and watchOS.
	•	Maintains ephemeral state (remaining time, current round, active vs. rest phase) in memory.
	•	Syncs timer actions (play, pause, reset) in near real-time across devices using WatchConnectivity.

The architecture follows these key principles:
	1.	Separation of Persistent and Ephemeral State:
	•	TimerManager stores permanent configurations (name, durations, round counts).
	•	TimerEngine tracks countdown details (remainingTime, currentRound, phase) in memory only.
	2.	Event-Based Synchronization:
	•	Actions (play/pause/reset) are transmitted with timestamps and a snapshot of state.
	•	Each device reconciles delays by adjusting its local engine.
	3.	Self-Healing:
	•	Any updates to timer configurations propagate to running engines, ensuring that UI and countdown logic stay current.

2. Project Structure

├─ Shared
│   ├─ IntervalTimer.swift
│   ├─ TimerAction.swift
│   ├─ TimerManager.swift
│   ├─ TimerEngine.swift
│   ├─ ActiveTimerEngines.swift
│   └─ WatchConnectivityProvider.swift
├─ iOS
│   ├─ TimerApp_iOS.swift
│   ├─ HomeView.swift
│   ├─ RowView.swift
│   ├─ TimerView.swift
│   ├─ EditView.swift
│   ├─ CreateView.swift
│   └─ ...
└─ watchOS
    ├─ TimerApp_watchOS.swift
    ├─ WatchHomeView.swift
    ├─ RowView.swift
    ├─ WatchTimerView.swift
    └─ ...

2.1 Shared Codebase
	•	IntervalTimer: A simple model storing permanent configurations (activeDuration, restDuration, totalRounds, etc.).
	•	TimerAction: Enum with .play, .pause, and .reset actions for synchronization.
	•	TimerManager: A singleton that persists user-created timers to an App Group, also used for CRUD operations.
	•	TimerEngine: Manages ephemeral countdown state, including the current round, remaining time, and transitions between active and rest.
	•	ActiveTimerEngines: Stores one TimerEngine instance per timer (by its UUID). Ensures that if multiple parts of the app request an engine for the same timer, they get the same object.
	•	WatchConnectivityProvider: Oversees data transfer between iOS and watchOS, handling updates to timers and user actions (play/pause/reset).

2.2 iOS Components
	•	TimerApp_iOS: Entry point of the iOS app. Injects shared objects (TimerManager and WatchConnectivityProvider) into the environment.
	•	HomeView: Lists saved timers. If none exist, shows a placeholder message instructing the user to create one. A top-right “+” button navigates to CreateView.
	•	RowView: A row representing a single timer in the list. Tapping navigates to TimerView. If the timer is running, shows a small blue dot on the right.
	•	TimerView: Displays a specific timer’s countdown, round indicators, and control buttons. A HStack places the reset button (if not idle) to the left, and the play/pause button to the right (or centered if idle).
	•	EditView: Allows in-place editing of an existing timer’s name, durations, and round count.
	•	CreateView: Collects new timer data (including durations via wheel pickers) and saves the resulting timer to TimerManager.

2.3 watchOS Components
	•	TimerApp_watchOS: Entry point for watchOS, similarly injecting TimerManager and WatchConnectivityProvider.
	•	WatchHomeView: Lists saved timers or shows a placeholder if none exist. Tapping a timer row opens WatchTimerView.
	•	RowView: Displays timer info in a watch-friendly layout, with a small circle on the right if the timer is running.
	•	WatchTimerView: A simpler UI for controlling the countdown. It shows the remaining time at the top, round indicators below, and play/pause and reset buttons at the bottom. The background color changes to green or red to reflect the active or rest phase.

3. Data Flow
	1.	Creation/Editing:
	•	iOS CreateView or EditView modifies TimerManager, which persists changes via an App Group.
	•	WatchConnectivityProvider can send updated timer lists to watchOS.
	2.	Selection:
	•	User taps on a timer row, which obtains a TimerEngine from ActiveTimerEngines.shared.
	•	iOS transitions to TimerView, watchOS transitions to WatchTimerView.
	3.	Countdown & Actions:
	•	Start/Stop/Reset actions are triggered. The local device updates TimerEngine and sends an action event to WatchConnectivityProvider.
	•	The counterpart device receives the event, adjusts its local TimerEngine with offsets and snaps to the new state.

4. Synchronization Logic
	•	Event Payload:

{
  "actionEvent": true,
  "timerID": "<uuid-string>",
  "action": "<play|pause|reset>",
  "timestamp": <Double: seconds since 1970>,
  "remainingTime": <Int>,
  "isRestPeriod": <Bool>,
  "currentRound": <Int>
}


	•	applyAction Method:
	•	The receiving device sets its own remainingTime, phase, currentRound based on the payload.
	•	Adjusts for network delay by comparing timestamp to the local clock.
	•	Calls the local play(), pause(), or reset() method to finalize state transitions.

5. TimerEngine Details
	•	Phases:
	•	.idle: Timer not started or just reset.
	•	.active: Currently counting down the active duration.
	•	.rest: Currently counting down the rest duration.
	•	.completed: All rounds finished.
	•	Key Operations:
	•	play():
	•	If .idle, initialize round = 1, load activeDuration, set phase = .active.
	•	Else if paused, recalculate period start time for accurate resumed countdown.
	•	Start a DispatchSourceTimer that updates remainingTime every 0.2 seconds.
	•	pause():
	•	Stop the dispatch timer and finalize remainingTime based on the absolute elapsed time.
	•	reset():
	•	Return to .idle, killing any active dispatch timer, setting currentRound=0 and remainingTime=activeDuration.
	•	advancePeriod():
	•	Moves from .active to .rest (or to next round if restDuration == 0).
	•	Moves from .rest to next round if more remain, else .completed.

6. Creating and Editing Timers

Creation (iOS):
	1.	Navigate to CreateView.
	2.	User inputs:
	•	Timer name (text field).
	•	Active/Rest durations (via wheel pickers in 5-second increments).
	•	Round count (Stepper, with 0 meaning infinite).
	3.	Save:
	•	Calls timerManager.addTimer(...).
	•	Immediately sends updated timers list to watchOS.

Editing (iOS):
	1.	From TimerView, tap the gear button to open EditView.
	2.	User modifies name/durations/round count (text fields, number pads).
	3.	Save:
	•	Calls timerManager.updateTimer(...).
	•	Sync changes to watchOS.

7. User Interface Highlights

iOS
	•	HomeView:
	•	Displays a list of timers or a placeholder message if empty.
	•	A plus button in the top-right opens CreateView.
	•	CreateView & EditView:
	•	Use DurationPicker for setting times in minute/5-second increments.
	•	Stepper for setting total rounds (0 = infinite).
	•	Automatic watch sync on save.
	•	TimerView:
	•	Shows a circular progress bar (75% of screen width).
	•	“REST” label at the top with toggled opacity.
	•	Round indicators (filled or empty circles).
	•	Reset button on the left if not idle.
	•	Play/Pause button on the right or centered if idle.
	•	Solid accent color backgrounds, white icons, large sizes, and neat spacing.

watchOS
	•	WatchHomeView:
	•	Either shows a placeholder (no timers) or a list.
	•	Selecting a timer opens WatchTimerView.
	•	WatchTimerView:
	•	Remaining time at the top, monospaced.
	•	Minimal round indicators below.
	•	The background changes color (green for active, red for rest).
	•	play/pause and reset buttons at the bottom.

8. How to Contribute
	1.	Fork or Branch this repository to add your changes.
	2.	Implement new features or bug fixes:
	•	Ensure that any ephemeral state remains in memory (TimerEngine), and only configuration changes are persisted in TimerManager.
	•	For watch/iOS communication, follow the established pattern of WatchConnectivityProvider event handling.
	3.	Test thoroughly:
	•	Check the UI on multiple devices and simulators.
	•	Validate watchOS interactions with iOS in real-time.
	4.	Submit a Pull Request or coordinate merges to keep the main branch consistent.

Code Style Guidelines
	•	Prefer SwiftUI patterns over legacy UIKit bridging where possible.
	•	Maintain functional boundaries: configurations in TimerManager, ephemeral states in TimerEngine, event bridging in WatchConnectivityProvider.
	•	Write descriptive commit messages.

9. License

This project is distributed under the MIT License. Contributions are welcome—please ensure they comply with the project’s guidelines and overall architecture.

Contact & Support
For questions, enhancements, or bug reports, please open an issue or reach out to the maintainers. We appreciate community feedback and contributions to make Gym Time the best cross-platform interval timer possible!
