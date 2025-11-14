//
//  ContentView.swift
//  tiny
//
//  Created by Destu Cikal Ramdani on 25/10/25.
//

import SwiftUI
import Orb

// MARK: - Updated ContentView with Enhanced Heartbeat Monitoring
struct ContentView: View {
    var body: some View {
        AnimatedOrbView()
            .tabItem {
                Label("Orb", systemImage: "apple.image.playground.fill")
            }
    }
}

#Preview {
    ContentView()
}
