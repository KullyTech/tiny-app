//
//  ContentView.swift
//  tiny
//
//  Created by Destu Cikal Ramdani on 25/10/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @AppStorage("hasShownOnboarding") var hasShownOnboarding: Bool = false
    @StateObject private var heartbeatSoundManager = HeartbeatSoundManager()
    @State private var showTimeline = false
    
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        Group {
            if hasShownOnboarding {
                HeartbeatMainView()
            } else {
                OnBoardingView(hasShownOnboarding: $hasShownOnboarding)
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
    ContentView()
        .modelContainer(for: SavedHeartbeat.self, inMemory: true)
}
