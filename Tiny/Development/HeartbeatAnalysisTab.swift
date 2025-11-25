//
//  HeartbeatAnalysisTab.swift
//  Tiny
//
//  Created by Destu Cikal Ramdani on 12/11/25.
//

// Testing TestFlight CI/CD Pipeline

import SwiftUI

struct HeartbeatAnalysisTab: View {
    @StateObject private var manager = HeartbeatSoundManager()
    @State private var selectedTab: AnalysisTab = .overview
    
    enum AnalysisTab: String, CaseIterable {
        case overview = "Overview"
        case detailed = "Detailed"
        case trends = "Trends"
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Tab Selector
                Picker("Analysis Tab", selection: $selectedTab) {
                    ForEach(AnalysisTab.allCases, id: \.self) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                // Content based on selected tab
                TabView(selection: $selectedTab) {
                    overviewView.tag(AnalysisTab.overview)
                    detailedAnalysisView.tag(AnalysisTab.detailed)
                    trendsView.tag(AnalysisTab.trends)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
            .navigationBarTitle("Heartbeat Analysis", displayMode: .large)
        }
    }
    
    private var overviewView: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Current Status Card
                VStack(spacing: 12) {
                    Text("Current Status")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 20) {
                        VStack {
                            Text(String(format: "%.0f", manager.currentBPM))
                                .font(.system(size: 36, weight: .bold, design: .rounded))
                                .foregroundColor(manager.currentBPM > 0 ? .primary : .secondary)
                            Text("BPM")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Divider()
                            .frame(height: 40)
                        
                        VStack {
                            Text("\(manager.heartbeatData.count)")
                                .font(.system(size: 36, weight: .bold, design: .rounded))
                                .foregroundColor(.primary)
                            Text("Samples")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if let latest = manager.heartbeatData.last {
                        HStack {
                            Text("Last Detection")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(latest.timestamp, style: .time)
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(15)
                
                // Quick Stats
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                    QuickStatCard(title: "Signal Quality", value: "\(Int(manager.signalQuality * 100))%", color: qualityColor(manager.signalQuality))
                    QuickStatCard(title: "Filter Mode", value: manager.filterMode.displayName, color: .blue)
                    QuickStatCard(title: "Noise Floor", value: String(format: "%.3f", manager.noiseFloor), color: .orange)
                    QuickStatCard(title: "Amplitude", value: String(format: "%.3f", manager.amplitudeVal), color: .purple)
                }
                
                // Recent Detections
                if !manager.heartbeatData.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Recent Detections")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        LazyVStack(spacing: 8) {
                            ForEach(Array(manager.heartbeatData.suffix(5).reversed()), id: \.timestamp) { data in
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(String(format: "%.0f BPM", data.bpm))
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                        Text(data.timestamp, style: .time)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    HStack(spacing: 8) {
                                        Circle()
                                            .fill(Color.green)
                                            .frame(width: 8, height: 8)
                                        Text("S1: \(String(format: "%.2f", data.s1Amplitude))")
                                            .font(.caption2)
                                        
                                        Circle()
                                            .fill(Color.blue)
                                            .frame(width: 8, height: 8)
                                        Text("S2: \(String(format: "%.2f", data.s2Amplitude))")
                                            .font(.caption2)
                                    }
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color.gray.opacity(0.05))
                                .cornerRadius(8)
                            }
                        }
                    }
                }
            }
            .padding()
        }
    }
    
    private var detailedAnalysisView: some View {
        HeartbeatDataAnalysisView(
            heartbeatData: $manager.heartbeatData,
            currentBPM: $manager.currentBPM
        )
    }
    
    private var trendsView: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Heart Rate Trend Chart
                VStack(alignment: .leading, spacing: 12) {
                    Text("Heart Rate Trends")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    if manager.heartbeatData.count > 1 {
                        // Simple trend visualization
                        VStack(spacing: 8) {
                            HStack {
                                Text("Average")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(String(format: "%.1f BPM", averageBPM))
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                            
                            HStack {
                                Text("Range")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(String(format: "%.0f - %.0f BPM", minBPM, maxBPM))
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                            
                            HStack {
                                Text("Variability")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(String(format: "%.1f BPM", bpmVariability))
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                        }
                        .padding()
                        .background(Color.gray.opacity(0.05))
                        .cornerRadius(8)
                    } else {
                        Text("Insufficient data for trend analysis")
                            .foregroundColor(.secondary)
                            .padding()
                    }
                }
                
                // Signal Quality Trends
                VStack(alignment: .leading, spacing: 12) {
                    Text("Signal Quality Trends")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    if !manager.heartbeatData.isEmpty {
                        let highQualityCount = manager.heartbeatData.filter { $0.confidence > 0.7 }.count
                        let qualityPercentage = Double(highQualityCount) / Double(manager.heartbeatData.count) * 100
                        
                        VStack(spacing: 8) {
                            HStack {
                                Text("High Quality Detections")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text("\(highQualityCount)/\(manager.heartbeatData.count) (\(Int(qualityPercentage))%)")
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                            
                            ProgressView(value: qualityPercentage / 100.0, total: 1.0)
                                .progressViewStyle(
                                    LinearProgressViewStyle(
                                    tint: qualityPercentage > 70 ?
                                        .green : qualityPercentage > 40 ?
                                        .yellow : .red
                                    )
                                )
                        }
                        .padding()
                        .background(Color.gray.opacity(0.05))
                        .cornerRadius(8)
                    }
                }
                
                // S1/S2 Ratio Trends
                VStack(alignment: .leading, spacing: 12) {
                    Text("Heart Sound Analysis")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    if !manager.heartbeatData.isEmpty {
                        let avgS1 = manager.heartbeatData.map(\.s1Amplitude).reduce(0, +) / Float(manager.heartbeatData.count)
                        let avgS2 = manager.heartbeatData.map(\.s2Amplitude).reduce(0, +) / Float(manager.heartbeatData.count)
                        let ratio = avgS1 / max(avgS2, 0.001)
                        
                        VStack(spacing: 8) {
                            HStack {
                                Text("Average S1 Amplitude")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(String(format: "%.3f", avgS1))
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.green)
                            }
                            
                            HStack {
                                Text("Average S2 Amplitude")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(String(format: "%.3f", avgS2))
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.blue)
                            }
                            
                            HStack {
                                Text("S1/S2 Ratio")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(String(format: "%.2f", ratio))
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                        }
                        .padding()
                        .background(Color.gray.opacity(0.05))
                        .cornerRadius(8)
                    }
                }
            }
            .padding()
        }
    }
    
    private var averageBPM: Double {
        guard !manager.heartbeatData.isEmpty else { return 0 }
        return manager.heartbeatData.map(\.bpm).reduce(0, +) / Double(manager.heartbeatData.count)
    }
    
    private var minBPM: Double {
        manager.heartbeatData.map(\.bpm).min() ?? 0
    }
    
    private var maxBPM: Double {
        manager.heartbeatData.map(\.bpm).max() ?? 0
    }
    
    private var bpmVariability: Double {
        guard manager.heartbeatData.count > 1 else { return 0 }
        let avg = averageBPM
        let variance = manager.heartbeatData.map { pow($0.bpm - avg, 2) }.reduce(0, +) / Double(manager.heartbeatData.count)
        return sqrt(variance)
    }
    
    private func qualityColor(_ quality: Float) -> Color {
        if quality < 0.3 {
            return .red
        } else if quality < 0.7 {
            return .yellow
        } else {
            return .green
        }
    }
}

struct QuickStatCard: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
    }
}

#Preview {
    HeartbeatAnalysisTab()
}
