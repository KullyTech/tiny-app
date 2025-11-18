import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationView {
            OrbLiveListenView()
                .tabItem {
                    Label("Orb", systemImage: "microbe.fill")
                }
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    ContentView()
}
