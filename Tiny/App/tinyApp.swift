//
//  tinyApp.swift
//  tiny
//
//  Created by Destu Cikal Ramdani on 25/10/25.
//

import SwiftUI
import SwiftData
import FirebaseCore

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        FirebaseApp.configure()
        return true
    }
}

@main
struct TinyApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    @StateObject var heartbeatSoundManager = HeartbeatSoundManager()
    @StateObject private var themeManager = ThemeManager()
    @StateObject var authService = AuthenticationService()
    @StateObject var syncManager = HeartbeatSyncManager()
    @State private var isShowingSplashScreen: Bool = true // Add state to control splash screen
    
    // Define the container configuration
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            SavedHeartbeat.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    var body: some Scene {
        WindowGroup {
            if isShowingSplashScreen {
                SplashScreenView(isShowingSplashScreen: $isShowingSplashScreen)
                    .environmentObject(themeManager)
                    .preferredColorScheme(.dark)
            } else {
                //                ContentView()
                //                    .environmentObject(heartbeatSoundManager)
                RootView()
                    .environmentObject(heartbeatSoundManager)
                    .environmentObject(authService)
                    .environmentObject(syncManager)
                    .environmentObject(themeManager)
            }
        }
        .modelContainer(sharedModelContainer)
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
