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
                    .preferredColorScheme(.dark)
            } else {
                //                ContentView()
                //                    .environmentObject(heartbeatSoundManager)
                RootView()
                    .environmentObject(heartbeatSoundManager)
                    .environmentObject(authService)
                    .environmentObject(syncManager)
            }
        }
        .modelContainer(sharedModelContainer)
    }
}

struct RootView: View {
    @EnvironmentObject var authService: AuthenticationService
    
    // Check if onboarding is complete
    private var isOnboardingComplete: Bool {
        guard let user = authService.currentUser, let role = user.role else {
            return false
        }
        
        // For mothers: need role + pregnancyWeek
        if role == .mother {
            return user.pregnancyWeeks != nil || UserDefaults.standard.integer(forKey: "pregnancyWeek") > 0
        }
        
        // For fathers: need role + roomCode
        return user.roomCode != nil
    }
    
    var body: some View {
        Group {
            if !authService.isAuthenticated {
                // Step 1: Landing screen with Sign in with Apple
                SignInView()
            } else if !isOnboardingComplete {
                // Step 2-4: Onboarding flow (role, name, week/roomCode)
                OnboardingCoordinator()
            } else {
                // Step 5: Main app - Timeline is now the main page
                HeartbeatMainView()
            }
        }
    }
}
