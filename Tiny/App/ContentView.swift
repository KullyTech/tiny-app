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

            // DEBUG: Force sign out to clear any cached sessions
                if !hasShownOnboarding {
                    // If showing onboarding, ensure we start fresh
                    Task {
                        try? await authService.signOut()
                        print("🧹 Cleared any existing auth session before onboarding")
                    }
                }

            // DEBUG: Print auth state
            print("📊 ContentView - hasShownOnboarding: \(hasShownOnboarding)")
            print("📊 ContentView - isAuthenticated: \(authService.isAuthenticated)")
            print("📊 ContentView - currentUser: \(String(describing: authService.currentUser))")
            print("📊 ContentView - isRestoringSession: \(authService.isRestoringSession)")
        }
    }
}

struct RootView: View {
    @EnvironmentObject var authService: AuthenticationService

    var body: some View {
        Group {
            if authService.isRestoringSession {
                ZStack {
                    Color.black.ignoresSafeArea()
                    ProgressView()
                        .tint(.white)
                }
                .onAppear {
                    print("🔄 RootView: Showing loading (isRestoringSession)")
                }
            } else if authService.currentUser == nil {
                // Step 1: Landing screen with Sign in with Apple
                SignInView()
                    .onAppear {
                        print("🔐 RootView: Showing SignInView (currentUser is nil)")
                    }
            } else if authService.currentUser?.role == nil {
                // Step 2-4: Onboarding flow (role selection, name input, room code)
                OnboardingCoordinator()
                    .onAppear {
                        print("👤 RootView: Showing OnboardingCoordinator (user exists, no role)")
                    }
            } else {
                // Step 5: Main app - go to HeartbeatMainView
                HeartbeatMainView()
                    .onAppear {
                        print("🏠 RootView: Showing HeartbeatMainView (fully onboarded)")
                    }
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: SavedHeartbeat.self, inMemory: true)
}
