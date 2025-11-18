import SwiftUI

struct OrbLiveListenView: View {
    @StateObject var heartbeatSoundManager = HeartbeatSoundManager()
    @StateObject private var audioPostProcessingManager = AudioPostProcessingManager()
    @StateObject private var physicsController = OrbPhysicsController()
    @State private var isListening = false
    @State private var animateOrb = false
    @State private var showShareSheet = false
    @State private var isPlaybackMode = false
    
    // Long press countdown states
    @State private var isLongPressing = false
    @State private var longPressCountdown = 3
    @State private var longPressTimer: Timer?
    @State private var longPressScale: CGFloat = 1.0

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)

                Image("background")
                    .resizable()
                    .scaleEffect(isListening ? 1.2 : 1.0)
                    .animation(.easeInOut(duration: 1.2), value: isListening)
                    .ignoresSafeArea()

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

                if isListening && !isLongPressing {
                    VStack {
                        Text("Listening...")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.top, 50)
                        Spacer()
                    }
                    .transition(.opacity.animation(.easeInOut))
                } else if isPlaybackMode {
                    VStack {
                        Text(audioPostProcessingManager.isPlaying ? "Playing..." : "Tap orb to play")
                            .font(.title2)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding(.top, 50)
                        
                        if audioPostProcessingManager.duration > 0 {
                            VStack {
                                Text("\(Int(audioPostProcessingManager.currentTime))s / \(Int(audioPostProcessingManager.duration))s")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            .padding(.top, 10)
                        }
                        
                        Spacer()
                    }
                    .transition(.opacity.animation(.easeInOut))
                }

                // Countdown text overlay
                if isListening && isLongPressing {
                    VStack {
                        CountdownTextView(countdown: longPressCountdown, isVisible: isLongPressing)
                            .padding(.top, 50)
                        Spacer()
                    }
                    .transition(.opacity.animation(.easeInOut))
                }

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
                        } else if isPlaybackMode {
                            BokehEffectView(amplitude: .constant(audioPostProcessingManager.isPlaying ? 0.8 : 0.2))
                                .scaleEffect(x: physicsController.scaleX, y: physicsController.scaleY)
                                .offset(x: physicsController.offsetX, y: physicsController.offsetY)
                                .rotationEffect(.degrees(physicsController.rotation))
                                .onAppear {
                                    physicsController.startPhysics()
                                }
                                .opacity(audioPostProcessingManager.isPlaying ? 1.0 : 0.5)
                                .animation(.easeInOut(duration: 0.5), value: audioPostProcessingManager.isPlaying)
                                .frame(width: 18, height: 18)
                        }
                    }
                    .frame(width: 200, height: 200)
                    .opacity(isPlaybackMode ? (audioPostProcessingManager.isPlaying ? 1.0 : 0.4) : 1.0)
                    .scaleEffect(
                        isListening ? 
                            (isLongPressing ? (animateOrb ? 1.6 : 1.1) * longPressScale : (animateOrb ? 1.5 : 1.0)) :
                            isPlaybackMode ? 
                                (audioPostProcessingManager.isPlaying ? 1.15 : 0.8) : 
                                1.0
                    )
                    .animation(.easeInOut(duration: 0.5), value: audioPostProcessingManager.isPlaying)
                    .animation(.interpolatingSpring(mass: 2, stiffness: 100, damping: 20), value: animateOrb)
                    .animation(.easeInOut(duration: 0.2), value: longPressScale)
                    .offset(y: getOrbOffset(geometry: geometry))
                    .onTapGesture(count: 2) {
                        if !isLongPressing {
                            handleDoubleTap()
                        }
                    }
                    .onTapGesture(count: 1) {
                        if !isLongPressing {
                            handleSingleTap()
                        }
                    }
                    .onLongPressGesture(
                        minimumDuration: 3.0,
                        maximumDistance: 50,
                        perform: {
                            // Long press completed - stop listening
                            handleLongPressComplete()
                        },
                        onPressingChanged: { pressing in
                            handleLongPressChange(pressing: pressing)
                        }
                    )
                }
                .frame(width: geometry.size.width, height: geometry.size.height)

                if !isListening && !isPlaybackMode {
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
    
    private func getOrbOffset(geometry: GeometryProxy) -> CGFloat {
        if isListening {
            return geometry.size.height / 2 - 150
        } else if isPlaybackMode {
            return 0
        } else {
            return 0
        }
    }
    
    private func handleDoubleTap() {
        // Remove the listening session stop logic from double tap
        if isPlaybackMode {
            audioPostProcessingManager.stop()
            
            withAnimation(.interpolatingSpring(mass: 2, stiffness: 100, damping: 20)) {
                isPlaybackMode = false
                isListening = true
                animateOrb = true
            }
            
            heartbeatSoundManager.start()
            heartbeatSoundManager.startRecording()
            
        } else if !isListening && !isPlaybackMode {
            // Only allow starting listening session from idle state
            withAnimation(.interpolatingSpring(mass: 2, stiffness: 100, damping: 20)) {
                animateOrb = true
                isListening = true
            }
            
            heartbeatSoundManager.start()
            heartbeatSoundManager.startRecording()
        }
    }
    
    private func handleSingleTap() {
        if isPlaybackMode && !isListening {
            guard let lastRecording = heartbeatSoundManager.lastRecording else {
                print("No recording available to play")
                return
            }
            
            if audioPostProcessingManager.isPlaying {
                audioPostProcessingManager.pause()
            } else {
                if audioPostProcessingManager.currentTime > 0 && audioPostProcessingManager.duration > 0 {
                    // Resume from paused state
                    audioPostProcessingManager.resume()
                } else {
                    // Load and play fresh
                    audioPostProcessingManager.loadAndPlay(fileURL: lastRecording.fileURL)
                }
            }
        }
    }
    
    // MARK: - Long Press Handling
    
    private func handleLongPressChange(pressing: Bool) {
        if isListening {
            if pressing {
                startLongPressCountdown()
            } else {
                cancelLongPressCountdown()
            }
        }
    }
    
    private func startLongPressCountdown() {
        isLongPressing = true
        longPressCountdown = 3
        longPressScale = 1.0
        
        var tickCount = 0
        let totalTicks = 30 // 3 seconds * 10 ticks per second
        let scaleIncrement = 0.15 / 30 // Total growth of 0.15 over 30 ticks
        
        longPressTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            tickCount += 1
            
            // Update countdown every 10 ticks (every second)
            if tickCount % 10 == 0 {
                withAnimation(.easeInOut(duration: 0.2)) {
                    longPressCountdown -= 1
                }
            }
            
            // Smoothly grow the orb on every tick
            withAnimation(.linear(duration: 0.1)) {
                longPressScale += scaleIncrement
            }
            
            // Stop when we reach 3 seconds (30 ticks)
            if tickCount >= totalTicks {
                timer.invalidate()
            }
        }
    }
    
    private func cancelLongPressCountdown() {
        isLongPressing = false
        longPressCountdown = 3
        longPressScale = 1.0
        longPressTimer?.invalidate()
        longPressTimer = nil
    }
    
    private func handleLongPressComplete() {
        // Long press completed - stop listening session
        cancelLongPressCountdown()
        stopListeningSession()
    }
    
    private func stopListeningSession() {
        withAnimation(.interpolatingSpring(mass: 2, stiffness: 100, damping: 20)) {
            isListening = false
            animateOrb = false
            isPlaybackMode = true
        }
        
        heartbeatSoundManager.stopRecording()
        heartbeatSoundManager.stop()
    }
}

#Preview {
    OrbLiveListenView()
}
