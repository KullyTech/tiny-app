import SwiftUI
import SwiftData

struct OrbLiveListenView: View {
    @Environment(\.modelContext) private var modelContext

    @ObservedObject var heartbeatSoundManager: HeartbeatSoundManager
    @Binding var showTimeline: Bool

    @StateObject private var viewModel = OrbLiveListenViewModel()
    @StateObject private var tutorialViewModel = TutorialViewModel()
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                backgroundView
                topControlsView
                statusTextView
                orbView(geometry: geometry)
                
                // Save/Library Button (Only visible when dragging)
                saveButton(geometry: geometry)
                
                // Floating Button to Open Timeline manually
                if !viewModel.isListening && !viewModel.isDraggingToSave {
                    libraryOpenButton(geometry: geometry)
                }
                
                coachMarkView
                
                if let context = tutorialViewModel.activeTutorial {
                    TutorialOverlay(viewModel: tutorialViewModel, context: context)
                }
            }
            .sheet(isPresented: $viewModel.showShareSheet) {
                if let lastRecordingURL = heartbeatSoundManager.lastRecording?.fileURL {
                    ShareSheet(activityItems: [lastRecordingURL])
                }
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
            Image("background")
                .resizable()
                .scaleEffect(viewModel.isListening ? 1.2 : 1.0)
                .animation(.easeInOut(duration: 1.2), value: viewModel.isListening)
                .ignoresSafeArea()
        }
    }
    
    private var topControlsView: some View {
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
                    .transition(.opacity.animation(.easeInOut))
                }
                Spacer()
            }
            .padding()
            Spacer()
        }
    }
    
    private func libraryOpenButton(geometry: GeometryProxy) -> some View {
        VStack {
            HStack {
                Spacer()
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
            .background(Circle().fill(Color.white.opacity(0.1)))
            .clipShape(Circle())
            .scaleEffect(viewModel.saveButtonScale)
            .position(x: geometry.size.width / 2, y: geometry.size.height - 100)
            .opacity(viewModel.isDraggingToSave ? min(viewModel.dragOffset / 150.0, 1.0) : 0.0)
            .animation(.easeOut(duration: 0.2), value: viewModel.isDraggingToSave)
            .animation(.easeOut(duration: 0.2), value: viewModel.dragOffset)
    }
    
    private var statusTextView: some View {
        VStack {
            Group {
                if viewModel.isListening && viewModel.isLongPressing {
                    CountdownTextView(countdown: viewModel.longPressCountdown, isVisible: viewModel.isLongPressing)
                } else if viewModel.isListening {
                    Text("Listening...")
                        .font(.title)
                        .fontWeight(.bold)
                } else if viewModel.isPlaybackMode {
                    VStack(spacing: 8) {
                        Text(viewModel.audioPostProcessingManager.isPlaying ? "Playing..." :
                                (viewModel.isDraggingToSave ? "Drag to save" : "Tap orb to play"))
                            .font(.title2)
                            .fontWeight(.medium)
                        
                        if viewModel.audioPostProcessingManager.duration > 0 && !viewModel.isDraggingToSave {
                            Text("\(Int(viewModel.audioPostProcessingManager.currentTime))s / \(Int(viewModel.audioPostProcessingManager.duration))s")
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
            .onTapGesture(count: 2) {
                viewModel.handleDoubleTap {
                    heartbeatSoundManager.start()
                    heartbeatSoundManager.startRecording()
                    tutorialViewModel.showListeningTutorialIfNeeded()
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
                    viewModel.handleDragEnd(value: value, geometry: geometry) {
                        heartbeatSoundManager.saveRecording()
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                            showTimeline = true
                        }
                    }
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

    struct GestureModifier: ViewModifier {
        let isPlaybackMode: Bool
        let geometry: GeometryProxy
        let handleDragChange: (SequenceGesture<LongPressGesture, DragGesture>.Value) -> Void
        let handleDragEnd: (SequenceGesture<LongPressGesture, DragGesture>.Value) -> Void
        let handleLongPressChange: (Bool) -> Void
        let handleLongPressComplete: () -> Void
        
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
                        .onChanged { handleLongPressChange($0) }
                        .onEnded { _ in handleLongPressComplete() }
                )
            }
        }
    }
}

#Preview {
    OrbLiveListenView(
        heartbeatSoundManager: HeartbeatSoundManager(),
        showTimeline: .constant(false)
    )
    .modelContainer(for: SavedHeartbeat.self, inMemory: true)
}
