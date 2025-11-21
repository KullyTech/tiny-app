//
//  HeartbeatDetector.swift
//  Tiny
//
//  Created by Benedictus Yogatama Favian Satyajati on 30/10/25.
//

import Foundation
import Accelerate

class HeartbeatDetector {
    private var heartbeatData: [HeartbeatData] = []
    private var recentPeaks: [Date] = []
    private var sampleRate: Float
    private var fftSize: Int = 0

    // Configuration for different use cases
    enum DetectionMode {
        case live      // Real-time microphone input
        case playback  // Recorded audio playback
    }

    private let mode: DetectionMode

    // Configurable parameters based on mode
    private var confidenceThreshold: Float
    private var peakThreshold: Float

    private let s1FreqRange: ClosedRange<Float> = 20.0...150.0  // Hz
    private let s2FreqRange: ClosedRange<Float> = 80.0...200.0  // Hz
    private let minTimeBetweenBeats: TimeInterval = 0.3  // 200 BPM max
    private let maxTimeBetweenBeats: TimeInterval = 2.0  // 30 BPM min

    // Peak detection state
    private var lastPeakTime: Date?
    private var peakBuffer: [Float] = []
    private let peakBufferSize = 5

    // Initializer with configurable parameters
    init(sampleRate: Float = 44100.0, mode: DetectionMode = .live) {
        self.sampleRate = sampleRate
        self.mode = mode

        // Adjust thresholds based on mode
        switch mode {
        case .live:
            // More sensitive for live detection (microphone may have more noise)
            self.confidenceThreshold = 0.40
            self.peakThreshold = 0.18
        case .playback:
            // More precise for playback (cleaner signal)
            self.confidenceThreshold = 0.25
            self.peakThreshold = 0.10
        }
    }

    func detectHeartbeat(from fftData: [Float]) -> HeartbeatData? {
        guard !fftData.isEmpty else { return nil }

        // Initialize FFT size on first run
        if fftSize == 0 {
            fftSize = fftData.count
        }

        // Convert frequency ranges to FFT bin ranges
        let s1BinRange = frequencyToBinRange(s1FreqRange, fftSize: fftSize, sampleRate: sampleRate)
        let s2BinRange = frequencyToBinRange(s2FreqRange, fftSize: fftSize, sampleRate: sampleRate)

        // Calculate amplitudes with proper normalization
        let s1Amplitude = calculatePeakAmplitude(in: s1BinRange, from: fftData)
        let s2Amplitude = calculatePeakAmplitude(in: s2BinRange, from: fftData)

        // Calculate total energy in heartbeat frequency range
        let totalEnergy = calculateAverageAmplitude(in: s1BinRange.lowerBound...s2BinRange.upperBound, from: fftData)

        // Detect peaks in the signal
        let isPeak = detectPeak(amplitude: s1Amplitude)

        // Calculate confidence based on multiple factors
        let confidence = calculateEnhancedConfidence(
            s1Amplitude: s1Amplitude,
            s2Amplitude: s2Amplitude,
            totalEnergy: totalEnergy,
            isPeak: isPeak
        )

        // Only register heartbeat if confidence is high enough and it's a peak
        if confidence > confidenceThreshold && isPeak {
            let now = Date()

            // Check timing constraint to avoid double-counting
            if let lastPeak = lastPeakTime {
                let interval = now.timeIntervalSince(lastPeak)
                if interval < minTimeBetweenBeats {
                    return nil  // Too soon, likely noise or double detection
                }
            }

            lastPeakTime = now
            recentPeaks.append(now)

            // Keep only recent peaks for BPM calculation
            let cutoffTime = now.addingTimeInterval(-10.0)
            recentPeaks.removeAll { $0 < cutoffTime }

            let bpm = estimateBPM()

            let heartbeat = HeartbeatData(
                timestamp: now,
                bpm: bpm,
                s1Amplitude: s1Amplitude,
                s2Amplitude: s2Amplitude,
                confidence: confidence
            )

            heartbeatData.append(heartbeat)
            if heartbeatData.count > 20 {
                heartbeatData.removeFirst()
            }

            return heartbeat
        }

        return nil
    }

    // Convert frequency range to FFT bin range
    private func frequencyToBinRange(_ freqRange: ClosedRange<Float>, fftSize: Int, sampleRate: Float) -> ClosedRange<Int> {
        let binWidth = sampleRate / Float(fftSize * 2)
        let lowerBin = Int(freqRange.lowerBound / binWidth)
        let upperBin = Int(freqRange.upperBound / binWidth)
        return max(0, lowerBin)...min(fftSize - 1, upperBin)
    }

