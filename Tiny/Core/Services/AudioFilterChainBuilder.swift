//
//  AudioFilterChainBuilder.swift
//  Tiny
//
//  Created by Benedictus Yogatama Favian Satyajati on 30/10/25.
//

import Foundation
import AudioKit
import AudioKitEX

class AudioFilterChainBuilder {
    var highPassFilter: HighPassFilter?
    var lowPassFilter: LowPassFilter?
    var secondaryLowPassFilter: LowPassFilter?
    var bandPassFilter: BandPassFilter?
    var peakLimiter: PeakLimiter?
    var compressor: Compressor?
    
    func setupSpatialAudioChain(input: AudioEngine.InputNode, lowFreq: Float, highFreq: Float) {
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
    
    func setupTraditionalFilterChain(input: AudioEngine.InputNode, lowFreq: Float, highFreq: Float, aggressiveFiltering: Bool) {
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
    
    func updateSpatialAudioChain(_ lowFreq: Float, _ highFreq: Float) {
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
    
    func updateTraditionalFilterChain(_ lowFreq: Float, _ highFreq: Float, aggressiveFiltering: Bool) {
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
}
