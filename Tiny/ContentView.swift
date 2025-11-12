//
//  ContentView.swift
//  tiny
//
//  Created by Destu Cikal Ramdani on 25/10/25.
//

import SwiftUI

// MARK: - Updated ContentView with Enhanced Heartbeat Monitoring
struct ContentView: View {
    var body: some View {
        TabView {
            EnhancedLiveListenView()
                .tabItem {
                    Label("Listen", systemImage: "waveform")
                }

            HeartbeatAnalysisTab()
                .tabItem {
                    Label("Analysis", systemImage: "chart.line.uptrend.xyaxis")
                }

            RippleEffectView()
                .tabItem {
                    Label("Ripple", systemImage: "water.waves")
                }
        }
    }
}
#Preview {
    ContentView()
}
