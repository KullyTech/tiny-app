//
//  TimelineView.swift
//  Tiny
//
//  Created by Tm Revanza Narendra Pradipta on 18/11/25.
//

import SwiftUI

struct PregnancyTimelineView: View {
    @ObservedObject var heartbeatSoundManager: HeartbeatSoundManager
    let onSelectRecording: (Recording) -> Void
    let onClose: () -> Void
    
    @State private var isExpanded = false
    @State private var showDates = false
    
    private static let dateFormatter: DateFormatter = {
        let dateFormat = DateFormatter()
        dateFormat.dateStyle = .medium
        dateFormat.timeStyle = .short
        return dateFormat
    }()
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [Color(red: 0.05, green: 0.05, blue: 0.15), Color.black],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            // Title
            VStack {
                if isExpanded {
                    Text("Heartbeat Timeline")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                        .transition(.opacity)
                        .padding(.top, 80)
                } else {
                    Spacer().frame(height: 40)
                }
                Spacer()
            }
            
            GeometryReader { geometry in
                ZStack {
                    // Wavy timeline path
                    WavePath()
                        .stroke(
                            Color.white.opacity(0.25),
                            style: StrokeStyle(
                                lineWidth: 2,
                                lineCap: .round,
                                lineJoin: .round,
                                dash: [6, 8]
                            )
                        )
                        .frame(width: geometry.size.width, height: geometry.size.height)
                    
                    let recordings = heartbeatSoundManager.savedRecordings
                    let total = recordings.count
                    
                    if total == 0 {
                        VStack {
                            Spacer()
                            Text("No saved recordings yet")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.6))
                                .padding(.bottom, 140)
                        }
                        .frame(width: geometry.size.width, height: geometry.size.height)
                    } else {
                        // Orbs along the wavy path
                        ForEach(recordings.indices, id: \.self) { index in
                            let recording = recordings[index]
                            let point = wavePoint(
                                for: index,
                                total: total,
                                in: geometry.size
                            )
                            
                            VStack(spacing: 4) {
                                AnimatedOrbView(size: 40)
                                    .onTapGesture {
                                        onSelectRecording(recording)
                                    }
                                
                                Text(label(for: recording))
                                    .font(.caption2)
                                    .foregroundColor(.white.opacity(0.8))
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.7)
                            }
                            .position(point)
                            .transition(.scale.combined(with: .opacity))
                        }
                    }
                }
            }
            
            // Bottom morphing book/back button (glass)
            GeometryReader { geometry in
                Button {
                    if !isExpanded {
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                            isExpanded = true
                        }
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.3)) {
                            showDates = true
                        }
                    } else {
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                            isExpanded = false
                            showDates = false
                        }
                        onClose()
                    }
                } label: {
                    ZStack {
                        // book icon when collapsed
                        Image(systemName: "book.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.white)
                            .opacity(isExpanded ? 0 : 1)
                            .scaleEffect(isExpanded ? 0.5 : 1)

                        // chevron when expanded
                        Image(systemName: "chevron.left")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(.white)
                            .opacity(isExpanded ? 1 : 0)
                            .scaleEffect(isExpanded ? 1 : 0.5)
                    }
                    .frame(width: isExpanded ? 50 : 77, height: isExpanded ? 50 : 77)
                    .clipShape(Circle())
                }
                .glassEffect(.clear)
                .position(
                    x: isExpanded ? 45 : geometry.size.width / 2,
                    y: isExpanded ? 85 : geometry.size.height - 100
                )
            }
        }
        .animation(.easeInOut(duration: 0.4), value: isExpanded)
    }
    
    // Position along the same wave as the path, from bottom to top
    private func wavePoint(for index: Int, total: Int, in size: CGSize) -> CGPoint {
        guard total > 1 else {
            return CGPoint(x: size.width * 0.5, y: size.height * 0.75)
        }
        
        // 0 = bottom, 1 = top
        let top = CGFloat(index) / CGFloat(max(total - 1, 1))
        
        let yStart = size.height * 0.75
        let yEnd = size.height * 0.25
        let yCoordinate = yStart + (yEnd - yStart) * top
        
        let centerX = size.width * 0.5
        let amplitude = size.width * 0.25
        let xCoordinate = centerX + sin(top * .pi * 1.5) * amplitude
        
        return CGPoint(x: xCoordinate, y: yCoordinate)
    }
    
    private func label(for recording: Recording) -> String {
        // Try to extract unix timestamp from filename "saved-heartbeat-<timestamp>.caf"
        let name = recording.fileURL.deletingPathExtension().lastPathComponent
        
        let components = name.split(separator: "-")
        if let last = components.last,
           let timeSecond = TimeInterval(last) {
            let date = Date(timeIntervalSince1970: timeSecond)
            return Self.dateFormatter.string(from: date)
        } else {
            // Fallback: show the raw file name
            return name
        }
    }
}

// Wavy timeline path (matches `wavePoint`)
struct WavePath: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let centerX = rect.width * 0.5
        let amplitude = rect.width * 0.25
        let yStart = rect.height * 0.75
        let yEnd = rect.height * 0.25
        let steps = 60
        
        path.move(to: CGPoint(x: centerX, y: yStart))
        
        for step in 1...steps {
            let top = CGFloat(step) / CGFloat(steps)
            let yCoor = yStart + (yEnd - yStart) * top
            let xCoor = centerX + sin(top * .pi * 1.5) * amplitude
            path.addLine(to: CGPoint(x: xCoor, y: yCoor))
        }
        
        return path
    }
}

#Preview {
    PregnancyTimelineView(
        heartbeatSoundManager: HeartbeatSoundManager(),
        onSelectRecording: { _ in },
        onClose: {}
    )
}
