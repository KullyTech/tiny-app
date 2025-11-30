import SwiftUI
import SwiftData

// swiftlint:disable type_body_length
struct OrbLiveListenView: View {
    @State private var showThemeCustomization = false
    @EnvironmentObject var themeManager: ThemeManager
    
    @State private var showSuccessAlert = false
    @State private var successMessage = (title: "", subtitle: "")
    @Environment(\.modelContext) private var modelContext
    
    @ObservedObject var heartbeatSoundManager: HeartbeatSoundManager
    @Binding var showTimeline: Bool
    
    @StateObject private var viewModel = OrbLiveListenViewModel()
    @StateObject private var tutorialViewModel = TutorialViewModel()
    
    @GestureState private var isPressing = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                backgroundView
                    .animation(.easeOut(duration: 0.2), value: viewModel.isDraggingToSave)
                    .animation(.easeOut(duration: 0.2), value: viewModel.isDraggingToDelete)
                
                topControlsView
                    .opacity(viewModel.isDraggingToSave || viewModel.isDraggingToDelete ? 0.0 : 1.0)
                    .animation(.easeOut(duration: 0.2), value: viewModel.isDraggingToSave)
                    .animation(.easeOut(duration: 0.2), value: viewModel.isDraggingToDelete)
                
                statusTextView
                    .opacity(viewModel.isDraggingToSave || viewModel.isDraggingToDelete ? 0.0 : 1.0)
                    .animation(.easeOut(duration: 0.2), value: viewModel.isDraggingToSave)
                    .animation(.easeOut(duration: 0.2), value: viewModel.isDraggingToDelete)
                
                orbView(geometry: geometry)
                
                // Save/Library Button (Only visible when dragging)
                saveButton(geometry: geometry)
                
                // Delete Button (Only visible when dragging up)
                deleteButton(geometry: geometry)
                
                // Floating Button to Open Timeline manually
                if !viewModel.isListening && !viewModel.isDraggingToSave && !viewModel.isDraggingToDelete {
                    libraryOpenButton(geometry: geometry)
                        .opacity(viewModel.isDraggingToSave || viewModel.isDraggingToDelete ? 0.0 : 1.0)
                        .animation(.easeOut(duration: 0.2), value: viewModel.isDraggingToSave)
                        .animation(.easeOut(duration: 0.2), value: viewModel.isDraggingToDelete)
                }
                
                coachMarkView
                
                // Success Alert with dark overlay
                if showSuccessAlert {
                    ZStack {
                        // Dark overlay
                        Color.black.opacity(0.6)
                            .ignoresSafeArea()
                        
                        // Alert on top
                        VStack {
                            HStack(spacing: 16) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 28))
                                    .foregroundColor(.white)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(successMessage.title)
                                        .font(.body)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.white)
                                    
