import SwiftUI
internal import Combine

struct BokehEffectView: View {
    @Binding var amplitude: Float

    private var pulseOpacity: Double {
        let clampedAmplitude = min(max(Double(amplitude), 0.0), 1.0)
        return 0.2 + (clampedAmplitude * 0.8) // Make it more visible
    }
    
    private var pulseScale: CGFloat {
        return 1.0 + CGFloat(amplitude) * 0.2
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.yellow.opacity(0.8)) // Keeping this one
                .frame(width: 30)
                .opacity(pulseOpacity)
                .scaleEffect(pulseScale)
        }
        .blur(radius: 2)
        .animation(.easeInOut(duration: 0.15), value: amplitude)
    }
}

#Preview {
    // Example of how to use the view with a dummy binding
    struct PreviewWrapper: View {
        @State private var dummyAmplitude: Float = 0.5
        let timer = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()

        var body: some View {
            ZStack {
                Color.black
                BokehEffectView(amplitude: $dummyAmplitude)
                    .onReceive(timer) { _ in
                        withAnimation {
                            dummyAmplitude = Float.random(in: 0.1...0.8)
                        }
                    }
            }
        }
    }
    return PreviewWrapper()
}
