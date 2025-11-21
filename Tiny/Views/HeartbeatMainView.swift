//
//  HeartbeatMainView.swift
//  Tiny
//
//  Created by Tm Revanza Narendra Pradipta on 20/11/25.
//

import SwiftUI
import SwiftData

struct HeartbeatMainView: View {
    // 1. Hoist Manager Here
    @StateObject private var heartbeatSoundManager = HeartbeatSoundManager()
    // 2. Simple Boolean State for Navigation
    @State private var showTimeline = false
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        ZStack {
            if showTimeline {
                // Show Timeline
                PregnancyTimelineView(
                    heartbeatSoundManager: heartbeatSoundManager,
                    showTimeline: $showTimeline, // Pass binding to close
                    onSelectRecording: { recording in
                        // When recording selected:
                        // 1. Update manager
                        heartbeatSoundManager.lastRecording = recording
                        // 2. Close timeline to go back to Orb
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                            showTimeline = false
                        }
                    }
                )
                .transition(.opacity)
            } else {
                // Show Orb Recorder
                OrbLiveListenView(
                    heartbeatSoundManager: heartbeatSoundManager,
                    showTimeline: $showTimeline // Pass binding to open
                )
                .transition(.opacity)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            heartbeatSoundManager.modelContext = modelContext
            heartbeatSoundManager.loadFromSwiftData()
        }
    }
}

#Preview {
    HeartbeatMainView()
        .modelContainer(for: SavedHeartbeat.self, inMemory: true)
}
