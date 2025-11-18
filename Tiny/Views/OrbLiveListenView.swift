import SwiftUI

struct OrbLiveListenView: View {
    @StateObject var heartbeatSoundManager = HeartbeatSoundManager()
    @StateObject private var physicsController = OrbPhysicsController()
    @State private var isListening = false
    @State private var animateOrb = false
    @State private var showShareSheet = false

    // State for long press logic
    @State private var isLongPressing = false
    @State private var countdownValue: Int?
    @State private var countdownTimer: Timer?

    // Constants
    private let longPressDuration: Double = 3.0
    private let orbDefaultScale: CGFloat = 1.0
    private let orbHoldScale: CGFloat = 1.3
    private let orbListeningScale: CGFloat = 1
    private let animationSpring: Animation = .interpolatingSpring(mass: 2, stiffness: 60, damping: 20)

    // Timer helper functions
    private func startCountdown() {
        countdownValue = Int(longPressDuration)
        stopCountdown()

        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            DispatchQueue.main.async {
                if let current = countdownValue, current > 1 {
                    self.countdownValue = current - 1
                } else {
                    timer.invalidate()
                    self.countdownTimer = nil
                }
            }
        }
    }

    private func stopCountdown() {
        countdownTimer?.invalidate()
        countdownTimer = nil
        countdownValue = nil
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                Color.black.edgesIgnoringSafeArea(.all)

                Image("background")
                    .resizable()
                    .scaleEffect(isListening ? 1.2 : 1.0)
                    .animation(.easeInOut(duration: 1.2), value: isListening)
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

                /// Listening & Countdown Text at Top
                VStack {
                    if isListening {
                        if let countdown = countdownValue {
                            Text("Stopping in \(countdown)...")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.red)
                                .padding(.top, 50)
                                .transition(.opacity.combined(with: .scale))
                        } else {
                            Text("Listening...")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(.top, 50)
                                .transition(.opacity.combined(with: .scale))
                        }
                    }
                    Spacer()
                }
                .animation(.easeInOut(duration: 0.3), value: isListening)
                .animation(.easeInOut(duration: 0.2), value: countdownValue)

                // Orb View
                VStack {
                    ZStack {
                        AnimatedOrbView()
                        if isListening {
                            BokehEffectView(amplitude: $heartbeatSoundManager.blinkAmplitude)
                                .scaleEffect(x: physicsController.scaleX, y: physicsController.scaleY)
                                .offset(x: physicsController.offsetX, y: physicsController.offsetY)
                                .rotationEffect(.degrees(physicsController.rotation))
                                .onAppear {
                                    physicsController.startPhysics()
                                }
                                .frame(width: 18, height: 18)
                        }
                    }
                    .frame(width: 200, height: 200)
                    .scaleEffect(isLongPressing ? orbHoldScale : (animateOrb ? orbListeningScale : orbDefaultScale))
                    .offset(y: animateOrb ? geometry.size.height / 2 - 150 : 0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.6, blendDuration: 0), value: animateOrb)
                    .animation(.spring(), value: isLongPressing)

                    // --- FIXED Gesture Implementation with LongPressGesture ---
                    .gesture(
                        LongPressGesture(minimumDuration: longPressDuration, maximumDistance: 50)
                            .onChanged { isPressing in
                                // onChanged fires when user starts pressing (isPressing = true)
                                // and can fire when gesture is cancelled (isPressing = false)
                                if isListening && isPressing && !isLongPressing {
                                    withAnimation(.spring()) {
                                        isLongPressing = true
                                    }
                                    startCountdown()
                                }
                            }
                            .onEnded { _ in
                                // Successful 3-second hold: Full Stop
                                if isListening {
                                    stopCountdown()

                                    withAnimation(animationSpring) {
                                        animateOrb = false
                                        isListening = false
                                        isLongPressing = false
                                    }
                                    heartbeatSoundManager.stopRecording()
                                    heartbeatSoundManager.stop()
                                }
                            }
                        .simultaneously(with:
                            DragGesture(minimumDistance: 0)
                                .onEnded { _ in
                                    // This catches when user releases before long press completes
                                    if isListening && isLongPressing && countdownValue != nil {
                                        withAnimation(.spring()) {
                                            isLongPressing = false
                                        }
                                        stopCountdown()
                                    }
                                }
                        )
                        .simultaneously(with: TapGesture(count: 2).onEnded { _ in
                            if !isListening {
                                withAnimation(animationSpring) {
                                    animateOrb = true
                                    isListening = true
                                }
                                heartbeatSoundManager.start()
                                heartbeatSoundManager.startRecording()
                            }
                        })
                    )
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
            .onDisappear {
                stopCountdown()
            }
        }
    }
}

#Preview {
    OrbLiveListenView()
}
