//
//  HeartbeatDetector.swift
//  Tiny
//
//  Created by Benedictus Yogatama Favian Satyajati on 30/10/25.
//

import Foundation

class HeartbeatDetector {
    private var heartbeatData: [HeartbeatData] = []
    
    func detectHeartbeat(from fftData: [Float]) -> HeartbeatData? {
        guard !fftData.isEmpty else { return nil }
        
        let s1Range = 20...50
        let s2Range = 50...80
        
        let s1Amplitude = calculateAverageAmplitude(in: s1Range, from: fftData)
        let s2Amplitude = calculateAverageAmplitude(in: s2Range, from: fftData)
        
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
            
            // Track heartbeat for BPM estimation
            heartbeatData.append(heartbeat)
            if heartbeatData.count > 10 {
                heartbeatData.removeFirst()
            }
            
            return heartbeat
        }
        
        return nil
    }
    
    private func calculateAverageAmplitude(in range: ClosedRange<Int>, from fftData: [Float]) -> Float {
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
}

