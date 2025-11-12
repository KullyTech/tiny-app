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
    case noiseReduced
}

class HeartbeatSoundManager: NSObject, ObservableObject {
    var engine: AudioEngine!
    var mic: AudioEngine.InputNode?
    var highPassFilter: HighPassFilter?
    var lowPassFilter: LowPassFilter?
    var secondaryLowPassFilter: LowPassFilter?
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
    @Published var gainVal: Float = 10.0
    @Published var currentBPM: Double = 0.0
    @Published var heartbeatData: [HeartbeatData] = []
    @Published var fftData: [Float] = []
    @Published var filterMode: HeartbeatFilterMode = .standard
    @Published var noiseFloor: Float = 0.0
    @Published var signalQuality: Float = 0.0
    @Published var noiseReductionEnabled: Bool = true
    @Published var adaptiveGainEnabled: Bool = true
    @Published var aggressiveFiltering: Bool = false
    
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
            try forceBuiltInMicrophone()
            try session.setActive(true)
            
            guard let input = engine.input else {
                print("No input available!")
                return
            }
            
            mic = input
            
            let (lowFreq, highFreq) = getFilterFrequencies(for: filterMode)
            let adjustedLowFreq = aggressiveFiltering ? max(lowFreq, 40.0) : lowFreq
            
            highPassFilter = HighPassFilter(input)
            highPassFilter?.cutoffFrequency = AUValue(adjustedLowFreq)
            highPassFilter?.resonance = AUValue(1.0)
            
            lowPassFilter = LowPassFilter(highPassFilter!)
            lowPassFilter?.cutoffFrequency = AUValue(highFreq)
            lowPassFilter?.resonance = AUValue(0.5)
            
            secondaryLowPassFilter = LowPassFilter(lowPassFilter!)
            secondaryLowPassFilter?.cutoffFrequency = AUValue(120.0)
            secondaryLowPassFilter?.resonance = AUValue(0.3)
            
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
        secondaryLowPassFilter = nil
        lowPassFilter = nil
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
    
    func forceBuiltInMicrophone() throws {
        let session = AVAudioSession.sharedInstance()
        let availableInputs = session.availableInputs ?? []

        print("🎤 Available audio inputs:")
        for input in availableInputs {
            print("Input portType: \(input.portType.rawValue), portName: \(input.portName)")

            if let dataSources = input.dataSources, !dataSources.isEmpty {
                print("Data sources for \(input.portName):")
                for dataSource in dataSources {
                    print("    • \(dataSource.dataSourceName)")
                }
            } else {
                print("No data sources found for \(input.portName)")
            }
        }

        for input in availableInputs where input.portType == .builtInMic {
            try session.setPreferredInput(input)
            
            if let dataSources = input.dataSources {
                for dataSource in dataSources where dataSource.dataSourceName.lowercased().contains("bottom") {
                    print("✅ Setting preferred data source: \(dataSource.dataSourceName)")
                    try input.setPreferredDataSource(dataSource)
                    break
                }
            }
            return
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
        highPassFilter?.cutoffFrequency = AUValue(lowCutoff)
        lowPassFilter?.cutoffFrequency = AUValue(highCutoff)
    }
    
    func getFilterFrequencies(for mode: HeartbeatFilterMode) -> (Float, Float) {
        switch mode {
        case .standard:
            return (30.0, 100.0)
        case .enhanced:
            return (40.0, 120.0)
        case .sensitive:
            return (25.0, 150.0)
        case .noiseReduced:
            return (50.0, 110.0)
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
        var processedAmplitude = amplitude
        
        if noiseReductionEnabled {
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
        let smoothingFactor: Float = 0.95
        noiseFloor = noiseFloor * smoothingFactor + amplitudeVal * (1.0 - smoothingFactor)
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
        
        let confidence = calculateHeartbeatConfidence(s1: s1Amplitude, s2: s2Amplitude)
        
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
    
    private func calculateHeartbeatConfidence(s1: Float, s2: Float) -> Float {
        let ratio = s2 / max(s1, 0.001)
        let idealRatio: Float = 0.6
        let ratioScore = 1.0 - abs(ratio - idealRatio)
        
        let amplitudeScore = min(1.0, (s1 + s2) / 2.0)
        
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
    
    private func applyNoiseReduction(_ amplitude: Float) -> Float {
        let threshold = noiseFloor * (aggressiveFiltering ? 1.5 : 1.2)
        let reductionFactor: Float = aggressiveFiltering ? 0.2 : 0.3
        
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
        let gain = 1.0 + (error * 0.5)

        let clampedGain = max(minGain, min(maxGain, gain))

        return amplitude * clampedGain
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

