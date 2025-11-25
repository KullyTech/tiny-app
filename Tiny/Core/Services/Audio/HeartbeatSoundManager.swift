//
//  HeartbeatSoundManager.swift
//  Tiny
//
//  Created by Benedictus Yogatama Favian Satyajati on 30/10/25.
//

import Foundation
import AVFoundation
import Accelerate

import AudioKit
import AudioKitEX

internal import Combine

import SwiftData
import UIKit
import SwiftUI

struct Recording: Identifiable, Equatable {
    let id = UUID()
    let fileURL: URL
    let createdAt: Date
    var isPlaying: Bool = false
}

struct HeartbeatData {
    let timestamp: Date
    let bpm: Double
    let s1Amplitude: Float
    let s2Amplitude: Float
    let confidence: Float
}

enum HeartbeatFilterMode {
    case standard
    case enhanced
    case sensitive
    case spatial
}

// swiftlint:disable type_body_length
@MainActor
class HeartbeatSoundManager: NSObject, ObservableObject {
    var modelContext: ModelContext?
    
    var engine: AudioEngine!
    var mic: AudioEngine.InputNode?
    var gain: Fader?
    var mixer: Mixer?
    private let filterChainBuilder = AudioFilterChainBuilder()

    var highPassFilter: HighPassFilter? { filterChainBuilder.highPassFilter }
    var lowPassFilter: LowPassFilter? { filterChainBuilder.lowPassFilter }
    var secondaryLowPassFilter: LowPassFilter? { filterChainBuilder.secondaryLowPassFilter }
    var bandPassFilter: BandPassFilter? { filterChainBuilder.bandPassFilter }
    var peakLimiter: PeakLimiter? { filterChainBuilder.peakLimiter }
    var compressor: Compressor? { filterChainBuilder.compressor }
    var amplitudeTap: AmplitudeTap?
    var fftTap: FFTTap?
    var recorder: NodeRecorder?
    var player: AudioPlayer?

    @Published var isPlaying = false
    @Published var isRunning = false
    @Published var isRecording = false
    @Published var lastRecording: Recording?
    @Published var savedRecordings: [Recording] = []
    @Published var isPlayingPlayback = false
    @Published var amplitudeVal: Float = 0.0
    @Published var blinkAmplitude: Float = 0.0
    @Published var gainVal: Float = 100.0
    @Published var currentBPM: Double = 0.0
    @Published var heartbeatData: [HeartbeatData] = []
    @Published var fftData: [Float] = []
    @Published var filterMode: HeartbeatFilterMode = .spatial
    @Published var noiseFloor: Float = 0.0
    @Published var signalQuality: Float = 0.0
    @Published var noiseReductionEnabled: Bool = true
    @Published var adaptiveGainEnabled: Bool = true
    @Published var aggressiveFiltering: Bool = false
    @Published var spatialMode: Bool = true
    @Published var proximityGain: Float = 2.0
    @Published var noiseGateThreshold: Float = 0.005

    private let heartbeatDetector = HeartbeatDetector()
    
    override init() {
        super.init()
        engine = AudioEngine()
    }

    func requestMicrophonePermission(completion: @escaping (Bool) -> Void) {
        AVAudioApplication.requestRecordPermission { granted in
            DispatchQueue.main.async {
                completion(granted)
            }
        }
    }
    
    func loadFromSwiftData() {
        guard let modelContext = modelContext else { return }
        do {
            let results = try modelContext.fetch(FetchDescriptor<SavedHeartbeat>())
            let documentsURL = getDocumentsDirectory()
            
            DispatchQueue.main.async {
                // ✅ Map the REAL timestamp from SwiftData
                self.savedRecordings = results.map { savedItem in
                    let fileName = URL(fileURLWithPath: savedItem.filePath).lastPathComponent
                    
                    let currentURL = documentsURL.appendingPathComponent(fileName)
                    
                    return Recording(
                        fileURL: currentURL,
                        createdAt: savedItem.timestamp
                    )
                }
            }
            print("✅ Loaded \(self.savedRecordings.count) recordings from SwiftData")
        } catch {
            print("SwiftData load error: \(error)")
        }
    }
    
