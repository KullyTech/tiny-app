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

class HeartbeatSoundManager: NSObject, ObservableObject {
    var engine: AudioEngine!
    var mic: AudioEngine.InputNode?
    var highPassFilter: HighPassFilter?
    var lowPassFilter: LowPassFilter?
    var gain: Fader?
    var mixer: Mixer?
    var amplitudeTap: AmplitudeTap?
    
    @Published var isPlaying = false
    @Published var isRunning = false
    @Published var frequencyVal: Float = 0.0
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
            highPassFilter?.cutoffFrequency = AUValue(40.0)  // Increased from 20.0 to reduce bass
            
            lowPassFilter = LowPassFilter(highPassFilter!)
            lowPassFilter?.cutoffFrequency = AUValue(200.0)  // Increased from 50.0 for more clarity
            
            gain = Fader(lowPassFilter!)
            gain?.gain = AUValue(gainVal)
            
            mixer = Mixer(gain!)
            engine.output = mixer
            
            amplitudeTap = AmplitudeTap(gain!) { [weak self] amp in
                DispatchQueue.main.async {
                    self?.amplitudeVal = amp
                }
            }
        } catch {
            print("Error setting up audio!: \(error.localizedDescription)")
        }
    }
    
    private func cleanupAudio() {
        amplitudeTap?.stop()
        amplitudeTap = nil
        
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
        
        for input in availableInputs {
            if input.portType == .builtInMic {
                try session.setPreferredInput(input)
                
                if let dataSources = input.dataSources {
                    for dataSource in dataSources {
                        if dataSource.dataSourceName.lowercased().contains("bottom") {
                            try input.setPreferredDataSource(dataSource)
                            break
                        }
                    }
                }
                return
            }
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
    
    func start() {
        resetEngine()
        setupAudio()
        
        do {
            try engine.start()
            amplitudeTap?.start()
            isRunning = true
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
