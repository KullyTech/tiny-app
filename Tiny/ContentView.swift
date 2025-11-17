import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            OrbLiveListenView()
                .tabItem {
                    Label("Orb", systemImage: "microbe.fill")
                }

            EnhancedLiveListenView()
                .tabItem {
                    Label("Debug", systemImage: "waveform.badge.microphone")
                }
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    ContentView()
}
