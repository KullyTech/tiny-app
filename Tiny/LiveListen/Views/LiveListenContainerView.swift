import SwiftUI
import SpriteKit

struct LiveListenContainerView: View {
    @StateObject private var soundManager = HeartbeatSoundManager()
    @State private var scene: LiveListenView?
    @State private var isListening = false
    
    var body: some View {
        ZStack {
            if let scene = scene {
                SpriteView(scene: scene)
                    .ignoresSafeArea()
            }
            
            VStack {
                Spacer()
                
                if isListening {
                    VStack(spacing: 8) {
                        Text("Amplitude: \(soundManager.amplitudeVal, specifier: "%.3f")")
                            .font(.caption)
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.black.opacity(0.6))
                            .cornerRadius(8)
                    }
                    .padding(.bottom, 16)
                }
                
                Button(action: {
                    toggleListening()
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: isListening ? "stop.circle.fill" : "play.circle.fill")
                            .font(.title2)
                        Text(isListening ? "Stop Listening" : "Start Listening")
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        isListening ? 
                        Color.red.opacity(0.8) : 
                        Color.blue.opacity(0.8)
                    )
                    .cornerRadius(16)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            setupScene()
        }
        .onDisappear {
            if isListening {
                stopListening()
            }
        }
        .onChange(of: soundManager.amplitudeVal) { oldValue, newValue in
            if isListening {
                scene?.currentAmplitude = newValue
            }
        }
    }
    
    private func setupScene() {
        let newScene = LiveListenView()
        newScene.scaleMode = .resizeFill
        scene = newScene
    }
    
    private func toggleListening() {
        if isListening {
            stopListening()
        } else {
            startListening()
        }
    }
    
    private func startListening() {
        soundManager.updateGain(50.0)
        soundManager.start()
        isListening = true
    }
    
    private func stopListening() {
        soundManager.stop()
        isListening = false
        scene?.resetHeartbeat()
    }
}

#Preview {
    LiveListenContainerView()
}
