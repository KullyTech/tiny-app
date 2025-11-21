import SwiftUI
import SwiftData

struct OrbLiveListenView: View {
    @Environment(\.modelContext) private var modelContext
    
    @ObservedObject var heartbeatSoundManager: HeartbeatSoundManager
    // ⬇️ CHANGED: Boolean binding instead of Tab Int
    @Binding var showTimeline: Bool
    
    @State private var activeTutorial: TutorialContext?
    @StateObject private var audioPostProcessingManager = AudioPostProcessingManager()
    @StateObject private var physicsController = OrbPhysicsController()
    
    @State private var isListening = false
    @State private var animateOrb = false
    @State private var showShareSheet = false
    @State private var isPlaybackMode = false
    
    // Long press / Drag states
    @State private var isLongPressing = false
    @State private var longPressCountdown = 3
    @State private var longPressTimer: Timer?
    @State private var longPressScale: CGFloat = 1.0
    @State private var dragOffset: CGFloat = 0
    @State private var isDraggingToSave = false
    @State private var saveButtonScale: CGFloat = 1.0
    @State private var orbDragScale: CGFloat = 1.0
    @State private var canSaveCurrentRecording = false

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                backgroundView
                topControlsView
                statusTextView
                orbView(geometry: geometry)
                
                // Save/Library Button (Only visible when dragging)
                saveButton(geometry: geometry)
                
                // ⬇️ NEW: Temporary Floating Button to Open Timeline manually
                // (Since the dragging saveButton is hidden by default)
                if !isListening && !isDraggingToSave {
                    libraryOpenButton(geometry: geometry)
                }
                
                coachMarkView
                
