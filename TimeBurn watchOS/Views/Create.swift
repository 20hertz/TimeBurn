//
//  WatchCreateView.swift
//  TimeBurn
//
//  Created by Stéphane on 2025-02-10.
//

import SwiftUI
import WatchKit

struct WatchCreateView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var timerManager: TimerManager
    @EnvironmentObject var connectivityProvider: WatchConnectivityProvider

    // Store durations as total seconds
    @State private var activeDuration: Int = 60
    @State private var restDuration: Int = 30
    @State private var totalRounds: Int = 0
    @State private var enableSound: Bool = true

    @State private var activeIndex: Int = 0  // Tracks the focused item

    var sections: [(String, AnyView)] {
        [
            ("Active", AnyView(TimePickerView(totalSeconds: $activeDuration))),
            ("Rest", AnyView(TimePickerView(totalSeconds: $restDuration))),
            ("Rounds", AnyView(
                HStack {
                    Text("Rounds")
                    Spacer()
                    Picker("", selection: $totalRounds) {
                        Text("∞").tag(0)
                        ForEach(1..<21, id: \.self) { round in
                            Text("\(round)").tag(round)
                        }
                    }
                    .pickerStyle(WheelPickerStyle())
                    .frame(maxWidth: 60)
                }
            )),
            ("", AnyView(Toggle("Sound", isOn: $enableSound)))
        ]
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: -10) {
                    ForEach(Array(sections.enumerated()), id: \.offset) { index, section in
                        SnappingSection(header: section.0) {
                            section.1
                        }
                        .id(index)  // Set ID for snapping
                    }
                }
                .padding(.vertical, 50)
            }
            .gesture(
                DragGesture()
                    .onEnded { value in
                        withAnimation(.spring()) {
                            if value.translation.height < -30, activeIndex < sections.count - 1 {
                                activeIndex += 1
                            } else if value.translation.height > 30, activeIndex > 0 {
                                activeIndex -= 1
                            }
                            proxy.scrollTo(activeIndex, anchor: .center)  // Ensure snapping to center
                        }
                    }
            )
        }
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    saveTimer()
                }
            }
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }
        }
    }

    private func saveTimer() {
        timerManager.addTimer(
            name: "",
            activeDuration: activeDuration,
            restDuration: restDuration,
            totalRounds: totalRounds,
            enableSound: enableSound
        )
        connectivityProvider.sendTimers(timerManager.timers)
        dismiss()
    }
}

struct SnappingSection<Content: View>: View {
    let header: String?
    let content: Content

    init(header: String? = nil, @ViewBuilder content: () -> Content) {
        self.header = header
        self.content = content()
    }

    var body: some View {
        GeometryReader { proxy in
            let minY = proxy.frame(in: .global).midY
            let screenHeight = WKInterfaceDevice.current().screenBounds.height

            let scale = max(0.9, 1 - abs(minY - screenHeight / 2) / (screenHeight / 2.5))
            let opacity = max(0.4, 1 - abs(minY - screenHeight / 2) / (screenHeight / 2.5))

            VStack {
                if let header = header {
                    Text(header)
                        .font(.headline)
                        .opacity(opacity)
                }
                content
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 15).fill(Color.blue.opacity(0.2)))
                    .scaleEffect(scale)
                    .opacity(opacity)
                    .animation(.easeInOut(duration: 0.3), value: scale)
            }
            .padding()
        }
        .frame(height: 150)  // Controls height of each section
    }
}


#Preview {
    NavigationStack {
        WatchCreateView()
            .environmentObject(TimerManager.shared)
            .environmentObject(WatchConnectivityProvider.shared)
    }
}

struct TimePickerView: View {
    @Binding var totalSeconds: Int

    private var minutes: Int {
        totalSeconds / 60
    }
    
    private var seconds: Int {
        totalSeconds % 60
    }
    
    var body: some View {
        GeometryReader { geometry in
            let totalWidth = max(geometry.size.width, 150)  // ✅ Ensure a minimum width
            let dividerWidth: CGFloat = 8
            let columnWidth = max((totalWidth - dividerWidth) / 2, 50) // ✅ Ensure a minimum column width
            
            HStack(spacing: 0) {
                // Minutes column
                VStack(spacing: 0) {
                    Picker("", selection: Binding(
                        get: { minutes },
                        set: { newMinutes in
                            totalSeconds = newMinutes * 60 + seconds
                        }
                    )) {
                        ForEach(0..<11, id: \.self) { minute in
                            Text("\(minute)").tag(minute)
                        }
                    }
                    .pickerStyle(WheelPickerStyle())
                    .frame(width: columnWidth, height: 60)  // ✅ No more invalid width
                    .clipped()
                }
                
                Divider()
                    .frame(width: dividerWidth, height: 60)
                    .padding(.horizontal, 4)
                
                // Seconds column
                VStack(spacing: 0) {
                    Picker("", selection: Binding(
                        get: { seconds },
                        set: { newSeconds in
                            totalSeconds = minutes * 60 + newSeconds
                        }
                    )) {
                        ForEach(0..<60, id: \.self) { second in
                            Text(String(format: "%02d", second)).tag(second)
                        }
                    }
                    .pickerStyle(WheelPickerStyle())
                    .frame(width: columnWidth, height: 60)  // ✅ Ensure valid width
                    .clipped()
                }
            }
            .frame(width: totalWidth)
        }
        .frame(height: 60)
    }
}
