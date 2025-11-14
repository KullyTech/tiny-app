import SwiftUI

struct CoachMarkView: View {
    @State private var iconState = 0  // 0 = idle, 1 = tap1, 2 = tap2

    var body: some View {
        VStack(spacing: 10) {

            // --- FIX: Use a ZStack for a stable frame ---
            // This prevents the layout from shifting when the icon changes,
            // as the ZStack's size is calculated to fit both icons.
            ZStack {
                Image(systemName: "hand.point.up.fill")
                    // Show this icon only when state is 0
                    .opacity(iconState == 0 ? 1 : 0)

                Image(systemName: "hand.tap.fill")
                    // Show this icon when state is 1 or 2
                    .opacity(iconState == 1 || iconState == 2 ? 1 : 0)
            }
            .font(.system(size: 90))
            .foregroundColor(.white.opacity(0.8))
            // Apply the animation to the opacity changes
            .animation(.easeInOut(duration: 0.15), value: iconState)

            Text("Tap Twice to Start")
                .font(.headline)
                .foregroundColor(.white.opacity(0.7))
        }
        .task {
            // Start the animation loop when the view appears
            await runDoubleTapLoop()
        }
    }

    // MARK: - Double Tap Animation Loop
    func runDoubleTapLoop() async {
        // Loop indefinitely
        while true {
            // --- Tap 1 ---
            iconState = 1
            try? await Task.sleep(for: .milliseconds(200))

            // --- Lift Up ---
            iconState = 0
            try? await Task.sleep(for: .milliseconds(150))

            // --- Tap 2 ---
            iconState = 2
            try? await Task.sleep(for: .milliseconds(200))

            // --- Rest ---
            iconState = 0
            try? await Task.sleep(for: .milliseconds(800))
        }
    }
}

#Preview {
    CoachMarkView()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
}