    // Calculate peak amplitude (max value) in range
    private func calculatePeakAmplitude(in range: ClosedRange<Int>, from fftData: [Float]) -> Float {
        guard fftData.count > range.upperBound else { return 0.0 }

        let startIndex = max(0, range.lowerBound)
        let endIndex = min(fftData.count, range.upperBound + 1)

        guard startIndex < endIndex else { return 0.0 }

        let slice = fftData[startIndex..<endIndex]
        return slice.max() ?? 0.0
    }

    // Calculate average amplitude in range
    private func calculateAverageAmplitude(in range: ClosedRange<Int>, from fftData: [Float]) -> Float {
        guard fftData.count > range.upperBound else { return 0.0 }

        let startIndex = max(0, range.lowerBound)
        let endIndex = min(fftData.count, range.upperBound + 1)

        guard startIndex < endIndex else { return 0.0 }

        let slice = fftData[startIndex..<endIndex]
        return slice.reduce(0, +) / Float(slice.count)
    }

    // Detect if current amplitude is a peak
    private func detectPeak(amplitude: Float) -> Bool {
        peakBuffer.append(amplitude)
        if peakBuffer.count > peakBufferSize {
            peakBuffer.removeFirst()
        }

        guard peakBuffer.count == peakBufferSize else { return false }

        // Check if middle value is a local maximum
        let middleIndex = peakBufferSize / 2
        let middleValue = peakBuffer[middleIndex]

        // Must exceed threshold
        guard middleValue > peakThreshold else { return false }

        // Must be higher than neighbors
        for (index, value) in peakBuffer.enumerated() {
            if index != middleIndex && value >= middleValue {
                return false
            }
        }

        return true
    }

    // Enhanced confidence calculation
    private func calculateEnhancedConfidence(
        s1Amplitude: Float,
        s2Amplitude: Float,
        totalEnergy: Float,
        isPeak: Bool
    ) -> Float {
        // 1. Amplitude strength (0.0 - 1.0)
        let amplitudeStrength = min(1.0, s1Amplitude * 5.0)

        // 2. S1/S2 ratio score (S1 should be stronger than S2)
        let ratio = s2Amplitude / max(s1Amplitude, 0.001)
        let idealRatio: Float = 0.5  // S2 is typically 50% of S1
        let ratioScore = max(0.0, 1.0 - abs(ratio - idealRatio) * 2.0)

        // 3. Energy concentration (heartbeat energy should be concentrated in expected range)
        let energyScore = min(1.0, totalEnergy * 3.0)

        // 4. Peak bonus
        let peakBonus: Float = isPeak ? 0.2 : 0.0

        // Weighted combination
        let confidence = (
            amplitudeStrength * 0.35 +
            ratioScore * 0.25 +
            energyScore * 0.20 +
            peakBonus
        )

        return min(1.0, confidence)
    }

    // Improved BPM estimation using inter-beat intervals
    private func estimateBPM() -> Double {
        guard recentPeaks.count >= 2 else { return 0.0 }

        // Calculate intervals between consecutive peaks
        var intervals: [TimeInterval] = []
        for index in 1..<recentPeaks.count {
            let interval = recentPeaks[index].timeIntervalSince(recentPeaks[index - 1])
            // Filter out unrealistic intervals
            if interval >= minTimeBetweenBeats && interval <= maxTimeBetweenBeats {
                intervals.append(interval)
            }
        }

        guard !intervals.isEmpty else { return 0.0 }

        // Use median instead of mean for better outlier resistance
        let sortedIntervals = intervals.sorted()
        let medianInterval: TimeInterval

        if sortedIntervals.count % 2 == 0 {
            let mid = sortedIntervals.count / 2
            medianInterval = (sortedIntervals[mid - 1] + sortedIntervals[mid]) / 2.0
        } else {
            medianInterval = sortedIntervals[sortedIntervals.count / 2]
        }

        // Convert interval to BPM
        let bpm = 60.0 / medianInterval

        // Clamp to realistic range
        return max(30.0, min(200.0, bpm))
    }

    // Get recent heartbeat statistics
    func getHeartbeatStats() -> (avgBPM: Double, confidence: Float, beatCount: Int) {
        guard !heartbeatData.isEmpty else { return (0.0, 0.0, 0) }

        let recentData = Array(heartbeatData.suffix(10))
        let avgBPM = recentData.map { $0.bpm }.reduce(0, +) / Double(recentData.count)
        let avgConfidence = recentData.map { $0.confidence }.reduce(0, +) / Float(recentData.count)

        return (avgBPM, avgConfidence, recentPeaks.count)
    }

    // Reset detector state
    func reset() {
        heartbeatData.removeAll()
        recentPeaks.removeAll()
        lastPeakTime = nil
        peakBuffer.removeAll()
    }
}
