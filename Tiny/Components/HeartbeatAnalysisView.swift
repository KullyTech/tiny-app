//
//  HeartbeatAnalysisView.swift
//  Tiny
//
//  Created by Destu Cikal Ramdani on 12/11/25.
//

import SwiftUI

struct HeartbeatAnalysisView: View {
    @Binding var heartbeatData: [HeartbeatData]
    @Binding var currentBPM: Double
    @Binding var filterMode: HeartbeatFilterMode
    let onFilterModeChange: (HeartbeatFilterMode) -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            bpmDisplay
            filterModeSelector
            heartbeatHistory
            signalAnalysis
        }
        .padding()
    }
    
    private var bpmDisplay: some View {
        VStack(spacing: 8) {
            Text("Heart Rate")
                .font(.headline)
                .foregroundColor(.primary)
            
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(String(format: "%.0f", currentBPM))
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(currentBPM > 0 ? .primary : .secondary)
                
                Text("BPM")
                    .font(.title2)
                    .foregroundColor(.secondary)
            }
            
            if currentBPM > 0 {
                Text(heartRateStatus)
                    .font(.caption)
                    .foregroundColor(statusColor)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(statusColor.opacity(0.1))
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var filterModeSelector: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Filter Mode")
                .font(.headline)
                .foregroundColor(.primary)
            
            HStack(spacing: 12) {
                ForEach(HeartbeatFilterMode.allCases, id: \.self) { mode in
                    Button(action: {
                        onFilterModeChange(mode)
                    }) {
                        VStack(spacing: 4) {
                            Text(mode.displayName)
                                .font(.caption)
                                .fontWeight(.medium)
                            
                            Text(mode.frequencyRange)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(filterMode == mode ? Color.blue : Color.gray.opacity(0.2))
                        .foregroundColor(filterMode == mode ? .white : .primary)
                        .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
    
    private var heartbeatHistory: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Recent Detections")
                .font(.headline)
                .foregroundColor(.primary)
            
            if heartbeatData.isEmpty {
                Text("No heartbeat detected yet")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                LazyVStack(spacing: 4) {
                    ForEach(Array(heartbeatData.suffix(5).reversed()), id: \.timestamp) { data in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(String(format: "%.0f BPM", data.bpm))
                                    .font(.caption)
                                    .fontWeight(.medium)
                                
                                Text(data.timestamp, style: .time)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 2) {
                                HStack(spacing: 4) {
                                    Circle()
                                        .fill(Color.green)
                                        .frame(width: 6, height: 6)
                                    Text("S1: \(String(format: "%.2f", data.s1Amplitude))")
                                        .font(.caption2)
                                }
                                
                                HStack(spacing: 4) {
                                    Circle()
                                        .fill(Color.blue)
                                        .frame(width: 6, height: 6)
                                    Text("S2: \(String(format: "%.2f", data.s2Amplitude))")
                                        .font(.caption2)
                                }
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.gray.opacity(0.05))
                        .cornerRadius(6)
                    }
                }
            }
        }
    }
    
    private var signalAnalysis: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Signal Analysis")
                .font(.headline)
                .foregroundColor(.primary)
            
            if let latest = heartbeatData.last {
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Confidence")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(Int(latest.confidence * 100))%")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(confidenceColor(latest.confidence))
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("S1/S2 Ratio")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(String(format: "%.2f", latest.s1Amplitude / max(latest.s2Amplitude, 0.001)))
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                    }
                    
                    Spacer()
                }
                .padding()
                .background(Color.gray.opacity(0.05))
                .cornerRadius(8)
            }
        }
    }
    
    private var heartRateStatus: String {
        switch currentBPM {
        case 0:
            return "No detection"
        case 60..<80:
            return "Normal"
        case 80..<100:
            return "Elevated"
        case 100...:
            return "High"
        default:
            return "Low"
        }
    }
    
    private var statusColor: Color {
        switch currentBPM {
        case 0:
            return .gray
        case 60..<80:
            return .green
        case 80..<100:
            return .yellow
        case 100...:
            return .red
        default:
            return .blue
        }
    }
    
    private func confidenceColor(_ confidence: Float) -> Color {
        if confidence < 0.3 {
            return .red
        } else if confidence < 0.7 {
            return .yellow
        } else {
            return .green
        }
    }
}

extension HeartbeatFilterMode: CaseIterable {
    static var allCases: [HeartbeatFilterMode] {
        [.standard, .enhanced, .sensitive, .noiseReduced]
    }
    
    var displayName: String {
        switch self {
        case .standard:
            return "Standard"
        case .enhanced:
            return "Enhanced"
        case .sensitive:
            return "Sensitive"
        case .noiseReduced:
            return "Noise Reduced"
        }
    }
    
    var frequencyRange: String {
        switch self {
        case .standard:
            return "30-100Hz"
        case .enhanced:
            return "40-120Hz"
        case .sensitive:
            return "25-150Hz"
        case .noiseReduced:
            return "50-110Hz"
        }
    }
}

#Preview {
    @State var heartbeatData: [HeartbeatData] = [
        HeartbeatData(timestamp: Date(), bpm: 72, s1Amplitude: 0.8, s2Amplitude: 0.5, confidence: 0.85),
        HeartbeatData(timestamp: Date().addingTimeInterval(-1), bpm: 74, s1Amplitude: 0.7, s2Amplitude: 0.4, confidence: 0.75)
    ]
    @State var currentBPM: Double = 72
    @State var filterMode: HeartbeatFilterMode = .standard
    
    return HeartbeatAnalysisView(
        heartbeatData: $heartbeatData,
        currentBPM: $currentBPM,
        filterMode: $filterMode,
        onFilterModeChange: { mode in
            filterMode = mode
        }
    )
}