//
//  AudioPostProcessingTestView.swift
//  Tiny
//
//  Created by Benedictus Yogatama Favian Satyajati
//

import SwiftUI

struct AudioPostProcessingTestView: View {
    @StateObject private var postProcessingManager = AudioPostProcessingManager()
    @EnvironmentObject var heartbeatSoundManager: HeartbeatSoundManager
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                VStack(spacing: 8) {
                    Image(systemName: "waveform.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text("Audio Post-Processing Test")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("EQ Settings Applied")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 40)
                
                VStack(alignment: .leading, spacing: 16) {
                    Text("EQ Configuration")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    VStack(spacing: 12) {
                        EQBandRow(frequency: "200 Hz", gain: "+20.3 dB", qFactor: "1.70", description: "Heartbeat thump boost")
                        Divider()
                        EQBandRow(frequency: "400-500 Hz", gain: "-20 dB", qFactor: "—", description: "Muddy mid-range cut")
                        Divider()
                        EQBandRow(frequency: "10 kHz", gain: "-10 dB", qFactor: "Shelf", description: "High-frequency noise reduction")
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(15)
                .padding(.horizontal)
                
                if postProcessingManager.isPlaying {
                    VStack(spacing: 8) {
                        HStack {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 12, height: 12)
                                .scaleEffect(1.2)
                                .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: true)
                            
                            Text("Playing with EQ")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.green)
                        }
                        
                        HStack {
                            Text(formatTime(postProcessingManager.currentTime))
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(formatTime(postProcessingManager.duration))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 40)
                        
                        ProgressView(value: postProcessingManager.currentTime, total: postProcessingManager.duration)
                            .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                            .padding(.horizontal, 40)
                    }
                    .padding()
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(15)
                    .padding(.horizontal)
                }
                
                Spacer()
                
                VStack(spacing: 15) {
                    Button(action: {
                        if let lastRecording = heartbeatSoundManager.lastRecording {
                            postProcessingManager.loadAndPlay(fileURL: lastRecording.fileURL)
                        }
                    }, label: {
                        HStack {
                            Image(systemName: postProcessingManager.isPlaying ? "waveform" : "play.circle.fill")
                                .font(.title2)
                            Text(postProcessingManager.isPlaying ? "Playing..." : "Play Last Recording with EQ")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(heartbeatSoundManager.lastRecording != nil ? Color.blue : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(15)
                    })
                    .disabled(heartbeatSoundManager.lastRecording == nil)

                    if postProcessingManager.isPlaying {
                        Button(action: {
                            postProcessingManager.pause()
                        }, label: {
                            HStack {
                                Image(systemName: "pause.circle.fill")
                                    .font(.title2)
                                Text("Pause")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.orange)
                            .foregroundColor(.white)
                            .cornerRadius(15)
                        })
                    }
                    
                    Button(action: {
                        postProcessingManager.stop()
                    }, label: {
                        HStack {
                            Image(systemName: "stop.circle.fill")
                                .font(.title2)
                            Text("Stop")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(15)
                    })
                    .disabled(!postProcessingManager.isPlaying)

                    if heartbeatSoundManager.lastRecording == nil {
                        Text("No recording available. Record in Orb mode first.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.top, 8)
                    } else {
                        Text("Recording: \(heartbeatSoundManager.lastRecording!.fileURL.lastPathComponent)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                            .padding(.top, 8)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 40)
            }
            .navigationBarTitle("EQ Test", displayMode: .inline)
        }
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

struct EQBandRow: View {
    let frequency: String
    let gain: String
    let qFactor: String
    let description: String
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(frequency)
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text(gain)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(gain.contains("+") ? .green : .red)
                }
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text("Q: \(qFactor)")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.gray.opacity(0.2))
                .cornerRadius(6)
        }
    }
}

#Preview {
    AudioPostProcessingTestView()
        .environmentObject(HeartbeatSoundManager())
}
