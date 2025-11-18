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
                backgroundView
                topButtonsView
                statusTextView
                orbView(geometry: geometry)
                coachMarkView
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

// MARK: - View Components
extension OrbLiveListenView {
    
    private var backgroundView: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            Image("background")
                .resizable()
                .scaleEffect(isListening ? 1.2 : 1.0)
                .animation(.easeInOut(duration: 1.2), value: isListening)
                .ignoresSafeArea()
        }
    }
    
    private var topButtonsView: some View {
        VStack {
            HStack {
                if isPlaybackMode {
                    Button(action: handleBackButton, label: {
                        Image(systemName: "chevron.left")
                            .font(.title)
                            .foregroundColor(.white)
                    })
                    .transition(.opacity.animation(.easeInOut))
                }
                
                Spacer()
                
                Button(action: { showShareSheet = true }, label: {
                    Image(systemName: "square.and.arrow.up")
                        .font(.title)
                        .foregroundColor(.white)
                })
                .disabled(heartbeatSoundManager.lastRecording == nil)
            }
            .padding()
            Spacer()
        }
    }
    
    private var statusTextView: some View {
        VStack {
            Group {
                if isListening && isLongPressing {
                    CountdownTextView(countdown: longPressCountdown, isVisible: isLongPressing)
                } else if isListening {
                    Text("Listening...")
                        .font(.title)
                        .fontWeight(.bold)
                } else if isPlaybackMode {
                    VStack(spacing: 8) {
                        Text(audioPostProcessingManager.isPlaying ? "Playing..." : "Tap orb to play")
                            .font(.title2)
                            .fontWeight(.medium)
                        
                        if audioPostProcessingManager.duration > 0 {
                            Text("\(Int(audioPostProcessingManager.currentTime))s / \(Int(audioPostProcessingManager.duration))s")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                }
            }
            .foregroundColor(.white)
            .padding(.top, 50)
            .transition(.opacity.animation(.easeInOut))
            
            Spacer()
        }
    }
    
    private func orbView(geometry: GeometryProxy) -> some View {
        VStack {
            ZStack {
                AnimatedOrbView()
                bokehEffectView
            }
            .frame(width: 200, height: 200)
            .opacity(isPlaybackMode ? (audioPostProcessingManager.isPlaying ? 1.0 : 0.4) : 1.0)
            .scaleEffect(orbScaleEffect)
            .animation(.easeInOut(duration: 0.5), value: audioPostProcessingManager.isPlaying)
            .animation(.interpolatingSpring(mass: 2, stiffness: 100, damping: 20), value: animateOrb)
            .animation(.easeInOut(duration: 0.2), value: longPressScale)
            .offset(y: orbOffset(geometry: geometry))
            .onTapGesture(count: 2, perform: handleDoubleTap)
            .onTapGesture(count: 1, perform: handleSingleTap)
            .onLongPressGesture(minimumDuration: 3.0, maximumDistance: 50, 
                               perform: handleLongPressComplete,
                               onPressingChanged: handleLongPressChange)
        }
        .frame(width: geometry.size.width, height: geometry.size.height)
    }
    
    private var bokehEffectView: some View {
        Group {
            if isListening {
                BokehEffectView(amplitude: $heartbeatSoundManager.blinkAmplitude)
            } else if isPlaybackMode {
                BokehEffectView(amplitude: .constant(audioPostProcessingManager.isPlaying ? 0.8 : 0.2))
                    .opacity(audioPostProcessingManager.isPlaying ? 1.0 : 0.5)
                    .animation(.easeInOut(duration: 0.5), value: audioPostProcessingManager.isPlaying)
            }
        }
        .scaleEffect(x: physicsController.scaleX, y: physicsController.scaleY)
        .offset(x: physicsController.offsetX, y: physicsController.offsetY)
        .rotationEffect(.degrees(physicsController.rotation))
        .onAppear { physicsController.startPhysics() }
        .frame(width: 18, height: 18)
    }
    
    private var coachMarkView: some View {
        Group {
            if !isListening && !isPlaybackMode {
                GeometryReader { proxy in
                    CoachMarkView()
                        .position(x: proxy.size.width / 2, y: proxy.size.height / 2 + 250)
                }
                .transition(.opacity)
            }
        }
    }
}

// MARK: - Computed Properties
extension OrbLiveListenView {
    
    private var orbScaleEffect: CGFloat {
        if isListening {
            return isLongPressing ? (animateOrb ? 1.6 : 1.1) * longPressScale : (animateOrb ? 1.5 : 1.0)
        } else if isPlaybackMode {
            return audioPostProcessingManager.isPlaying ? 1.3 : 0.8
        }
        return 1.0
    }
    
    private func orbOffset(geometry: GeometryProxy) -> CGFloat {
        isListening ? geometry.size.height / 2 - 150 : 0
    }
}

// MARK: - Actions
extension OrbLiveListenView {
    
    private func handleDoubleTap() {
        guard !isLongPressing, !isListening, !isPlaybackMode else { return }
        
        withAnimation(.interpolatingSpring(mass: 2, stiffness: 100, damping: 20)) {
            animateOrb = true
            isListening = true
        }
        
        heartbeatSoundManager.start()
        heartbeatSoundManager.startRecording()
    }
    
    private func handleSingleTap() {
        guard isPlaybackMode, !isListening, !isLongPressing else { return }
        guard let lastRecording = heartbeatSoundManager.lastRecording else { return }
        
        if audioPostProcessingManager.isPlaying {
            audioPostProcessingManager.pause()
        } else if audioPostProcessingManager.currentTime > 0 && audioPostProcessingManager.duration > 0 {
            audioPostProcessingManager.resume()
        } else {
            audioPostProcessingManager.loadAndPlay(fileURL: lastRecording.fileURL)
        }
    }
    
    private func handleBackButton() {
        audioPostProcessingManager.stop()
        withAnimation(.interpolatingSpring(mass: 2, stiffness: 100, damping: 20)) {
            isPlaybackMode = false
            animateOrb = false
        }
    }
    
    private func handleLongPressChange(pressing: Bool) {
        guard isListening else { return }
        if pressing {
            startLongPressCountdown()
        } else {
            cancelLongPressCountdown()
        }
    }
    
    private func startLongPressCountdown() {
        isLongPressing = true
        longPressCountdown = 3
        longPressScale = 1.0
        
        var tickCount = 0
        let totalTicks = 30
        let scaleIncrement = 0.15 / 30
        
        longPressTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            tickCount += 1
            
            if tickCount % 10 == 0 {
                withAnimation(.easeInOut(duration: 0.2)) { longPressCountdown -= 1 }
            }
            
            withAnimation(.linear(duration: 0.1)) { longPressScale += scaleIncrement }
            
            if tickCount >= totalTicks { timer.invalidate() }
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
        cancelLongPressCountdown()
        
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

