import SwiftUI

struct OrbLiveListenView: View {
    @State private var activeTutorial: TutorialContext?
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
    
    // Long press to drag states
    @State private var dragOffset: CGFloat = 0
    @State private var isDraggingToSave = false
    @State private var saveButtonScale: CGFloat = 1.0
    @State private var orbDragScale: CGFloat = 1.0
    
    // NEW:
    @State private var showTimeline = false
    @State private var canSaveCurrentRecording = false

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                backgroundView
                topButtonsView
                statusTextView
                orbView(geometry: geometry)
                saveButtonView(geometry: geometry)
                coachMarkView
                
                if let context = activeTutorial {
                    TutorialOverlay(activeTutorial: $activeTutorial, context: context)
                }
                    
                    // ⬇️ Overlay: PregnancyTimelineView with fade
                if showTimeline {
                    PregnancyTimelineView(
                        heartbeatSoundManager: heartbeatSoundManager,
                        onSelectRecording: { recording in
                            handleSelectRecordingFromTimeline(recording)
                        },
                        onClose: {
                            withAnimation(.easeInOut(duration: 0.4)) {
                                showTimeline = false
                            }
                        }
                    )
                    .transition(.opacity)
                    .ignoresSafeArea()
                    .zIndex(2)
                }
            }
            .animation(.easeInOut(duration: 0.4), value: showTimeline)
            .sheet(isPresented: $showShareSheet) {
                if let lastRecordingURL = heartbeatSoundManager.lastRecording?.fileURL {
                    ShareSheet(activityItems: [lastRecordingURL])
                }
            }
            .preferredColorScheme(.dark)
            .onAppear(perform: showInitialTutorialIfNeeded)
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
                        // CHANGED: Added drag instruction
                        Text(audioPostProcessingManager.isPlaying ? "Playing..." : (isDraggingToSave ? "Drag to save" : "Tap orb to play"))
                            .font(.title2)
                            .fontWeight(.medium)
                        
                        // CHANGED: Hide duration when dragging
                        if audioPostProcessingManager.duration > 0 && !isDraggingToSave {
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
            .scaleEffect(orbScaleEffect * orbDragScale) // CHANGED: Added orbDragScale
            .animation(.easeInOut(duration: 0.5), value: audioPostProcessingManager.isPlaying)
            .animation(.interpolatingSpring(mass: 2, stiffness: 100, damping: 20), value: animateOrb)
            .animation(.easeInOut(duration: 0.2), value: longPressScale)
            .animation(.easeInOut(duration: 0.2), value: orbDragScale) // CHANGED: Added animation for orbDragScale
            .offset(y: orbOffset(geometry: geometry) + dragOffset) // CHANGED: Added dragOffset
            .onTapGesture(count: 2, perform: handleDoubleTap)
            .onTapGesture(count: 1, perform: handleSingleTap)
            .modifier(GestureModifier(
                isPlaybackMode: isPlaybackMode,
                geometry: geometry,
                handleDragChange: handleDragChange,
                handleDragEnd: handleDragEnd,
                handleLongPressChange: handleLongPressChange,
                handleLongPressComplete: handleLongPressComplete
            ))
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
    
    // CHANGED: Updated save button to fade in based on drag progress
    private func saveButtonView(geometry: GeometryProxy) -> some View {
        Button {} label: {
            Image(systemName: "book.fill")
                .font(.system(size: 28))
                .foregroundColor(.white)
                .frame(width: 77, height: 77)
                .clipShape(Circle())
        }
        .glassEffect(.clear)
        .scaleEffect(saveButtonScale)
        .animation(.easeInOut(duration: 0.2), value: saveButtonScale)
        .position(x: geometry.size.width / 2, y: geometry.size.height - 100)
        .opacity(isDraggingToSave ? min(dragOffset / 100, 1.0) : 0.0)
        .animation(.easeInOut(duration: 0.2), value: isDraggingToSave)
        .animation(.easeInOut(duration: 0.2), value: dragOffset)
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

// MARK: - Drag Gesture Actions (NEW SECTION)
extension OrbLiveListenView {
    
    private func handleDragChange(value: SequenceGesture<LongPressGesture, DragGesture>.Value, geometry: GeometryProxy) {
        guard canSaveCurrentRecording else { return } // NEW
        switch value {
        case .second(true, let drag):
            isDraggingToSave = true
            
            // Only allow downward drag
            let translation = max(0, drag?.translation.height ?? 0)
            dragOffset = translation
            
            // Calculate how far down the orb is dragged
            let maxDragDistance = geometry.size.height / 2
            let dragProgress = min(translation / maxDragDistance, 1.0)
            
            // Shrink orb as it's dragged down (from 1.0 to 0.5)
            withAnimation(.easeInOut(duration: 0.2)) {
                orbDragScale = 1.0 - (dragProgress * 0.5)
                
                // Grow save button as orb gets closer (from 1.0 to 1.5)
                saveButtonScale = 1.0 + (dragProgress * 0.5)
            }
            
        default:
            break
        }
    }
    
    private func handleDragEnd(value: SequenceGesture<LongPressGesture, DragGesture>.Value, geometry: GeometryProxy) {
        guard canSaveCurrentRecording else { return } // NEW
        switch value {
        case .second(true, let drag):
            let translation = drag?.translation.height ?? 0
            let saveThreshold = geometry.size.height / 3
            
            if translation > saveThreshold {
                // User dragged far enough - save the recording
                handleSaveRecording()
            } else {
                // User didn't drag far enough or dragged back up - cancel
                resetDragState()
            }
            
        default:
            resetDragState()
        }
    }
    
    private func resetDragState() {
        withAnimation(.easeInOut(duration: 0.3)) {
            dragOffset = 0
            orbDragScale = 1.0
            saveButtonScale = 1.0
            isDraggingToSave = false
        }
    }
    
    private func handleSaveRecording() {
        guard canSaveCurrentRecording else { return }
        withAnimation(.interpolatingSpring(mass: 1, stiffness: 200, damping: 15)) {
            saveButtonScale = 1.8
            orbDragScale = 0.3
        }
        
        // Call your save function here
        heartbeatSoundManager.saveRecording()
        canSaveCurrentRecording = false
        
        // After the little save animation, reset + fade into timeline
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            resetDragState()
            withAnimation(.easeInOut(duration: 0.5)) {
                showTimeline = true
            }
        }
    }
}

// MARK: - Recording Actions
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
        // CHANGED: Added guard for isDraggingToSave
        guard isPlaybackMode, !isListening, !isLongPressing, !isDraggingToSave else { return }
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
            canSaveCurrentRecording = true
        }
        
        heartbeatSoundManager.stopRecording()
        heartbeatSoundManager.stop()
        
        showListeningTutorialIfNeeded()
    }
    
    // MARK: - Tutorial Logic
    private func showInitialTutorialIfNeeded() {
        if !UserDefaults.standard.bool(forKey: "hasShownInitialTutorial") {
            activeTutorial = .initial
        }
    }
    
    private func showListeningTutorialIfNeeded() {
        if !UserDefaults.standard.bool(forKey: "hasShownListeningTutorial") {
            // Use a delay to allow the listening UI to appear first
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
                activeTutorial = .listening
            }
        }
    }
    
    private func handleSelectRecordingFromTimeline(_ recording: Recording) {
        // Update lastRecording so the playback logic can reuse it
        heartbeatSoundManager.lastRecording = recording
        
        // Make sure we're not listening
        isListening = false
        
        // Close the timeline with a fade and go into playback mode
        withAnimation(.easeInOut(duration: 0.4)) {
            showTimeline = false
            isPlaybackMode = true
            canSaveCurrentRecording = false
            animateOrb = true
        }
        
        // Start playback using your existing post-processing manager
        audioPostProcessingManager.stop()
        audioPostProcessingManager.loadAndPlay(fileURL: recording.fileURL)
    }
    
    // MARK: - Gesture Modifier (NO CHANGES)
    struct GestureModifier: ViewModifier {
        let isPlaybackMode: Bool
        let geometry: GeometryProxy
        let handleDragChange: (SequenceGesture<LongPressGesture, DragGesture>.Value, GeometryProxy) -> Void
        let handleDragEnd: (SequenceGesture<LongPressGesture, DragGesture>.Value, GeometryProxy) -> Void
        let handleLongPressChange: (Bool) -> Void
        let handleLongPressComplete: () -> Void
        
        func body(content: Content) -> some View {
            if isPlaybackMode {
                content
                    .gesture(
                        LongPressGesture(minimumDuration: 0.5)
                            .sequenced(before: DragGesture())
                            .onChanged { value in
                                handleDragChange(value, geometry)
                            }
                            .onEnded { value in
                                handleDragEnd(value, geometry)
                            }
                    )
            } else {
                content
                    .gesture(
                        LongPressGesture(minimumDuration: 3.0)
                            .onChanged { pressing in
                                handleLongPressChange(pressing)
                            }
                            .onEnded { _ in
                                handleLongPressComplete()
                            }
                    )
            }
        }
    }
}

#Preview {
    OrbLiveListenView()
}
