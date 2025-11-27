//
//  tinyApp.swift
//  tiny
//
//  Created by Destu Cikal Ramdani on 25/10/25.
//

import SwiftUI
import SwiftData
import FirebaseCore

@main
struct TinyApp: App {
    @StateObject var heartbeatSoundManager = HeartbeatSoundManager()
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
            ContentView()
                .environmentObject(heartbeatSoundManager)
        }
        .modelContainer(sharedModelContainer)
    }
}
