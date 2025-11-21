//
//  tinyApp.swift
//  tiny
//
//  Created by Destu Cikal Ramdani on 25/10/25.
//

import SwiftUI
import SwiftData

@main
struct TinyApp: App {
    @StateObject var heartbeatSoundManager = HeartbeatSoundManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(heartbeatSoundManager)
        }
        .modelContainer(for: SavedHeartbeat.self)
    }
}