                                    Text(successMessage.subtitle)
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.8))
                                }
                                
                                Spacer()
                            }
                            .padding(20)
                            .glassEffect(.clear)
                            .padding(.horizontal, 20)
                            .padding(.top, 60)
                            
                            Spacer()
                        }
                    }
                    .transition(.opacity)
                    .zIndex(300)
                }
                
                if let context = tutorialViewModel.activeTutorial {
                    TutorialOverlay(viewModel: tutorialViewModel, context: context)
                }
            }
            .sheet(isPresented: $viewModel.showShareSheet) {
                if let lastRecordingURL = heartbeatSoundManager.lastRecording?.fileURL {
                    ShareSheet(activityItems: [lastRecordingURL])
                }
            }
            .sheet(isPresented: $showThemeCustomization) {
                            ThemeCustomizationView()
                                .environmentObject(themeManager)
                        }
            .preferredColorScheme(.dark)
            .onAppear {
                tutorialViewModel.showInitialTutorialIfNeeded()
                viewModel.handleOnAppear(recording: heartbeatSoundManager.lastRecording)
            }
        }
    }
    
    private var backgroundView: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            Image(themeManager.selectedBackground.imageName)
                .resizable()
                .scaleEffect(viewModel.isListening ? 1.2 : 1.0)
                .animation(.easeInOut(duration: 1.2), value: viewModel.isListening)
                .ignoresSafeArea()
        }
    }
    
    private var topControlsView: some View {
        GeometryReader { _ in
            VStack {
                HStack {
                    if viewModel.isPlaybackMode {
                        Button(action: viewModel.handleBackButton, label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(width: 50, height: 50)
                                .clipShape(Circle())
                        })
                        .glassEffect(.clear)
                        .padding(.bottom, 50)
                        .transition(.opacity.animation(.easeInOut))
                    }
                    Spacer()
                }
                .padding()
                Spacer()
            }
        }
    }
    
    private func libraryOpenButton(geometry: GeometryProxy) -> some View {
        VStack {
            HStack {
                Spacer()
                
                if viewModel.isPlaybackMode {
                    Button {
                        viewModel.showShareSheet = true
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                            .font(.body)
                            .foregroundColor(.white)
                            .frame(width: 50, height: 50)
                            .clipShape(Circle())
                    }
                    .glassEffect(.clear)
                    .padding(.bottom, 50)
                    .transition(.opacity.animation(.easeInOut))
                }
                
                Button {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        showTimeline = true
                    }
                } label: {
                    Image(systemName: "book.fill")
                        .font(.body)
                        .foregroundColor(.white)
                        .frame(width: 50, height: 50)
                        .clipShape(Circle())
                }
                .glassEffect(.clear)
                .padding(.bottom, 50)
            }
            .padding()
            Spacer()
        }
    }
    
    private func saveButton(geometry: GeometryProxy) -> some View {
        Image(systemName: "book.fill")
            .font(.system(size: 28))
            .foregroundColor(.white)
            .frame(width: 77, height: 77)
            .clipShape(Circle())
            .glassEffect(.clear)
            .scaleEffect(viewModel.saveButtonScale)
            .position(x: geometry.size.width / 2, y: geometry.size.height - 46)
            .opacity(viewModel.isDraggingToSave ? min(viewModel.dragOffset / 150.0, 1.0) : 0.0)
            .animation(.easeOut(duration: 0.2), value: viewModel.isDraggingToSave)
            .animation(.easeOut(duration: 0.2), value: viewModel.dragOffset)
    }
    
    private func deleteButton(geometry: GeometryProxy) -> some View {
        Image(systemName: "trash.fill")
            .font(.system(size: 28))
            .foregroundColor(.red)
            .frame(width: 77, height: 77)
            .clipShape(Circle())
            .glassEffect(.clear)
            .scaleEffect(viewModel.deleteButtonScale)
            .position(x: geometry.size.width / 2, y: 50)
            .opacity(viewModel.isDraggingToDelete ? min(abs(viewModel.dragOffset) / 150.0, 1.0) : 0.0)
            .animation(.easeOut(duration: 0.2), value: viewModel.isDraggingToDelete)
            .animation(.easeOut(duration: 0.2), value: viewModel.dragOffset)
    }
    
    private var statusTextView: some View {
        VStack {
            Group {
                if viewModel.isListening && viewModel.isLongPressing {
                    CountdownTextView(countdown: viewModel.longPressCountdown, isVisible: viewModel.isLongPressing)
                } else if viewModel.isListening {
                    VStack(spacing: 8) {
                        Text("Listening...")
                            .font(.title)
                            .fontWeight(.bold)

                        Text("Hold sphere to stop session")
                            .font(.subheadline)
                            .foregroundStyle(.placeholder)
                    }
                } else if viewModel.isPlaybackMode {
                    VStack(spacing: 8) {
                        Text(viewModel.audioPostProcessingManager.isPlaying ? "Playing..." :
                                (viewModel.isDraggingToSave ? "Drag to save" : "Tap orb to play"))
                        .font(.title2)
                        .fontWeight(.medium)
                        
                        if viewModel.audioPostProcessingManager.duration > 0 && !viewModel.isDraggingToSave {
                            Text("\(Int(viewModel.currentTime))s / \(Int(viewModel.audioPostProcessingManager.duration))s")
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
            .opacity(viewModel.isPlaybackMode ? (viewModel.audioPostProcessingManager.isPlaying ? 1.0 : 0.4) : 1.0)
            .scaleEffect(viewModel.orbScaleEffect * viewModel.orbDragScale)
            .animation(.easeInOut(duration: 0.5), value: viewModel.audioPostProcessingManager.isPlaying)
            .animation(.interpolatingSpring(mass: 2, stiffness: 100, damping: 20), value: viewModel.animateOrb)
            .animation(.easeInOut(duration: 0.2), value: viewModel.longPressScale)
            .animation(.easeInOut(duration: 0.2), value: viewModel.orbDragScale)
            .offset(y: viewModel.orbOffset(geometry: geometry) + viewModel.dragOffset)
            .animation(.spring(response: 1.0, dampingFraction: 0.8), value: viewModel.isListening)
            .onTapGesture(count: 2) {
                viewModel.handleDoubleTap {
                    heartbeatSoundManager.start()
                    heartbeatSoundManager.startRecording()
                }
            }
            .onTapGesture(count: 1) {
                viewModel.handleSingleTap(lastRecording: heartbeatSoundManager.lastRecording)
            }
            .modifier(GestureModifier(
                isPlaybackMode: viewModel.isPlaybackMode,
                geometry: geometry,
                handleDragChange: { value in
                    viewModel.handleDragChange(value: value, geometry: geometry)
                },
                handleDragEnd: { value in
                    viewModel.handleDragEnd(value: value, geometry: geometry, onSave: {
                        // Show alert first
                        successMessage = (title: "Saved!", subtitle: "Your recording is saved on timeline.")
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                            showSuccessAlert = true
                        }
                        // Then save after alert is visible
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            heartbeatSoundManager.saveRecording()
                            // Navigate after another delay
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                    showSuccessAlert = false
                                    showTimeline = true
                                }
                            }
                        }
                    }, onDelete: {
                        // Show alert first
                        successMessage = (title: "Deleted.", subtitle: "Your recording is deleted.")
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                            showSuccessAlert = true
                        }
                        // Then delete after alert is visible
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            if let lastRecording = heartbeatSoundManager.lastRecording {
                                heartbeatSoundManager.deleteRecording(lastRecording)
                            }
                            // Navigate after another delay
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                    showSuccessAlert = false
                                    showTimeline = true
                                }
                            }
                        }
                    })
                },
                handleLongPressChange: viewModel.handleLongPressChange,
                handleLongPressComplete: {
                    viewModel.handleLongPressComplete {
                        heartbeatSoundManager.stopRecording()
                        heartbeatSoundManager.stop()
                        tutorialViewModel.showListeningTutorialIfNeeded()
                    }
                }
            ))
        }
        .frame(width: geometry.size.width, height: geometry.size.height)
    }
    
    private var bokehEffectView: some View {
        Group {
            if viewModel.isListening {
                BokehEffectView(amplitude: $heartbeatSoundManager.blinkAmplitude)
            } else if viewModel.isPlaybackMode {
                BokehEffectView(amplitude: .constant(viewModel.audioPostProcessingManager.isPlaying ? 0.8 : 0.2))
                    .opacity(viewModel.audioPostProcessingManager.isPlaying ? 1.0 : 0.5)
                    .animation(.easeInOut(duration: 0.5), value: viewModel.audioPostProcessingManager.isPlaying)
            }
        }
        .scaleEffect(x: viewModel.physicsController.scaleX, y: viewModel.physicsController.scaleY)
        .offset(x: viewModel.physicsController.offsetX, y: viewModel.physicsController.offsetY)
        .rotationEffect(.degrees(viewModel.physicsController.rotation))
        .onAppear { viewModel.physicsController.startPhysics() }
        .frame(width: 18, height: 18)
    }
    
    private var coachMarkView: some View {
        Group {
            if !viewModel.isListening && !viewModel.isPlaybackMode {
                GeometryReader { proxy in
                    CoachMarkView()
                        .position(x: proxy.size.width / 2, y: proxy.size.height / 2 + 250)
                }
                .transition(.opacity)
            }
        }
    }
    
    private var themeButton: some View {
        VStack {
            HStack {
                if !viewModel.isListening && !viewModel.isPlaybackMode {
                    Button(action: {
                        showThemeCustomization = true
                    }, label: {
                        Image(systemName: "paintbrush.fill")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 50, height: 50)
                            .background(Circle().fill(Color.white.opacity(0.1)))
                            .clipShape(Circle())
                    })
                    .padding(.leading, 16)
                    .padding(.top, 50)
                    .transition(.opacity.animation(.easeInOut))
                }
                Spacer()
            }
            Spacer()
        }
        .allowsHitTesting(true)  // Ensure button is tappable
    }

    struct GestureModifier: ViewModifier {
        let isPlaybackMode: Bool
        let geometry: GeometryProxy
        let handleDragChange: (SequenceGesture<LongPressGesture, DragGesture>.Value) -> Void
        let handleDragEnd: (SequenceGesture<LongPressGesture, DragGesture>.Value) -> Void
        let handleLongPressChange: (Bool) -> Void
        let handleLongPressComplete: () -> Void
        
        @GestureState private var isDetectingLongPress = false
        
        func body(content: Content) -> some View {
            if isPlaybackMode {
                content.gesture(
                    LongPressGesture(minimumDuration: 0.2)
                        .sequenced(before: DragGesture())
                        .onChanged { handleDragChange($0) }
                        .onEnded { handleDragEnd($0) }
                )
            } else {
                content.gesture(
                    LongPressGesture(minimumDuration: 3.0)
                        .updating($isDetectingLongPress) { currentState, gestureState, _ in
                            gestureState = currentState
                        }
                        .onEnded { _ in
                            handleLongPressComplete()
                        }
                )
                .onChange(of: isDetectingLongPress) { _, newValue in
                    handleLongPressChange(newValue)
                }
            }
        }
    }
}
// swiftlint:enable type_body_length

// #Preview("Normal Mode") {
//    OrbLiveListenView(
//        heartbeatSoundManager: HeartbeatSoundManager(),
//        showTimeline: .constant(true)
//    )
//    .environmentObject(ThemeManager())
//    .modelContainer(for: SavedHeartbeat.self, inMemory: true)
// }

#Preview("Playback Mode") {
    let manager = HeartbeatSoundManager()
    
    // Create a mock recording
    let mockURL = URL(fileURLWithPath: "/mock/heartbeat-\(Date().timeIntervalSince1970).m4a")
    let mockRecording = Recording(fileURL: mockURL, createdAt: Date())
    
    // Set it as the last recording to trigger playback mode
    manager.lastRecording = mockRecording
    
    return OrbLiveListenView(
        heartbeatSoundManager: manager,
        showTimeline: .constant(true)
    )
    .environmentObject(ThemeManager())
    .modelContainer(for: SavedHeartbeat.self, inMemory: true)
}
