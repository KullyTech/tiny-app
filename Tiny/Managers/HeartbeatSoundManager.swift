//
//  HeartbeatSoundManager.swift
//  Tiny
//
//  Created by Benedictus Yogatama Favian Satyajati on 30/10/25.
//

import Foundation
import AVFoundation

import AudioKit
import AudioKitEX

import Combine

struct Recording: Identifiable, Equatable {
    let id = UUID()
    let fileURL: URL
    var isPlaying: Bool = false
}

class HeartbeatSoundManager: NSObject, ObservableObject {
    var engine: AudioEngine!
    var mic: AudioEngine.InputNode?
    var highPassFilter: HighPassFilter?
    var lowPassFilter: LowPassFilter?
    var gain: Fader?
    var mixer: Mixer?
    var amplitudeTap: AmplitudeTap?
    var recorder: NodeRecorder?
    var player: AudioPlayer?
    
    @Published var isPlaying = false
    @Published var isRunning = false
    @Published var isRecording = false
    @Published var lastRecording: Recording?
    @Published var isPlayingPlayback = false
    @Published var amplitudeVal: Float = 0.0
    @Published var gainVal: Float = 10.0
    
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
            
            highPassFilter = HighPassFilter(input)
            highPassFilter?.cutoffFrequency = AUValue(40.0)
            
            lowPassFilter = LowPassFilter(highPassFilter!)
            lowPassFilter?.cutoffFrequency = AUValue(200.0)
            
            gain = Fader(lowPassFilter!)
            gain?.gain = AUValue(gainVal)
            
            mixer = Mixer(gain!)
            
            amplitudeTap = AmplitudeTap(mixer!) { [weak self] amp in
                DispatchQueue.main.async {
                    print("Amplitude value: \(amp)")
                    self?.amplitudeVal = amp
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
            print("Amplitude tap started")
            
        } catch {
            print("Error setting up audio!: \(error.localizedDescription)")
        }
    }
    
    private func cleanupAudio() {
        amplitudeTap?.stop()
        amplitudeTap = nil
        
        recorder?.stop()
        recorder = nil
        
        if engine.avEngine.isRunning {
            engine.stop()
        }

        mixer = nil
        gain = nil
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
        
        for input in availableInputs where input.portType == .builtInMic {
            try session.setPreferredInput(input)
            
            if let dataSources = input.dataSources {
                for dataSource in dataSources where dataSource.dataSourceName.lowercased().contains("bottom") {
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
