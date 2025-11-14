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

struct Recording: Identifiable, Equatable {
    let id = UUID()
    let fileURL: URL
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

class HeartbeatSoundManager: NSObject, ObservableObject {
    var engine: AudioEngine!
    var mic: AudioEngine.InputNode?
    var highPassFilter: HighPassFilter?
    var lowPassFilter: LowPassFilter?
    var secondaryLowPassFilter: LowPassFilter?
    var bandPassFilter: BandPassFilter?
    var peakLimiter: PeakLimiter?
    var compressor: Compressor?
    var gain: Fader?
    var mixer: Mixer?
    var amplitudeTap: AmplitudeTap?
    var fftTap: FFTTap?
    var recorder: NodeRecorder?
    var player: AudioPlayer?
    
    @Published var isPlaying = false
    @Published var isRunning = false
    @Published var isRecording = false
    @Published var lastRecording: Recording?
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
    
    override init() {
        super.init()
        engine = AudioEngine()
        AVAudioApplication.requestRecordPermission { granted in
            if granted {
                print("Microphone Permission granted! ")
            } else {
                print("Micrphone Denied!")
            }
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
                setupSpatialAudioChain(input: input, lowFreq: lowFreq, highFreq: highFreq)
            } else {
                setupTraditionalFilterChain(input: input, lowFreq: lowFreq, highFreq: highFreq)
            }
            
            gain = Fader(secondaryLowPassFilter!)
            gain?.gain = AUValue(gainVal)
            
            mixer = Mixer(gain!)
            
            amplitudeTap = AmplitudeTap(mixer!) { [weak self] amp in
                DispatchQueue.main.async {
                    self?.processAmplitude(amp)
                }
            }
            
            fftTap = FFTTap(mixer!) { [weak self] fftData in
                DispatchQueue.main.async {
                    self?.processFFTData(fftData)
                }
            }
            
            recorder = nil
            do {
                recorder = try NodeRecorder(node: gain!)
            } catch {
                print("Error creating recorder: \(error.localizedDescription)")
            }
            
            engine.output = mixer
            
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
        peakLimiter = nil
        compressor = nil
        secondaryLowPassFilter = nil
        lowPassFilter = nil
        bandPassFilter = nil
        highPassFilter = nil
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
                for ds in dataSources {
                    print("    • \(ds.dataSourceName)")
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
            updateSpatialAudioChain(lowCutoff, highCutoff)
        } else {
            updateTraditionalFilterChain(lowCutoff, highCutoff)
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
        // --- New logic for blinkAmplitude ---
        // Use the raw amplitude, but maybe apply a simple multiplier if it's too low.
        // Let's also apply the noise gate to avoid blinking from pure noise.
        let gatedAmplitude = applyNoiseGate(amplitude)
        DispatchQueue.main.async {
            // We can apply a multiplier to make the blink more sensitive.
            // And clamp it to ensure it stays within a 0-1 range for the UI.
            self.blinkAmplitude = min(gatedAmplitude * 5.0, 1.0)
        }
        // --- End of new logic ---
        
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
        detectHeartbeatPattern()
    }
    
    private func detectHeartbeatPattern() {
        guard !fftData.isEmpty else { return }
        
        let s1Range = 20...50
        let s2Range = 50...80
        
        let s1Amplitude = calculateAverageAmplitude(in: s1Range)
        let s2Amplitude = calculateAverageAmplitude(in: s2Range)
        
        let confidence = calculateHeartbeatConfidence(s1Amplitude: s1Amplitude, s2Amplitude: s2Amplitude)
        
        if confidence > 0.3 {
            let bpm = estimateBPM()
            let heartbeat = HeartbeatData(
                timestamp: Date(),
                bpm: bpm,
                s1Amplitude: s1Amplitude,
                s2Amplitude: s2Amplitude,
                confidence: confidence
            )
            
            DispatchQueue.main.async {
                self.heartbeatData.append(heartbeat)
                if self.heartbeatData.count > 10 {
                    self.heartbeatData.removeFirst()
                }
                self.currentBPM = bpm
            }
        }
    }
    
    private func calculateAverageAmplitude(in range: ClosedRange<Int>) -> Float {
        guard fftData.count > range.upperBound else { return 0.0 }
        
        let startIndex = max(0, range.lowerBound)
        let endIndex = min(fftData.count, range.upperBound)
        
        let slice = fftData[startIndex..<endIndex]
        return slice.reduce(0, +) / Float(slice.count)
    }
    
    private func calculateHeartbeatConfidence(s1Amplitude: Float, s2Amplitude: Float) -> Float {
        let ratio = s2Amplitude / max(s1Amplitude, 0.001)
        let idealRatio: Float = 0.6
        let ratioScore = 1.0 - abs(ratio - idealRatio)
        
        let amplitudeScore = min(1.0, (s1Amplitude + s2Amplitude) / 2.0)
        
        return (ratioScore * 0.7 + amplitudeScore * 0.3)
    }
    
    private func estimateBPM() -> Double {
        guard heartbeatData.count >= 2 else { return 0.0 }
        
        let recentData = Array(heartbeatData.suffix(5))
        guard recentData.count >= 2 else { return 0.0 }
        
        let timeDifferences = zip(recentData.dropFirst(), recentData.dropLast())
            .map { newer, older in
                newer.timestamp.timeIntervalSince(older.timestamp)
            }
        
        let averageInterval = timeDifferences.reduce(0, +) / Double(timeDifferences.count)
        
        return averageInterval > 0 ? 60.0 / averageInterval : 0.0
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
    
    private func setupSpatialAudioChain(input: AudioEngine.InputNode, lowFreq: Float, highFreq: Float) {
        // Gentle high-pass to remove only extreme sub-bass
        highPassFilter = HighPassFilter(input)
        highPassFilter?.cutoffFrequency = AUValue(lowFreq)
        highPassFilter?.resonance = AUValue(0.5) // Gentle resonance
        
        // Wide band-pass for natural sound preservation
        bandPassFilter = BandPassFilter(highPassFilter!)
        bandPassFilter?.centerFrequency = AUValue(500.0) // Center for voice/body sounds
        bandPassFilter?.bandwidth = AUValue(highFreq - lowFreq)
        
        // Gentle low-pass to remove only extreme highs
        lowPassFilter = LowPassFilter(bandPassFilter!)
        lowPassFilter?.cutoffFrequency = AUValue(highFreq)
        lowPassFilter?.resonance = AUValue(0.3) // Very gentle
        
        // Secondary gentle low-pass for smoothing
        secondaryLowPassFilter = LowPassFilter(lowPassFilter!)
        secondaryLowPassFilter?.cutoffFrequency = AUValue(highFreq)
        secondaryLowPassFilter?.resonance = AUValue(0.1) // Minimal resonance
        
        // Gentle compression for proximity enhancement
        compressor = Compressor(secondaryLowPassFilter!)
        compressor?.threshold = AUValue(-18.0) // Higher threshold for natural sound
        compressor?.headRoom = AUValue(6.0) // More headroom
        compressor?.attackTime = AUValue(0.01) // Moderate attack
        compressor?.releaseTime = AUValue(0.1) // Moderate release
        compressor?.masterGain = AUValue(0.0)
        
        // Gentle peak limiting
        peakLimiter = PeakLimiter(compressor!)
        peakLimiter?.attackTime = AUValue(0.001) // Moderate attack
        peakLimiter?.decayTime = AUValue(0.01) // Moderate decay
        peakLimiter?.preGain = AUValue(0.0)
    }
    
    private func setupTraditionalFilterChain(input: AudioEngine.InputNode, lowFreq: Float, highFreq: Float) {
        let adjustedLowFreq = aggressiveFiltering ? max(lowFreq, 50.0) : lowFreq
        
        // Traditional aggressive filtering
        highPassFilter = HighPassFilter(input)
        highPassFilter?.cutoffFrequency = AUValue(adjustedLowFreq)
        highPassFilter?.resonance = AUValue(0.7)
        
        bandPassFilter = BandPassFilter(highPassFilter!)
        bandPassFilter?.centerFrequency = AUValue((adjustedLowFreq + highFreq) / 2.0)
        bandPassFilter?.bandwidth = AUValue(highFreq - adjustedLowFreq)
        
        lowPassFilter = LowPassFilter(bandPassFilter!)
        lowPassFilter?.cutoffFrequency = AUValue(highFreq)
        lowPassFilter?.resonance = AUValue(0.5)
        
        secondaryLowPassFilter = LowPassFilter(lowPassFilter!)
        secondaryLowPassFilter?.cutoffFrequency = AUValue(min(highFreq, 120.0))
        secondaryLowPassFilter?.resonance = AUValue(0.1)
        
        compressor = Compressor(secondaryLowPassFilter!)
        compressor?.threshold = AUValue(aggressiveFiltering ? -30.0 : -24.0)
        compressor?.headRoom = AUValue(aggressiveFiltering ? 2.0 : 3.0)
        compressor?.attackTime = AUValue(0.003)
        compressor?.releaseTime = AUValue(0.05)
        compressor?.masterGain = AUValue(0.0)
        
        peakLimiter = PeakLimiter(compressor!)
        peakLimiter?.attackTime = AUValue(0.0005)
        peakLimiter?.decayTime = AUValue(0.005)
        peakLimiter?.preGain = AUValue(0.0)
    }
    
    private func updateSpatialAudioChain(_ lowFreq: Float, _ highFreq: Float) {
        highPassFilter?.cutoffFrequency = AUValue(lowFreq)
        bandPassFilter?.centerFrequency = AUValue(500.0)
        bandPassFilter?.bandwidth = AUValue(highFreq - lowFreq)
        lowPassFilter?.cutoffFrequency = AUValue(highFreq)
        secondaryLowPassFilter?.cutoffFrequency = AUValue(highFreq)
        
        compressor?.threshold = AUValue(-18.0)
        compressor?.headRoom = AUValue(6.0)
        compressor?.attackTime = AUValue(0.01)
        compressor?.releaseTime = AUValue(0.1)
    }
    
    private func updateTraditionalFilterChain(_ lowFreq: Float, _ highFreq: Float) {
        let adjustedLowFreq = aggressiveFiltering ? max(lowFreq, 50.0) : lowFreq

        highPassFilter?.cutoffFrequency = AUValue(adjustedLowFreq)
        bandPassFilter?.centerFrequency = AUValue((adjustedLowFreq + highFreq) / 2.0)
        bandPassFilter?.bandwidth = AUValue(highFreq - adjustedLowFreq)
        lowPassFilter?.cutoffFrequency = AUValue(highFreq)
        secondaryLowPassFilter?.cutoffFrequency = AUValue(min(highFreq, 120.0))

        compressor?.threshold = AUValue(aggressiveFiltering ? -30.0 : -24.0)
        compressor?.headRoom = AUValue(aggressiveFiltering ? 2.0 : 3.0)
        compressor?.attackTime = AUValue(0.003)
        compressor?.releaseTime = AUValue(0.05)
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
            let documentsURL = getDocumentsDirectory()
            let outputURL = documentsURL.appendingPathComponent("recording-\(Date().timeIntervalSince1970).caf")
            
            do {
                if fileManager.fileExists(atPath: outputURL.path) {
                    try fileManager.removeItem(at: outputURL)
                }
                try fileManager.moveItem(at: audioFile.url, to: outputURL)
                DispatchQueue.main.async {
                    self.lastRecording = Recording(fileURL: outputURL)
                }
                print("Recording saved to \(outputURL)")
            } catch {
                print("Error saving recording: \(error.localizedDescription)")
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
}





