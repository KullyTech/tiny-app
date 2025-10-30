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
    let engine = AudioEngine()
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
    @Published var gainVal: Float = 0.0
    
    override init() {
        super.init()
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
            let session = AVAudioSession.sharedInstance()
            
            try session.setCategory(.playAndRecord, mode: .measurement, options: [.allowBluetoothHFP, .allowBluetoothA2DP])
            try forceBuiltInMicrophone()
            try session.setActive(true)
            
            guard let input = engine.input else {
                print("No input available!")
                return
            }
            
            mic = input
            
//            let currentRoute = session.currentRoute
            
            highPassFilter = HighPassFilter(input)
            highPassFilter?.cutoffFrequency = AUValue(20.0)
            
            lowPassFilter = LowPassFilter(highPassFilter!)
            lowPassFilter?.cutoffFrequency = AUValue(50.0)
            
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
}
