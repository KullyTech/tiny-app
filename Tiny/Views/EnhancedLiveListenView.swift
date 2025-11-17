//
//  EnhancedLiveListenView.swift
//  Tiny
//
//  Created by Destu Cikal Ramdani on 12/11/25.
//

import SwiftUI

// swiftlint:disable type_body_length
struct EnhancedLiveListenView: View {
    @StateObject private var manager = HeartbeatSoundManager()
    @StateObject private var bluetoothManager = BluetoothManager()
    @State private var showShareSheet = false
    @State private var showAdvancedSettings = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    bluetoothStatusSection
                    statusSection
                    audioVisualizationSection
                    heartbeatAnalysisSection
                    controlsSection
                    recordingSection
                    advancedSettingsSection
                }
                .padding()
            }
            .navigationBarTitle("Heartbeat Monitor", displayMode: .large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showAdvancedSettings.toggle()
                    }, label: {
                        Image(systemName: "gearshape.fill")
                    })
                }
            }
            .sheet(isPresented: $showAdvancedSettings) {
                AdvancedSettingsView(manager: manager, bluetoothManager: bluetoothManager)
            }
        }
    }
    
    private var bluetoothStatusSection: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: bluetoothManager.connectionIcon)
                    .foregroundColor(bluetoothManager.connectionColor)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(bluetoothManager.connectionStatus)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(bluetoothManager.connectionColor)
                    
                    if let deviceName = bluetoothManager.connectedDeviceName {
                        Text(deviceName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                if bluetoothManager.isLiveListenActive {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 8, height: 8)
                            .scaleEffect(1.2)
                            .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: true)
                        Text("Live Listen")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.green)
                    }
                }
            }
            .padding()
            .background(bluetoothManager.isLiveListenActive ? Color.green.opacity(0.1) : Color.gray.opacity(0.1))
            .cornerRadius(15)
        }
    }
    
    private var statusSection: some View {
        VStack(spacing: 12) {
            HStack {
                Circle()
                    .fill(manager.isRunning ? Color.green : Color.red)
                    .frame(width: 20, height: 20)
                    .scaleEffect(manager.isRunning ? 1.2 : 1.0)
                    .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: manager.isRunning)
                
                Text(manager.isRunning ? "Listening" : "Stopped")
                    .font(.headline)
                    .foregroundColor(manager.isRunning ? .green : .red)
                
                Spacer()
                
                if manager.currentBPM > 0 {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(String(format: "%.0f", manager.currentBPM))
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        Text("BPM")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(15)
        }
    }
    
    private var audioVisualizationSection: some View {
        VStack(spacing: 12) {
            Text("Audio Analysis")
                .font(.headline)
                .foregroundColor(.primary)
            
            AudioVisualizationView(
                fftData: $manager.fftData,
                amplitude: $manager.amplitudeVal,
                signalQuality: $manager.signalQuality
            )
        }
    }
    
    private var heartbeatAnalysisSection: some View {
        HeartbeatAnalysisView(
            heartbeatData: $manager.heartbeatData,
            currentBPM: $manager.currentBPM,
            filterMode: $manager.filterMode,
            onFilterModeChange: { mode in
                manager.setFilterMode(mode)
            }
        )
    }
    
    private var controlsSection: some View {
        VStack(spacing: 15) {
            // Gain control
            VStack(spacing: 10) {
                HStack {
                    Text("Amplification")
                        .font(.headline)
                    Spacer()
                    Text("\(String(format: "%.1f", manager.gainVal))x")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Slider(value: Binding(
                    get: { manager.gainVal },
                    set: { manager.updateGain($0) }
                ),
                in: 1...50,
                step: 1.0)
                .accentColor(.blue)
                
                HStack {
                    Text("1x")
                        .font(.caption)
                    Spacer()
                    Text("50x")
                        .font(.caption)
                }
                .foregroundColor(.secondary)
            }
            .padding()
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(15)
            
            // Main control buttons
            HStack(spacing: 15) {
                Button(action: {
                    manager.start()
                }, label: {
                    Label("Start", systemImage: "play.fill")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .cornerRadius(15)
                })
                .disabled(manager.isRunning)
                
                Button(action: {
                    manager.stop()
                }, label: {
                    Label("Stop", systemImage: "stop.fill")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .cornerRadius(15)
                })
                .disabled(!manager.isRunning)
            }
        }
    }
    
    private var recordingSection: some View {
        VStack(spacing: 15) {
            // Recording control
            Button(action: {
                if manager.isRecording {
                    manager.stopRecording()
                } else {
                    manager.startRecording()
                }
            }, label: {
                Label(manager.isRecording ? "Stop Recording" : "Start Recording", systemImage: "mic.circle.fill")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(manager.isRecording ? Color.orange : Color.blue)
                    .cornerRadius(15)
            })
            .disabled(!manager.isRunning)
            
            // Last recording playback
            if let recording = manager.lastRecording {
                VStack(spacing: 10) {
                    Text("Last Recording")
                        .font(.headline)
                    Text(recording.fileURL.lastPathComponent)
                        .font(.caption)
                        .lineLimit(1)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 10) {
                        Button(action: {
                            manager.togglePlayback(recording: recording)
                        }, label: {
                            Label(manager.isPlayingPlayback ? "Stop" : "Play", systemImage: manager.isPlayingPlayback ? "stop.fill" : "play.fill")
                                .font(.subheadline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.orange)
                                .cornerRadius(10)
                        })

                        Button(action: {
                            showShareSheet = true
                        }, label: {
                            Label("Share", systemImage: "square.and.arrow.up")
                                .font(.subheadline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.accentColor)
                                .cornerRadius(10)
                        })
                    }
                }
                .padding()
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(15)
                .sheet(isPresented: $showShareSheet) {
                    ShareSheet(activityItems: [recording.fileURL])
                }
            }
        }
    }
    
    private var advancedSettingsSection: some View {
        VStack(spacing: 12) {

            // === settings toggles ===
            VStack(spacing: 12) {
                HStack {
                    Text("Noise Reduction")
                        .font(.subheadline)
                    Spacer()
                    Toggle("", isOn: Binding(
                        get: { manager.noiseReductionEnabled },
                        set: { _ in manager.toggleNoiseReduction() }
                    ))
                }

                HStack {
                    Text("Adaptive Gain")
                        .font(.subheadline)
                    Spacer()
                    Toggle("", isOn: Binding(
                        get: { manager.adaptiveGainEnabled },
                        set: { _ in manager.toggleAdaptiveGain() }
                    ))
                }

                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Spatial Mode")
                            .font(.subheadline)
                        Text("Enhanced proximity audio")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Toggle("", isOn: Binding(
                        get: { manager.spatialMode },
                        set: { _ in manager.toggleSpatialMode() }
                    ))
                }

                if manager.spatialMode {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Proximity Gain")
                                .font(.subheadline)
                            Text("Boost close sounds")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Text(String(format: "%.1fx", manager.proximityGain))
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Noise Gate")
                            .font(.subheadline)
                        Spacer()
                        Text(String(format: "%.3f", manager.noiseGateThreshold))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Slider(
                        value: Binding(
                            get: { manager.noiseGateThreshold },
                            set: { manager.updateNoiseGateThreshold($0) }
                        ),
                        in: 0.001...0.1,
                        step: 0.001
                    )
                    .accentColor(.orange)

                    HStack {
                        Text("Silent")
                            .font(.caption)
                        Spacer()
                        Text("Sensitive")
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                }
            }

            // === spatial preset button ===
            Button(
                action: {
                    manager.setFilterMode(.spatial)
                    manager.toggleSpatialMode()
                    manager.updateProximityGain(3.0)
                    manager.updateNoiseGateThreshold(0.005)
                },
                label: {
                    HStack {
                        Image(systemName: "waveform.and.person.filled")
                        Text("Apply Spatial Audio Preset")
                    }
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
                }
            )
        }
    }

}
// swiftlint:enable type_body_length

