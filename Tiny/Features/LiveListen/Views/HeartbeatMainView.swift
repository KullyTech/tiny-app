//
//  HeartbeatMainView.swift
//  Tiny
//
//  Created by Tm Revanza Narendra Pradipta on 20/11/25.
//

import SwiftUI
import SwiftData

struct HeartbeatMainView: View {
    @StateObject private var viewModel = HeartbeatMainViewModel()
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        ZStack {
            if viewModel.showTimeline {
                PregnancyTimelineView(
                    heartbeatSoundManager: viewModel.heartbeatSoundManager,
                    showTimeline: $viewModel.showTimeline,
                    onSelectRecording: viewModel.handleRecordingSelection
                )
                .transition(.opacity)
            } else {
                OrbLiveListenView(
                    heartbeatSoundManager: viewModel.heartbeatSoundManager,
                    showTimeline: $viewModel.showTimeline
                )
                .transition(.opacity)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            viewModel.setupManager(modelContext: modelContext)
        }
    }
}

#Preview {
    HeartbeatMainView()
        .modelContainer(for: SavedHeartbeat.self, inMemory: true)
}
