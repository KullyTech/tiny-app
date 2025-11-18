import SwiftUI

struct OrbLiveListenView: View {
    @StateObject var heartbeatSoundManager = HeartbeatSoundManager()
    @State private var isListening = false
    @State private var animateOrb = false
    @State private var showShareSheet = false

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                Color.black.edgesIgnoringSafeArea(.all)

                Image("background")
                    .resizable()
                    .scaleEffect(isListening ? 1.4 : 1.0)   // zoom in
                    .animation(.easeInOut(duration: 1.6), value: isListening)
                    .ignoresSafeArea()

                // Share Button
                VStack {
                    HStack {
                        Spacer()
                        Button(action: {
                            self.showShareSheet = true
                        }, label: {
                            Image(systemName: "square.and.arrow.up")
                                .font(.title)
                                .foregroundColor(.white)
                        })
                        .disabled(heartbeatSoundManager.lastRecording == nil)
                        .padding()
                    }
                    Spacer()
                }

                // Listening Text at Top
                if isListening {
                    VStack {
                        Text("Listening...")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.top, 50) // Top padding
                        Spacer()
                    }
                    .transition(.opacity.animation(.easeInOut))
                }

                // Orb View
                VStack {
                    ZStack {
                        AnimatedOrbView()
                        if isListening {
                            BokehEffectView(amplitude: $heartbeatSoundManager.blinkAmplitude)
                        }
                    }
                    .frame(width: 200, height: 200)
                    .scaleEffect(animateOrb ? 1.5 : 1)
                    .offset(y: animateOrb ? geometry.size.height / 2 - 150 : 0)
                    .onTapGesture(count: 2) {
                        withAnimation(.interpolatingSpring(mass: 2, stiffness: 100, damping: 20)) {
                            animateOrb.toggle()
                            isListening.toggle()
                            if isListening {
                                heartbeatSoundManager.start()
                                heartbeatSoundManager.startRecording()
                            } else {
                                heartbeatSoundManager.stopRecording()
                                heartbeatSoundManager.stop()
                            }
                        }
                    }
                }
                .frame(width: geometry.size.width, height: geometry.size.height)

                // Coach Mark
                if !isListening {
                    CoachMarkView()
                        .position(x: geometry.size.width / 2, y: geometry.size.height / 2 + 250)
                        .transition(.opacity)
                }
            }
            .sheet(isPresented: $showShareSheet) {
                if let lastRecordingURL = heartbeatSoundManager.lastRecording?.fileURL {
                    ShareSheet(activityItems: [lastRecordingURL])
                }
            }
            .preferredColorScheme(.dark)
        }
    }
}

#Preview {
    OrbLiveListenView()
}