struct AdvancedSettingsView: View {
    @ObservedObject var manager: HeartbeatSoundManager
    @ObservedObject var bluetoothManager: BluetoothManager
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Filter Mode Selection
                VStack(alignment: .leading, spacing: 12) {
                    Text("Filter Mode")
                        .font(.headline)
                    
                    ForEach(HeartbeatFilterMode.allCases, id: \.self) { mode in
                        Button(action: {
                            manager.setFilterMode(mode)
                        }, label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(mode.displayName)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    Text(mode.frequencyRange)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                if manager.filterMode == mode {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.blue)
                                }
                            }
                            .padding()
                            .background(manager.filterMode == mode ? Color.blue.opacity(0.1) : Color.gray.opacity(0.05))
                            .cornerRadius(10)
                        })
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                
                // Bluetooth & Audio Device Settings
                VStack(alignment: .leading, spacing: 12) {
                    Text("Audio Device")
                        .font(.headline)
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Connected Device")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text(bluetoothManager.connectedDeviceName ?? "None")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            bluetoothManager.refreshConnectionStatus()
                        }, label: {
                            Image(systemName: "arrow.clockwise")
                                .font(.subheadline)
                                .foregroundColor(.blue)
                        })
                    }
                    
                    if bluetoothManager.isLiveListenActive {
                        HStack {
                            Image(systemName: "wave.3.left.circle.fill")
                                .foregroundColor(.green)
                            Text("Live Listen Active")
                                .font(.subheadline)
                                .foregroundColor(.green)
                            Spacer()
                        }
                    }
                    
                    Button(action: {
                        bluetoothManager.requestBluetoothPermission()
                    }, label: {
                        HStack {
                            Image(systemName: "bluetooth")
                            Text("Configure Bluetooth")
                        }
                        .font(.subheadline)
                        .foregroundColor(.blue)
                    })
                }
                
                // Signal Processing Options
                VStack(alignment: .leading, spacing: 12) {
                    Text("Signal Processing")
                        .font(.headline)
                    
                    Toggle("Noise Reduction", isOn: Binding(
                        get: { manager.noiseReductionEnabled },
                        set: { _ in manager.toggleNoiseReduction() }
                    ))
                    
                    Toggle("Adaptive Gain", isOn: Binding(
                        get: { manager.adaptiveGainEnabled },
                        set: { _ in manager.toggleAdaptiveGain() }
                    ))
                    
                    Toggle("Aggressive Filtering", isOn: Binding(
                        get: { manager.aggressiveFiltering },
                        set: { _ in manager.toggleAggressiveFiltering() }
                    ))
                    
                    Toggle("Spatial Mode", isOn: Binding(
                        get: { manager.spatialMode },
                        set: { _ in manager.toggleSpatialMode() }
                    ))
                }
                
                // Spatial Audio Preset
                Button(action: {
                    manager.setFilterMode(.spatial)
                    manager.toggleSpatialMode()
                    manager.updateProximityGain(3.0)
                    manager.updateNoiseGateThreshold(0.005)
                }, label: {
                    HStack {
                        Image(systemName: "waveform.and.person.filled")
                        Text("Apply Spatial Audio Preset")
                    }
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
                })
                
                Spacer()
            }
            .padding()
            .navigationBarTitle("Advanced Settings", displayMode: .inline)
            .navigationBarItems(
                trailing: Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
}

#Preview {
    EnhancedLiveListenView()
}