                if let context = activeTutorial {
                    TutorialOverlay(activeTutorial: $activeTutorial, context: context)
                }
            }
            .sheet(isPresented: $showShareSheet) {
                if let lastRecordingURL = heartbeatSoundManager.lastRecording?.fileURL {
                    ShareSheet(activityItems: [lastRecordingURL])
                }
            }
            .preferredColorScheme(.dark)
            .onAppear(perform: showInitialTutorialIfNeeded)
            // Auto-play if we return from timeline with a selected recording
            .onChange(of: heartbeatSoundManager.lastRecording) { oldValue, newValue in
                if let recording = newValue, !showTimeline, !isListening {
                    setupPlayback(for: recording)
                }
            }
        }
    }
    
    private func setupPlayback(for recording: Recording) {
        isPlaybackMode = true
        animateOrb = true
        audioPostProcessingManager.stop()
        audioPostProcessingManager.loadAndPlay(fileURL: recording.fileURL)
    }
    
    // MARK: - UI Components
    
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
    
    private var topControlsView: some View {
        VStack {
            HStack {
                if isPlaybackMode {
                    Button(action: handleBackButton) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 50, height: 50)
                            .clipShape(Circle())
                    }
                    .glassEffect(.clear)
                    .transition(.opacity.animation(.easeInOut))
                }
                Spacer()
            }
            .padding()
            Spacer()
        }
    }
    
    // ⬇️ This is the button users tap to see the timeline
    private func libraryOpenButton(geometry: GeometryProxy) -> some View {
        VStack {
            Spacer()
            Button {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    showTimeline = true
                }
            } label: {
                Image(systemName: "book.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.white)
                    .frame(width: 77, height: 77)
                    .clipShape(Circle())
            }
            .glassEffect(.clear)
            .padding(.bottom, 50)
        }
    }
    
    // This is the hidden target for "Drag to Save"
    private func saveButton(geometry: GeometryProxy) -> some View {
        Image(systemName: "book.fill")
            .font(.system(size: 28))
            .foregroundColor(.white)
            .frame(width: 77, height: 77)
            .background(Circle().fill(Color.white.opacity(0.1))) // Added background for visibility debug
            .clipShape(Circle())
            .scaleEffect(saveButtonScale)
            .position(x: geometry.size.width / 2, y: geometry.size.height - 100)
            .opacity(isDraggingToSave ? min(dragOffset / 150.0, 1.0) : 0.0)
            .animation(.easeOut(duration: 0.2), value: isDraggingToSave)
            .animation(.easeOut(duration: 0.2), value: dragOffset)
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
                        Text(audioPostProcessingManager.isPlaying ? "Playing..." : (isDraggingToSave ? "Drag to save" : "Tap orb to play"))
                            .font(.title2)
                            .fontWeight(.medium)
                        
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
            .scaleEffect(orbScaleEffect * orbDragScale)
            .animation(.easeInOut(duration: 0.5), value: audioPostProcessingManager.isPlaying)
            .animation(.interpolatingSpring(mass: 2, stiffness: 100, damping: 20), value: animateOrb)
            .animation(.easeInOut(duration: 0.2), value: longPressScale)
            .animation(.easeInOut(duration: 0.2), value: orbDragScale)
            .offset(y: orbOffset(geometry: geometry) + dragOffset)
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

// MARK: - Logic Extensions
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
    
    // MARK: - Drag & Save Logic
    private func handleDragChange(value: SequenceGesture<LongPressGesture, DragGesture>.Value, geometry: GeometryProxy) {
        guard canSaveCurrentRecording else { return }
        switch value {
        case .second(true, let drag):
            isDraggingToSave = true
            let translation = max(0, drag?.translation.height ?? 0)
            dragOffset = translation
            let maxDragDistance = geometry.size.height / 2
            let dragProgress = min(translation / maxDragDistance, 1.0)
            withAnimation(.interactiveSpring(response: 0.3, dampingFraction: 0.7)) {
                orbDragScale = 1.0 - (dragProgress * 0.4)
                saveButtonScale = 1.0 + (dragProgress * 0.4)
            }
        default: break
        }
    }
    
    private func handleDragEnd(value: SequenceGesture<LongPressGesture, DragGesture>.Value, geometry: GeometryProxy) {
        guard canSaveCurrentRecording else { return }
        switch value {
        case .second(true, let drag):
            let translation = drag?.translation.height ?? 0
            if translation > geometry.size.height / 4 {
                handleSaveRecording()
            } else {
                resetDragState()
            }
        default: resetDragState()
        }
    }
    
    private func resetDragState() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            dragOffset = 0
            orbDragScale = 1.0
            saveButtonScale = 1.0
            isDraggingToSave = false
        }
    }
    
    private func handleSaveRecording() {
        guard canSaveCurrentRecording else { return }
        withAnimation(.interpolatingSpring(mass: 1, stiffness: 200, damping: 15)) {
            saveButtonScale = 1.6
            orbDragScale = 0.05
        }
        heartbeatSoundManager.saveRecording()
        canSaveCurrentRecording = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            resetDragState()
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                showTimeline = true // Navigate to timeline after save
            }
        }
    }
    
    private func handleBackButton() {
        audioPostProcessingManager.stop()
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            isPlaybackMode = false
            animateOrb = false
            isDraggingToSave = false
            dragOffset = 0
        }
    }
    
    private func handleDoubleTap() {
        guard !isLongPressing, !isListening, !isPlaybackMode else { return }
        withAnimation(.interpolatingSpring(mass: 2, stiffness: 100, damping: 20)) {
            animateOrb = true
            isListening = true
        }
        heartbeatSoundManager.start()
        heartbeatSoundManager.startRecording()
        showListeningTutorialIfNeeded()
    }
    
    private func handleSingleTap() {
        guard isPlaybackMode, !isListening, !isLongPressing, !isDraggingToSave else { return }
        guard let lastRecording = heartbeatSoundManager.lastRecording else { return }
        if audioPostProcessingManager.isPlaying {
            audioPostProcessingManager.pause()
        } else if audioPostProcessingManager.currentTime > 0 {
            audioPostProcessingManager.resume()
        } else {
            audioPostProcessingManager.loadAndPlay(fileURL: lastRecording.fileURL)
        }
    }
    
    // Tutorial and Long Press logic omitted for brevity (assume standard implementation)
    private func showInitialTutorialIfNeeded() { if !UserDefaults.standard.bool(forKey: "hasShownInitialTutorial") { activeTutorial = .initial } }
    private func showListeningTutorialIfNeeded() { if !UserDefaults.standard.bool(forKey: "hasShownListeningTutorial") { DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) { activeTutorial = .listening } } }
    private func handleLongPressChange(pressing: Bool) { if isListening { if pressing { startLongPressCountdown() } else { cancelLongPressCountdown() } } }
    private func handleLongPressComplete() { cancelLongPressCountdown(); withAnimation(.interpolatingSpring(mass: 2, stiffness: 100, damping: 20)) { isListening = false; animateOrb = false; isPlaybackMode = true; canSaveCurrentRecording = true }; heartbeatSoundManager.stopRecording(); heartbeatSoundManager.stop() }
    private func startLongPressCountdown() { isLongPressing = true; longPressCountdown = 3; longPressScale = 1.0; longPressTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in if longPressCountdown > 0 { withAnimation { longPressCountdown -= 1 } } } }
    private func cancelLongPressCountdown() { isLongPressing = false; longPressCountdown = 3; longPressScale = 1.0; longPressTimer?.invalidate() }
    
    struct GestureModifier: ViewModifier {
        let isPlaybackMode: Bool; let geometry: GeometryProxy
        let handleDragChange: (SequenceGesture<LongPressGesture, DragGesture>.Value, GeometryProxy) -> Void
        let handleDragEnd: (SequenceGesture<LongPressGesture, DragGesture>.Value, GeometryProxy) -> Void
        let handleLongPressChange: (Bool) -> Void; let handleLongPressComplete: () -> Void
        func body(content: Content) -> some View { if isPlaybackMode { content.gesture(LongPressGesture(minimumDuration: 0.2).sequenced(before: DragGesture()).onChanged { handleDragChange($0, geometry) }.onEnded { handleDragEnd($0, geometry) }) } else { content.gesture(LongPressGesture(minimumDuration: 3.0).onChanged { handleLongPressChange($0) }.onEnded { _ in handleLongPressComplete() }) } }
    }
}

#Preview {
    OrbLiveListenView(
        heartbeatSoundManager: HeartbeatSoundManager(),
        showTimeline: .constant(false)
    )
    .modelContainer(for: SavedHeartbeat.self, inMemory: true)
}
