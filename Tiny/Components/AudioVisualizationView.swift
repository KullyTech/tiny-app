//
//  AudioVisualizationView.swift
//  Tiny
//
//  Created by Destu Cikal Ramdani on 12/11/25.
//

import SwiftUI

struct AudioVisualizationView: View {
    @Binding var fftData: [Float]
    @Binding var amplitude: Float
    @Binding var signalQuality: Float
    
    private let barCount = 64
    
    var body: some View {
        VStack(spacing: 20) {
            spectrumAnalyzer
            amplitudeIndicator
            signalQualityIndicator
        }
        .padding()
    }
    
    private var spectrumAnalyzer: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Frequency Spectrum")
                .font(.headline)
                .foregroundColor(.primary)
            
            HStack(alignment: .bottom, spacing: 2) {
                ForEach(0..<barCount, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(barColor(for: index))
                        .frame(width: 4, height: barHeight(for: index))
                        .animation(.easeInOut(duration: 0.1), value: fftData)
                }
            }
            .frame(height: 120)
            .frame(maxWidth: .infinity)
            
            HStack {
                Text("20Hz")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Spacer()
                Text("80Hz")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var amplitudeIndicator: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Signal Amplitude")
                .font(.headline)
                .foregroundColor(.primary)
            
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 20)
                
                RoundedRectangle(cornerRadius: 8)
                    .fill(amplitudeColor)
                    .frame(width: amplitudeWidth, height: 20)
                    .animation(.easeInOut(duration: 0.2), value: amplitude)
            }
            
            Text(String(format: "%.2f", amplitude))
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private var signalQualityIndicator: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Signal Quality")
                .font(.headline)
                .foregroundColor(.primary)
            
            HStack {
                ForEach(0..<5, id: \.self) { index in
                    Circle()
                        .fill(index < Int(signalQuality * 5) ? qualityColor : Color.gray.opacity(0.3))
                        .frame(width: 12, height: 12)
                        .animation(.easeInOut(duration: 0.3), value: signalQuality)
                }
                
                Spacer()
                
                Text("\(Int(signalQuality * 100))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private func barColor(for index: Int) -> Color {
        guard index < fftData.count else { return .gray.opacity(0.3) }
        
        let value = fftData[index]
        let normalizedValue = min(1.0, max(0.0, value))
        
        if normalizedValue < 0.3 {
            return .blue.opacity(0.6)
        } else if normalizedValue < 0.7 {
            return .green.opacity(0.7)
        } else {
            return .red.opacity(0.8)
        }
    }
    
    private func barHeight(for index: Int) -> CGFloat {
        guard index < fftData.count else { return 4 }
        
        let value = fftData[index]
        let normalizedValue = min(1.0, max(0.0, value))
        
        return CGFloat(normalizedValue * 120)
    }
    
    private var amplitudeColor: Color {
        let normalizedAmplitude = min(1.0, max(0.0, amplitude / 0.5))
        
        if normalizedAmplitude < 0.3 {
            return .blue
        } else if normalizedAmplitude < 0.7 {
            return .green
        } else {
            return .red
        }
    }
    
    private var amplitudeWidth: CGFloat {
        let normalizedAmplitude = min(1.0, max(0.0, amplitude / 0.5))
        return CGFloat(normalizedAmplitude) * UIScreen.main.bounds.width - 40
    }
    
    private var qualityColor: Color {
        if signalQuality < 0.3 {
            return .red
        } else if signalQuality < 0.7 {
            return .yellow
        } else {
            return .green
        }
    }
}

#Preview {
    @State var fftData = Array(repeating: Float.random(in: 0...1), count: 128)
    @State var amplitude: Float = 0.3
    @State var signalQuality: Float = 0.7
    
    return AudioVisualizationView(
        fftData: $fftData,
        amplitude: $amplitude,
        signalQuality: $signalQuality
    )
}
