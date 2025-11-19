import SwiftUI

struct ContentView: View {
    @AppStorage("hasShownOnboarding") var hasShownOnboarding: Bool = false

    var body: some View {
        Group {
            if hasShownOnboarding {
                OrbLiveListenView()
            } else {
                OnBoardingView(hasShownOnboarding: $hasShownOnboarding)
            }
        }
        .ignoresSafeArea()
        .preferredColorScheme(.dark)
    }
}

#Preview {
    ContentView()
}
