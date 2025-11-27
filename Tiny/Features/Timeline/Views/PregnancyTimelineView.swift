//
//  PregnancyTimelineView.swift
//  Tiny
//
//  Created by Tm Revanza Narendra Pradipta on 18/11/25.
//

import SwiftUI

struct PregnancyTimelineView: View {
    @ObservedObject var heartbeatSoundManager: HeartbeatSoundManager
    // ⬇️ NEW: Binding to control close
    @Binding var showTimeline: Bool
    let onSelectRecording: (Recording) -> Void
    
    @Namespace private var animation
    @State private var selectedWeek: WeekSection?
    @State private var groupedData: [WeekSection] = []
    
    var body: some View {
        ZStack {
            ZStack {
                Color.black.ignoresSafeArea()
                Image("backgroundPurple")
                    .resizable()
                    .ignoresSafeArea()
            }
            
            ZStack {
                if let week = selectedWeek {
                    TimelineDetailView(
                        week: week,
                        animation: animation,
                        onSelectRecording: onSelectRecording,
                        onDeleteRecording: { recording in
                            withAnimation {
                                heartbeatSoundManager.deleteSavedRecording(recording)
                                // If week becomes empty, go back? Optional.
                                // Force refresh of local selectedWeek state:

                                if let _ = selectedWeek?.recordings.firstIndex(of: recording) {
                                    // We need to refresh 'groupedData' first, then re-select this week
                                    // groupRecordings() will happen automatically via onChange below
                                }
                            }
                        }
                    )
                    .transition(.opacity)
                } else {
                    MainTimelineListView(groupedData: groupedData, selectedWeek: $selectedWeek, animation: animation).transition(.opacity)
                }
            }
            
            navigationButtons
        }
        .onAppear(perform: groupRecordings)
        // refresh when data changes (e.g. after delete)
        .onChange(of: heartbeatSoundManager.savedRecordings) { _, _ in
            groupRecordings()
            // Also update the currently selected week object so the detail view updates immediately
            if let currentWeek = selectedWeek {
                selectedWeek = groupedData.first(where: { $0.weekNumber == currentWeek.weekNumber })
                // If the week is now empty/gone, go back to main list
                if selectedWeek == nil {
                    withAnimation { selectedWeek = nil }
                }
            }
        }
    }
    
    private var navigationButtons: some View {
        VStack {
            if selectedWeek != nil {
                // Back Button (Detail -> List)
                HStack {
                    Button {
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.75)) { selectedWeek = nil }
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 50, height: 50)
                            .clipShape(Circle())
                    }
                    .glassEffect(.clear)
                    .matchedGeometryEffect(id: "navButton", in: animation)
                    .padding(.leading, 20)
                    .padding(.top, 0)
                    Spacer()
                }
                Spacer()
            }
        }
        .ignoresSafeArea(.all, edges: .bottom)
    }
    
    private func groupRecordings() {
        let raw = heartbeatSoundManager.savedRecordings
        let calendar = Calendar.current
        
        let grouped = Dictionary(grouping: raw) { recording -> Int in
            return calendar.component(.weekOfYear, from: recording.createdAt)
        }
        
        self.groupedData = grouped.map {
            WeekSection(weekNumber: $0.key, recordings: $0.value.sorted(by: { $0.createdAt > $1.createdAt }))
        }.sorted(by: { $0.weekNumber < $1.weekNumber })
    }
}

#Preview {
    let mockManager = HeartbeatSoundManager()
    
    let now = Date()
    let week1Date = now
    let week2Date = Calendar.current.date(byAdding: .day, value: -7, to: now)! // 1 week ago
    let week3Date = Calendar.current.date(byAdding: .day, value: -21, to: now)! // 3 weeks ago
    let week4Date = Calendar.current.date(byAdding: .day, value: -28, to: now)! // 4 weeks ago
    let week5Date = Calendar.current.date(byAdding: .day, value: -35, to: now)! // 5 weeks ago
    let week6Date = Calendar.current.date(byAdding: .day, value: -42, to: now)! // 6 weeks ago
    let week7Date = Calendar.current.date(byAdding: .day, value: -49, to: now)! // 7 weeks ago
    
    mockManager.savedRecordings = [
        // Week A (Current Week)
        Recording(fileURL: URL(fileURLWithPath: "my-baby-heartbeat.caf"), createdAt: week1Date),
        Recording(fileURL: URL(fileURLWithPath: "morning-check.caf"), createdAt: week1Date.addingTimeInterval(-100)),
        
        // Week B (Last Week)
        Recording(fileURL: URL(fileURLWithPath: "late-night-kick.caf"), createdAt: week2Date),
        
        // Week C (3 Weeks Ago)
        Recording(fileURL: URL(fileURLWithPath: "first-time.caf"), createdAt: week3Date),
        Recording(fileURL: URL(fileURLWithPath: "doctor-visit.caf"), createdAt: week3Date.addingTimeInterval(-50)),
        
        Recording(fileURL: URL(fileURLWithPath: "first-time1.caf"), createdAt: week4Date),
        
        Recording(fileURL: URL(fileURLWithPath: "first-time2.caf"), createdAt: week5Date),
        
        Recording(fileURL: URL(fileURLWithPath: "first-time3.caf"), createdAt: week6Date),
        
        Recording(fileURL: URL(fileURLWithPath: "first-time4.caf"), createdAt: week7Date)
    ]
    
    return PregnancyTimelineView(
        heartbeatSoundManager: mockManager,
        showTimeline: .constant(true),
        onSelectRecording: { recording in
            print("Selected: \(recording.fileURL.lastPathComponent)")
        }
    )
    .preferredColorScheme(.dark)
}