    func setupAudio() {
        do {
            cleanupAudio()

            let session = AVAudioSession.sharedInstance()

            try session.setCategory(.playAndRecord, mode: .measurement, options: [.allowBluetoothHFP, .allowBluetoothA2DP])
            try useBottomMicrophone()
            try session.setActive(true)

            guard let input = engine.input else {
                print("No input available!")
                return
            }

            mic = input

            let (lowFreq, highFreq) = getFilterFrequencies(for: filterMode)

            if spatialMode {
                filterChainBuilder.setupSpatialAudioChain(input: input, lowFreq: lowFreq, highFreq: highFreq)
            } else {
                filterChainBuilder.setupTraditionalFilterChain(input: input, lowFreq: lowFreq, highFreq: highFreq, aggressiveFiltering: aggressiveFiltering)
            }

            guard let secondaryLowPass = filterChainBuilder.secondaryLowPassFilter else {
                print("Error: Secondary low pass filter not initialized")
                return
            }

            gain = Fader(secondaryLowPass)
            gain?.gain = AUValue(gainVal)

            guard let gainNode = gain else {
                print("Error: Gain node not initialized")
                return
            }

            mixer = Mixer(gainNode)

            guard let mixerNode = mixer else {
                print("Error: Mixer node not initialized")
                return
            }

            amplitudeTap = AmplitudeTap(mixerNode) { [weak self] amp in
                DispatchQueue.main.async {
                    self?.processAmplitude(amp)
                }
            }

            fftTap = FFTTap(mixerNode) { [weak self] fftData in
                DispatchQueue.main.async {
                    self?.processFFTData(fftData)
                }
            }

            recorder = nil
            do {
                recorder = try NodeRecorder(node: gainNode)
            } catch {
                print("Error creating recorder: \(error.localizedDescription)")
            }

            engine.output = mixerNode

            amplitudeTap?.start()
            fftTap?.start()
            print("Audio analysis taps started")

        } catch {
            print("Error setting up audio!: \(error.localizedDescription)")
        }
    }

    private func cleanupAudio() {
        amplitudeTap?.stop()
        amplitudeTap = nil

        fftTap?.stop()
        fftTap = nil

        recorder?.stop()
        recorder = nil

        if engine.avEngine.isRunning {
            engine.stop()
        }

        mixer = nil
        gain = nil
        filterChainBuilder.peakLimiter = nil
        filterChainBuilder.compressor = nil
        filterChainBuilder.secondaryLowPassFilter = nil
        filterChainBuilder.lowPassFilter = nil
        filterChainBuilder.bandPassFilter = nil
        filterChainBuilder.highPassFilter = nil
        mic = nil

        engine.output = nil
    }

    private func resetEngine() {
        if engine.avEngine.isRunning {
            engine.stop()
        }
        engine = AudioEngine()
    }

    func useBottomMicrophone() throws {
        let session = AVAudioSession.sharedInstance()
        let availableInputs = session.availableInputs ?? []

        print("🎧 Available audio inputs:")
        for input in availableInputs {
            print("Input portType: \(input.portType.rawValue), portName: \(input.portName)")

            if let dataSources = input.dataSources, !dataSources.isEmpty {
                print("Data sources for \(input.portName):")
                for dataSource in dataSources {
                    print("    • \(dataSource.dataSourceName)")
                }
            }
        }

        // 1. Find the built-in microphone
        guard let builtInMic = availableInputs.first(where: { $0.portType == .builtInMic }) else {
            print("❌ No built-in mic found.")
            return
        }

        print("🎤 Built-in mic found: \(builtInMic.portName)")

        // 2. Look for the BOTTOM mic data source
        let bottomNames = ["Bottom", "Back", "Primary Bottom", "Microphone (Bottom)"]

        let bottomDataSource = builtInMic.dataSources?.first(where: {
            bottomNames.contains($0.dataSourceName)
        })

        // 3. If found, set it
        if let bottom = bottomDataSource {
            print("✅ Selecting bottom microphone: \(bottom.dataSourceName)")
            try session.setPreferredInput(builtInMic)
            try builtInMic.setPreferredDataSource(bottom)
        } else {
            print("⚠️ Bottom microphone data source NOT found; using default.")
            try session.setPreferredInput(builtInMic)
        }
    }

