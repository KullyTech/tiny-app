import SwiftUI

struct OrbLiveListenView: View {
    @StateObject var heartbeatSoundManager = HeartbeatSoundManager()
    @StateObject private var audioPostProcessingManager = AudioPostProcessingManager()
    @StateObject private var physicsController = OrbPhysicsController()
    @State private var isListening = false
    @State private var animateOrb = false
    @State private var showShareSheet = false
    @State private var isPlaybackMode = false

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

                if isListening {
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
                        isPlaybackMode ? 
                            (audioPostProcessingManager.isPlaying ? 1.15 : 0.8) : 
                            (animateOrb ? 1.5 : 1.0)
                    )
                    .animation(.easeInOut(duration: 0.5), value: audioPostProcessingManager.isPlaying)
                    .animation(.interpolatingSpring(mass: 2, stiffness: 100, damping: 20), value: animateOrb)
                    .offset(y: getOrbOffset(geometry: geometry))
                    .onTapGesture(count: 2) {
                        handleDoubleTap()
                    }
                    .onTapGesture(count: 1) {
                        handleSingleTap()
                    }
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
        if isListening {
            withAnimation(.interpolatingSpring(mass: 2, stiffness: 100, damping: 20)) {
                isListening = false
                animateOrb = false
                isPlaybackMode = true
            }
            
            heartbeatSoundManager.stopRecording()
            heartbeatSoundManager.stop()
            
        } else if isPlaybackMode {
            audioPostProcessingManager.stop()
            
            withAnimation(.interpolatingSpring(mass: 2, stiffness: 100, damping: 20)) {
                isPlaybackMode = false
                isListening = true
                animateOrb = true
            }
            
            heartbeatSoundManager.start()
            heartbeatSoundManager.startRecording()
            
        } else if !isPlaybackMode {
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
                    audioPostProcessingManager.resume()
                } else {
                    audioPostProcessingManager.loadAndPlay(fileURL: lastRecording.fileURL)
                }
            }
        }
    }
}

#Preview {
    OrbLiveListenView()
}
