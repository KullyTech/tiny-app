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

    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var authService: AuthenticationService
    @EnvironmentObject var syncManager: HeartbeatSyncManager

    var body: some View {
        Group {
            if hasShownOnboarding {
                // After onboarding → always go to RootView (SignIn → Onboarding → Main)
                RootView()
                    .environmentObject(heartbeatSoundManager)
                    .environmentObject(authService)
                    .environmentObject(syncManager)
            } else {
                // Onboarding only
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

struct RootView: View {
    @EnvironmentObject var authService: AuthenticationService

    var body: some View {
        Group {
            if !authService.isAuthenticated {
                // Step 1: Landing screen with Sign in with Apple
                SignInView()
            } else if authService.currentUser?.role == nil {
                // Step 2-4: Onboarding flow (role selection, name input, room code)
                OnboardingCoordinator()
            } else {
                // Step 5: Main app - go to HeartbeatMainView
                HeartbeatMainView()
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: SavedHeartbeat.self, inMemory: true)
}