    func getDocumentsDirectory() -> URL {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask) [0]
    }

    func updateGain(_ newGain: Float) {
        gainVal = newGain
        gain?.gain = AUValue(newGain)
    }

    func updateBandpassRange(lowCutoff: Float, highCutoff: Float) {
        if spatialMode {
            filterChainBuilder.updateSpatialAudioChain(lowCutoff, highCutoff)
        } else {
            filterChainBuilder.updateTraditionalFilterChain(lowCutoff, highCutoff, aggressiveFiltering: aggressiveFiltering)
        }
    }

    func getFilterFrequencies(for mode: HeartbeatFilterMode) -> (Float, Float) {
        switch mode {
        case .standard:
            return (20.0, 2000.0) // Wide range for natural sound
        case .enhanced:
            return (15.0, 3000.0) // Even wider for clarity
        case .sensitive:
            return (10.0, 4000.0) // Maximum range
        case .spatial:
            return (15.0, 2500.0) // Optimized for spatial processing
        }
    }

    func setFilterMode(_ mode: HeartbeatFilterMode) {
        filterMode = mode
        if isRunning {
            let (lowFreq, highFreq) = getFilterFrequencies(for: mode)
            updateBandpassRange(lowCutoff: lowFreq, highCutoff: highFreq)
        }
    }

    private func processAmplitude(_ amplitude: Float) {
        // --- Updated logic for blinkAmplitude ---
        // Only update blinkAmplitude if it's lower than the current value
        // This allows heartbeat-triggered blinks to persist and decay naturally
        // Apply noise gate to avoid blinking from pure noise
        let gatedAmplitude = applyNoiseGate(amplitude)
        DispatchQueue.main.async {
            let newBlinkValue = min(gatedAmplitude * 5.0, 1.0)
            // Only update if new value is higher, allowing heartbeat blinks to persist
            if newBlinkValue > self.blinkAmplitude {
                self.blinkAmplitude = newBlinkValue
            } else {
                // Allow natural decay
                self.blinkAmplitude = max(self.blinkAmplitude * 0.95, newBlinkValue)
            }
        }
        // --- End of updated logic ---

        var processedAmplitude = amplitude

        // Apply noise gate to eliminate low-level noise
        if noiseReductionEnabled {
            processedAmplitude = applyNoiseGate(processedAmplitude)
            processedAmplitude = applyNoiseReduction(processedAmplitude)
        }

        if adaptiveGainEnabled {
            processedAmplitude = applyAdaptiveGain(processedAmplitude)
        }

        amplitudeVal = processedAmplitude

        if processedAmplitude > noiseFloor * 1.5 {
            signalQuality = min(1.0, (processedAmplitude - noiseFloor) / (noiseFloor * 2))
        } else {
            signalQuality = max(0.0, signalQuality - 0.1)
        }

        updateNoiseFloor()
    }

    private func updateNoiseFloor() {
        let smoothingFactor: Float = aggressiveFiltering ? 0.98 : 0.95
        let targetNoiseFloor = amplitudeVal * 0.3 // Use 30% of current amplitude as noise estimate
        noiseFloor = noiseFloor * smoothingFactor + targetNoiseFloor * (1.0 - smoothingFactor)
    }

    private func processFFTData(_ fftData: [Float]) {
        self.fftData = Array(fftData.prefix(128))

        if let heartbeat = heartbeatDetector.detectHeartbeat(from: self.fftData) {
            DispatchQueue.main.async {
                self.heartbeatData.append(heartbeat)
                if self.heartbeatData.count > 10 {
                    self.heartbeatData.removeFirst()
                }
                self.currentBPM = heartbeat.bpm

                // Update blinkAmplitude when heartbeat is detected
                // Use S1 amplitude (the first, louder sound) to trigger brighter blink
                // Scale it appropriately and combine with confidence for better visibility
                let scaledS1 = min(heartbeat.s1Amplitude * 10.0, 1.0)
                let confidenceBoost = heartbeat.confidence * 0.3
                self.blinkAmplitude = min(scaledS1 + confidenceBoost, 1.0)
            }
        }
    }

    private func applyNoiseGate(_ amplitude: Float) -> Float {
        let threshold = max(noiseGateThreshold, noiseFloor * 1.5)

        if amplitude < threshold {
            return 0.0
        }

        // Smooth transition to avoid clicking
        let smoothingFactor: Float = 0.1
        let smoothedAmplitude = amplitude * smoothingFactor + (amplitude - threshold) * (1.0 - smoothingFactor)

        return max(0.0, smoothedAmplitude)
    }

    private func applyNoiseReduction(_ amplitude: Float) -> Float {
        let threshold = noiseFloor * (aggressiveFiltering ? 1.8 : 1.5)
        let reductionFactor: Float = aggressiveFiltering ? 0.1 : 0.2

        if amplitude < threshold {
            return amplitude * reductionFactor
        }
        return amplitude
    }

    private func applyAdaptiveGain(_ amplitude: Float) -> Float {
        let targetAmplitude: Float = 0.3
        let maxGain: Float = 3.0
        let minGain: Float = 0.5

        let error = targetAmplitude - amplitude
        let computedGain = 1.0 + (error * 0.5)

        let clampedGain = max(minGain, min(maxGain, computedGain))

        // Apply proximity gain for spatial mode
        let finalGain = spatialMode ? (gainVal * clampedGain * proximityGain) : (gainVal * clampedGain)
        self.gain?.gain = AUValue(finalGain)

        return amplitude * clampedGain * (spatialMode ? proximityGain : 1.0)
    }

    func toggleNoiseReduction() {
        noiseReductionEnabled.toggle()
    }

    func toggleAdaptiveGain() {
        adaptiveGainEnabled.toggle()
        if !adaptiveGainEnabled {
            gain?.gain = AUValue(gainVal)
        }
    }

    func toggleAggressiveFiltering() {
        aggressiveFiltering.toggle()
        if isRunning {
            setupAudio()
        }
    }

    func updateNoiseGateThreshold(_ threshold: Float) {
        noiseGateThreshold = threshold
    }

    func toggleSpatialMode() {
        spatialMode.toggle()
        if isRunning {
            setupAudio()
        }
    }

    func updateProximityGain(_ gain: Float) {
        proximityGain = gain
    }

    func startRecording() {
        guard let recorder = recorder, !isRecording else { return }
        do {
            if recorder.isRecording {
                recorder.stop()
            }
            try recorder.record()
            isRecording = true
        } catch {
            print("Error starting recording: \(error.localizedDescription)")
        }
    }

    func stopRecording() {
        guard let recorder = recorder, recorder.isRecording else { return }
        recorder.stop()
        isRecording = false
        
        if let audioFile = recorder.audioFile {
            let fileManager = FileManager.default
            let outputURL = getDocumentsDirectory().appendingPathComponent("recording-\(Date().timeIntervalSince1970).caf")
            
            do {
                if fileManager.fileExists(atPath: outputURL.path) {
                    try fileManager.removeItem(at: outputURL)
                }
                try fileManager.moveItem(at: audioFile.url, to: outputURL)
                DispatchQueue.main.async {
                    self.lastRecording = Recording(fileURL: outputURL, createdAt: Date())
                }
            } catch {
                print(error)
            }
        }
    }

    func togglePlayback(recording: Recording) {
        if player?.isPlaying == true {
            player?.stop()
            if engine.avEngine.isRunning {
                engine.stop()
            }
            isPlayingPlayback = false
            if lastRecording?.id == recording.id {
                lastRecording?.isPlaying = false
            }
        } else {
            do {
                if isRunning {
                    stop()
                }

                resetEngine()

                player = AudioPlayer(url: recording.fileURL)
                player?.completionHandler = { [weak self] in
                    DispatchQueue.main.async {
                        self?.isPlayingPlayback = false
                        if self?.lastRecording?.id == recording.id {
                            self?.lastRecording?.isPlaying = false
                        }
                    }
                }

                engine.output = player
                try engine.start()
                player?.play()
                isPlayingPlayback = true
                if lastRecording?.id == recording.id {
                    lastRecording?.isPlaying = true
                }
            } catch {
                print("Error playing back recording: \(error.localizedDescription)")
            }
        }
    }

    func start() {
        if isPlayingPlayback {
            player?.stop()
            isPlayingPlayback = false
            if lastRecording != nil {
                lastRecording?.isPlaying = false
            }
        }
        resetEngine()
        setupAudio()

        do {
            try engine.start()
            isRunning = true
            print("Audio engine started successfully")

            if amplitudeTap?.isStarted == false {
                amplitudeTap?.start()
                print("Amplitude tap restarted")
            }
        } catch {
            print("Error starting engine: \(error.localizedDescription)")
            cleanupAudio()
            isRunning = false
        }
    }

    func stop() {
        amplitudeTap?.stop()

        if engine.avEngine.isRunning {
            engine.stop()
        }

        cleanupAudio()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            do {
                try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
            } catch {
                print("Error deactivating audio session: \(error.localizedDescription)")
            }
        }

        isRunning = false
    }
    
    func saveRecording() {
        guard let recording = lastRecording else { return }
        self.savedRecordings.append(recording)
        
        guard let modelContext = modelContext else { return }
    
        let entry = SavedHeartbeat(
            filePath: recording.fileURL.path,
            timestamp: recording.createdAt
        )
        
        modelContext.insert(entry)
        do {
            try modelContext.save()
        } catch {
            print("SwiftData save failed: \(error)")
        }
    }
}
// swiftlint:enable type_body_length
