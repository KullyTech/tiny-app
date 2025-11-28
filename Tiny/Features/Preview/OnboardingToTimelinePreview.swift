//
//  OnboardingToTimelinePreview.swift
//  Tiny
//
//  Created by Tm Revanza Narendra Pradipta on 28/11/25.
//

import SwiftUI

struct OnboardingToTimelinePreview: View {
    @State private var showWeekInput = true
    @State private var selectedWeek: Int?
    @State private var showTimeline = false
    
    var body: some View {
        ZStack {
            if showWeekInput {
                // Week Input Screen
                WeekInputView(onComplete: { week in
                    selectedWeek = week
                    
                    // Reset animation flag to see it every time
                    UserDefaults.standard.set(false, forKey: "hasSeenTimelineAnimation")
                    
                    // Transition to timeline
                    withAnimation(.easeInOut(duration: 0.5)) {
                        showWeekInput = false
                        showTimeline = true
                    }
                })
                .transition(.opacity)
            }
            
            if showTimeline, let week = selectedWeek {
                // Timeline with animation
                PregnancyTimelineView(
                    heartbeatSoundManager: createMockManager(),
                    showTimeline: .constant(true),
                    onSelectRecording: { recording in
                        print("Selected: \(recording.fileURL.lastPathComponent)")
                    },
                    isMother: true,
                    inputWeek: week
                )
                .transition(.opacity)
            }
        }
        .preferredColorScheme(.dark)
    }
    
    private func createMockManager() -> HeartbeatSoundManager {
        let manager = HeartbeatSoundManager()
        // Empty recordings to show placeholder dots
        return manager
    }
}

#Preview {
    OnboardingToTimelinePreview()
}
