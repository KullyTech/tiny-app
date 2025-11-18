//
//  AudioPostProcessingManager.swift
//  Tiny
//
//  Created by Benedictus Yogatama Favian Satyajati
//

import Foundation
import AVFoundation
import AudioKit
import AudioKitEX
internal import Combine

class AudioPostProcessingManager: ObservableObject {
    private var engine: AudioEngine!
    private var player: AudioPlayer?
    private var parametricEQ: ParametricEQ?
    private var highShelfFilter: HighShelfFilter?
    
    @Published var isPlaying = false
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    
    init() {
        engine = AudioEngine()
    }

    func setupEQChain(input: Node) -> Node {
        let eq = ParametricEQ(input,
                              centerFreq: 200.0,
                              q: 1.70,
                              gain: 20.3)
        self.parametricEQ = eq
        
        let shelf = HighShelfFilter(eq,
                                    cutOffFrequency: 10000.0,
                                    gain: -10.0)
        self.highShelfFilter = shelf
        
        return shelf
    }
    
    func loadAndPlay(fileURL: URL) {
        do {
            stop()
            
            if engine.avEngine.isRunning {
                engine.stop()
            }
            engine = AudioEngine()
            
            player = AudioPlayer(url: fileURL)
            
            guard let player = player else {
                print("Failed to create audio player")
                return
            }
            
            let processedOutput = setupEQChain(input: player)
            
            engine.output = processedOutput

            if let audioFile = try? AVAudioFile(forReading: fileURL) {
                let sampleRate = audioFile.processingFormat.sampleRate
                let frameCount = Double(audioFile.length)
                duration = frameCount / sampleRate
            }

            player.completionHandler = { [weak self] in
                DispatchQueue.main.async {
                    self?.isPlaying = false
                    self?.currentTime = 0
                }
            }

            try engine.start()
            player.play()
            isPlaying = true
  
            startTimeTracking()
            
            print("✅ Audio playback started with EQ processing")
            print("📊 EQ Settings Applied:")
            print("   • 200 Hz boost: +\(parametricEQ?.gain ?? 0) dB (Q: \(parametricEQ?.q ?? 0), Freq: \(parametricEQ?.centerFreq ?? 0) Hz)")
            print("   • 10 kHz shelf: \(highShelfFilter?.gain ?? 0) dB (Cutoff: \(highShelfFilter?.cutOffFrequency ?? 0) Hz)")
            
        } catch {
            print("❌ Error loading audio: \(error.localizedDescription)")
        }
    }
    
    private func startTimeTracking() {
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] timer in
            guard let self = self, let player = self.player else {
                timer.invalidate()
                return
            }
            
            if !self.isPlaying {
                timer.invalidate()
                return
            }
            
            DispatchQueue.main.async {
                if self.isPlaying {
                    self.currentTime += 0.1
                    if self.currentTime >= self.duration {
                        self.currentTime = self.duration
                    }
                }
            }
        }
    }
    
    func pause() {
        player?.pause()
        isPlaying = false
    }
    
    func resume() {
        player?.play()
        isPlaying = true
    }
    
    func stop() {
        player?.stop()
        if engine.avEngine.isRunning {
            engine.stop()
        }
        isPlaying = false
        currentTime = 0
    }
    
    func seek(to time: TimeInterval) {
        currentTime = time
    }
    
    func exportProcessedAudio(inputURL: URL, outputURL: URL, completion: @escaping (Result<URL, Error>) -> Void) {
        print("⚠️ Export feature not yet implemented")
        completion(.failure(NSError(domain: "AudioPostProcessing", code: -1, userInfo: [NSLocalizedDescriptionKey: "Export not implemented"])))
    }
    
    deinit {
        stop()
    }
}
