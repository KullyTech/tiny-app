//
//  HeartbeatDataAnalysisView.swift
//  Tiny
//
//  Created by Destu Cikal Ramdani on 12/11/25.
//

import SwiftUI
import Charts

struct HeartbeatDataAnalysisView: View {
    @Binding var heartbeatData: [HeartbeatData]
    @Binding var currentBPM: Double
    @State private var selectedTimeRange: TimeRange = .lastMinute
    
    enum TimeRange: String, CaseIterable {
        case lastMinute = "1 Min"
        case last5Minutes = "5 Min"
        case last15Minutes = "15 Min"
        case all = "All"
        
        var timeInterval: TimeInterval {
            switch self {
            case .lastMinute: return 60
            case .last5Minutes: return 300
            case .last15Minutes: return 900
            case .all: return .infinity
            }
        }
    }
    
    var filteredData: [HeartbeatData] {
        guard selectedTimeRange != .all else { return heartbeatData }
        
        let cutoffDate = Date().addingTimeInterval(-selectedTimeRange.timeInterval)
        return heartbeatData.filter { $0.timestamp >= cutoffDate }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                timeRangeSelector
                bpmChart
                statisticsGrid
                confidenceAnalysis
                s1s2Analysis
                exportOptions
            }
            .padding()
        }
    }
    
    private var timeRangeSelector: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Time Range")
                .font(.headline)
                .foregroundColor(.primary)
            
            HStack {
                ForEach(TimeRange.allCases, id: \.self) { range in
                    Button(action: {
                        selectedTimeRange = range
                    }) {
                        Text(range.rawValue)
                            .font(.caption)
                            .fontWeight(.medium)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(selectedTimeRange == range ? Color.blue : Color.gray.opacity(0.2))
                            .foregroundColor(selectedTimeRange == range ? .white : .primary)
                            .cornerRadius(6)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
    
    private var bpmChart: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Heart Rate Trend")
                .font(.headline)
                .foregroundColor(.primary)
            
            if filteredData.count > 1 {
                Chart {
                    ForEach(Array(filteredData.enumerated()), id: \.offset) { index, data in
                        LineMark(
                            x: .value("Time", data.timestamp),
                            y: .value("BPM", data.bpm)
                        )
                        .foregroundStyle(Color.blue)
                        .interpolationMethod(.catmullRom)
                        
                        PointMark(
                            x: .value("Time", data.timestamp),
                            y: .value("BPM", data.bpm)
                        )
                        .foregroundStyle(Color.blue)
                        .symbolSize(30)
                    }
                }
                .frame(height: 200)
                .chartXAxis {
                    AxisMarks(values: .automatic) { value in
                        AxisGridLine()
                        AxisValueLabel(format: .dateTime.hour().minute())
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisGridLine()
                        AxisValueLabel("\(Int(value.as(Double.self)!))")
                    }
                }
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.1))
                    .frame(height: 200)
                    .overlay(
                        Text("Insufficient data for chart")
                            .foregroundColor(.secondary)
                    )
            }
        }
    }
    
    private var statisticsGrid: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Statistics")
                .font(.headline)
                .foregroundColor(.primary)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                StatCard(title: "Average BPM", value: String(format: "%.1f", averageBPM), color: .blue)
                StatCard(title: "Min BPM", value: String(format: "%.0f", minBPM), color: .green)
                StatCard(title: "Max BPM", value: String(format: "%.0f", maxBPM), color: .red)
                StatCard(title: "Samples", value: "\(filteredData.count)", color: .purple)
            }
        }
    }
    
    private var confidenceAnalysis: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Detection Confidence")
                .font(.headline)
                .foregroundColor(.primary)
            
            if !filteredData.isEmpty {
                VStack(spacing: 8) {
                    HStack {
                        Text("Average Confidence")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(Int(averageConfidence * 100))%")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    
                    ProgressView(value: averageConfidence, total: 1.0)
                        .progressViewStyle(LinearProgressViewStyle(tint: confidenceColor(averageConfidence)))
                    
                    HStack {
                        Text("High Quality Detections")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(highQualityCount)/\(filteredData.count)")
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
    
    private var s1s2Analysis: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("S1/S2 Heart Sound Analysis")
                .font(.headline)
                .foregroundColor(.primary)
            
            if !filteredData.isEmpty {
                VStack(spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("S1 (Lub) Average")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(String(format: "%.3f", averageS1Amplitude))
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(.green)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("S2 (Dub) Average")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(String(format: "%.3f", averageS2Amplitude))
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(.blue)
                        }
                    }
                    
                    HStack {
                        Text("S1/S2 Ratio")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(String(format: "%.2f", s1s2Ratio))
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                    }
                    
                    ProgressView(value: min(s1s2Ratio, 2.0), total: 2.0)
                        .progressViewStyle(LinearProgressViewStyle(tint: .orange))
                }
                .padding()
                .background(Color.gray.opacity(0.05))
                .cornerRadius(8)
            }
        }
    }
    
    private var exportOptions: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Export Data")
                .font(.headline)
                .foregroundColor(.primary)
            
            HStack(spacing: 12) {
                Button("Export CSV") {
                    exportToCSV()
                }
                .buttonStyle(.bordered)
                
                Button("Share Report") {
                    shareReport()
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }
    
    private var averageBPM: Double {
        guard !filteredData.isEmpty else { return 0 }
        return filteredData.map(\.bpm).reduce(0, +) / Double(filteredData.count)
    }
    
    private var minBPM: Double {
        filteredData.map(\.bpm).min() ?? 0
    }
    
    private var maxBPM: Double {
        filteredData.map(\.bpm).max() ?? 0
    }
    
    private var averageConfidence: Float {
        guard !filteredData.isEmpty else { return 0 }
        return filteredData.map(\.confidence).reduce(0, +) / Float(filteredData.count)
    }
    
    private var highQualityCount: Int {
        filteredData.filter { $0.confidence > 0.7 }.count
    }
    
    private var averageS1Amplitude: Float {
        guard !filteredData.isEmpty else { return 0 }
        return filteredData.map(\.s1Amplitude).reduce(0, +) / Float(filteredData.count)
    }
    
    private var averageS2Amplitude: Float {
        guard !filteredData.isEmpty else { return 0 }
        return filteredData.map(\.s2Amplitude).reduce(0, +) / Float(filteredData.count)
    }
    
    private var s1s2Ratio: Float {
        guard averageS2Amplitude > 0 else { return 0 }
        return averageS1Amplitude / averageS2Amplitude
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
    
    private func exportToCSV() {
        let csvString = generateCSVString()
        let fileName = "heartbeat_data_\(Date().timeIntervalSince1970).csv"
        
        guard let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        let fileURL = documentsURL.appendingPathComponent(fileName)
        
        do {
            try csvString.write(to: fileURL, atomically: true, encoding: .utf8)
            print("CSV exported to \(fileURL)")
        } catch {
            print("Error exporting CSV: \(error)")
        }
    }
    
    private func generateCSVString() -> String {
        var csv = "Timestamp,BPM,S1_Amplitude,S2_Amplitude,Confidence\n"
        
        for data in filteredData {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            let timestampString = formatter.string(from: data.timestamp)
            
            csv += "\(timestampString),\(data.bpm),\(data.s1Amplitude),\(data.s2Amplitude),\(data.confidence)\n"
        }
        
        return csv
    }
    
    private func shareReport() {
        let report = generateReport()
        print("Report to share: \(report)")
    }
    
    private func generateReport() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium
        
        return """
        Heartbeat Analysis Report
        Generated: \(formatter.string(from: Date()))
        
        Summary:
        - Average BPM: \(String(format: "%.1f", averageBPM))
        - Min/Max BPM: \(String(format: "%.0f", minBPM))/\(String(format: "%.0f", maxBPM))
        - Total Samples: \(filteredData.count)
        - Average Confidence: \(Int(averageConfidence * 100))%
        - S1/S2 Ratio: \(String(format: "%.2f", s1s2Ratio))
        
        Filter Mode: \(selectedTimeRange.rawValue)
        """
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
    }
}

#Preview {
    @State var heartbeatData: [HeartbeatData] = [
        HeartbeatData(timestamp: Date().addingTimeInterval(-300), bpm: 72, s1Amplitude: 0.8, s2Amplitude: 0.5, confidence: 0.85),
        HeartbeatData(timestamp: Date().addingTimeInterval(-240), bpm: 74, s1Amplitude: 0.7, s2Amplitude: 0.4, confidence: 0.75),
        HeartbeatData(timestamp: Date().addingTimeInterval(-180), bpm: 71, s1Amplitude: 0.9, s2Amplitude: 0.6, confidence: 0.90),
        HeartbeatData(timestamp: Date().addingTimeInterval(-120), bpm: 73, s1Amplitude: 0.6, s2Amplitude: 0.3, confidence: 0.65),
        HeartbeatData(timestamp: Date().addingTimeInterval(-60), bpm: 75, s1Amplitude: 0.8, s2Amplitude: 0.5, confidence: 0.80)
    ]
    @State var currentBPM: Double = 75
    
    return HeartbeatDataAnalysisView(
        heartbeatData: $heartbeatData,
        currentBPM: $currentBPM
    )
}