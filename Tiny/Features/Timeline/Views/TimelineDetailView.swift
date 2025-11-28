//
//  TimelineDetailView.swift
//  Tiny
//
//  Created by Tm Revanza Narendra Pradipta on 21/11/25.
//

import SwiftUI

struct TimelineDetailView: View {
    let week: WeekSection
    var animation: Namespace.ID // Passed from parent
    let onSelectRecording: (Recording) -> Void
    
    let isMother: Bool
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // 1. Header Area (Title + Hero Orb)
                headerView
                
                // 2. The List of Recordings (Glowing Dots)
                recordingsScrollView(geometry: geometry)
            }
        }
    }
    
    private var headerView: some View {
        VStack(spacing: 50) {
            ZStack {
                // Title
                Text("Week \(week.weekNumber)")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.top, 10)
            }
            .frame(maxWidth: .infinity)
            
        }
    }
    
    private func recordingsScrollView(geometry: GeometryProxy) -> some View {
        let recordings = week.recordings
        let recSpacing: CGFloat = 100
        let recHeight = max(geometry.size.height - 300, CGFloat(recordings.count) * recSpacing + 200)
        
        return ScrollView(showsIndicators: false) {
            // The "Hero" Orb (Animated from previous screen)
            ZStack {
                AnimatedOrbView(size: 115)
                    .shadow(color: .orange.opacity(0.6), radius: 30)
            }
            .matchedGeometryEffect(id: "orb_\(week.weekNumber)", in: animation)
            .frame(height: 115)
            .padding(.vertical, 20)
            
            ZStack(alignment: .top) {
                
                // Tighter Wavy Path for details
                ContinuousWave(
                    totalHeight: recHeight,
                    period: 400, // Faster wave
                    amplitude: 60 // Smaller width
                )
                .stroke(
                    Color.white.opacity(0.15),
                    style: StrokeStyle(lineWidth: 1, lineCap: .round)
                )
                .frame(width: geometry.size.width, height: recHeight)
                
                // Glowing Dots (Recordings)
                ForEach(Array(recordings.enumerated()), id: \.element.id) { index, recording in
                    let yPos: CGFloat = 40 + (CGFloat(index) * recSpacing)
                    let xPos = TimelineLayout.calculateX(
                        yCoor: yPos,
                        width: geometry.size.width,
                        period: 400,
                        amplitude: 60
                    )
                    
                    HStack(spacing: 15) {
                        // Label Left or Right based on X position
                        if xPos > geometry.size.width / 2 {
                            recordingLabel(for: recording)
                            glowingDot
                                .onTapGesture { onSelectRecording(recording) }
                        } else {
                            glowingDot
                                .onTapGesture { onSelectRecording(recording) }
                            recordingLabel(for: recording)
                        }
                    }
                    .frame(width: 300, height: 60)
                    .position(x: xPos, y: yPos)
                }
            }
            .frame(width: geometry.size.width, height: recHeight)
        }
    }
    
    var glowingDot: some View {
        ZStack {
            Circle().fill(Color.white).frame(width: 8, height: 8)
            Circle().stroke(Color.white.opacity(0.5), lineWidth: 1).frame(width: 16, height: 16)
            Circle().fill(Color.white.opacity(0.2)).frame(width: 24, height: 24).blur(radius: 4)
        }
    }
    
    func recordingLabel(for recording: Recording) -> some View {
        let dateName = recording.fileURL.deletingPathExtension().lastPathComponent
        let text = formatTimestamp(dateName)
        
        return Text(text)
            .font(.caption)
            .foregroundColor(.white.opacity(0.8))
            .padding(6)
            .background(Color.black.opacity(0.3))
            .cornerRadius(4)
    }
    
    private func formatTimestamp(_ raw: String) -> String {
        let components = raw.split(separator: "-")
        if let last = components.last, let timeSecond = TimeInterval(last) {
            let date = Date(timeIntervalSince1970: timeSecond)
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d, h:mm a"
            return formatter.string(from: date)
        }
        return raw
    }
}
