import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        HeartbeatMainView()
            .preferredColorScheme(.dark)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: SavedHeartbeat.self, inMemory: true)
}
