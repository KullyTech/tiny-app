//
//  TimelineDetailView.swift
//  Tiny
//
//  Created by Tm Revanza Narendra Pradipta on 21/11/25.
//

import SwiftUI

struct TimelineDetailView: View {
    let week: WeekSection
    var animation: Namespace.ID
    let onSelectRecording: (Recording) -> Void
    
    @ObservedObject var heartbeatSoundManager: HeartbeatSoundManager
    
    let isMother: Bool
    
    private var currentRecordings: [Recording] {
        heartbeatSoundManager.savedRecordings.filter { recording in
            let calendar = Calendar.current
            guard let storedDate = UserDefaults.standard.object(forKey: "pregnancyStartDate") as? Date else {
                return false
            }
            let pregnancyStartDate = calendar.startOfDay(for: storedDate)
            let weeksSinceStart = calendar.dateComponents([.weekOfYear], from: pregnancyStartDate, to: recording.createdAt).weekOfYear ?? 0
            return weeksSinceStart == week.weekNumber
        }.sorted { $0.createdAt < $1.createdAt } // Oldest first (newest at bottom)
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Scrollable content with orb and recordings
                recordingsScrollView(geometry: geometry)
                
                // Fixed header with back button and week title
                VStack(spacing: 0) {
                    HStack {
                        // Back button placeholder (actual button is in PregnancyTimelineView)
                        Color.clear
                            .frame(width: 50, height: 50)
                        
                        Spacer()
                        
                        // Week title
                        Text("Week \(week.weekNumber)")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        // Right side spacer for balance
                        Color.clear
                            .frame(width: 50, height: 50)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, geometry.safeAreaInsets.top + 40)
                    .background(
                        LinearGradient(
                            colors: [Color.black.opacity(0.6), Color.clear],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    
                    Spacer()
                }
            }
        }
    }
    
    private func recordingsScrollView(geometry: GeometryProxy) -> some View {
        let recordings = currentRecordings
        let recSpacing: CGFloat = 100
        let orbHeight: CGFloat = 115
        let topPadding: CGFloat = geometry.safeAreaInsets.top + 100
        
        // Calculate total height
        let contentHeight = orbHeight + CGFloat(recordings.count) * recSpacing + 200
        
        return ScrollView(showsIndicators: false) {
            ZStack(alignment: .top) {
                
                // Continuous Wave Path
                ContinuousWave(
                    totalHeight: contentHeight - (orbHeight / 2),
                    period: 400,
                    amplitude: 60
                )
                .stroke(
                    Color.white.opacity(0.15),
                    style: StrokeStyle(lineWidth: 1, lineCap: .round)
                )
                .frame(width: geometry.size.width, height: contentHeight - (orbHeight / 2))
                .offset(y: orbHeight / 2) // Start from center of orb (visually bottom due to ZStack alignment)
                
                // Orb at the top
                ZStack {
                    AnimatedOrbView(size: orbHeight)
                        .shadow(color: .orange.opacity(0.6), radius: 30)
                }
                .matchedGeometryEffect(id: "orb_\(week.weekNumber)", in: animation)
                .frame(height: orbHeight)
                .frame(maxWidth: .infinity) // Center horizontally
                // No top padding here, it sits at y=0 of the ZStack (start of wave)
                
                // Recordings
                ForEach(Array(recordings.enumerated()), id: \.element.id) { index, recording in
                    let yPos = orbHeight + CGFloat(index) * recSpacing + 40
                    let xPos = TimelineLayout.calculateX(
                        yCoor: yPos,
                        width: geometry.size.width,
                        period: 400,
                        amplitude: 60
                    )
                    
                    HStack(spacing: 16) {
                        // Glowing dot
                        glowingDot
                            .onTapGesture { onSelectRecording(recording) }
                        
                        // Label
                        recordingLabel(for: recording)
                        
                        Spacer()
                    }
                    .padding(.leading, xPos - 6) // Position dot center at xPos (6 is half dot width)
                    .frame(width: geometry.size.width, alignment: .leading)
                    .position(x: geometry.size.width / 2, y: yPos)
                }
            }
            .frame(width: geometry.size.width, height: contentHeight)
            .padding(.top, topPadding)
        }
    }
    
    var glowingDot: some View {
        ZStack {
            Circle()
                .fill(Color.white)
                .frame(width: 12, height: 12)
                .shadow(color: .white.opacity(0.8), radius: 8, x: 0, y: 0) // Glow effect
        }
    }
    
    func recordingLabel(for recording: Recording) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(recording.displayName ?? "Baby's Heartbeat")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
                .fixedSize(horizontal: false, vertical: true)
            
            Text(recording.createdAt.formatted(date: .long, time: .omitted))
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.6))
        }
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

#Preview {
    struct PreviewWrapper: View {
        @Namespace var animation
        
        var mockWeek: WeekSection {
            let dummyURL = URL(fileURLWithPath: "Heartbeat-1715421234.m4a")
            
            let rec1 = Recording(fileURL: dummyURL, createdAt: Date())
            let rec2 = Recording(fileURL: dummyURL, createdAt: Date().addingTimeInterval(-3600))
            
            return WeekSection(weekNumber: 24, recordings: [rec1, rec2, rec1])
        }
        
        var body: some View {
            TimelineDetailView(
                week: mockWeek,
                animation: animation,
                onSelectRecording: { recording in
                    print("Selected: \(recording.createdAt)")
                },
                heartbeatSoundManager: HeartbeatSoundManager(),
                isMother: true
            )
            .background(Color(red: 0.1, green: 0.1, blue: 0.2))
            .environmentObject(ThemeManager())
        }
    }
    
    return PreviewWrapper()
}
