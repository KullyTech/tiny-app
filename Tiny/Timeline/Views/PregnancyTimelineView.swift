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
            LinearGradient(colors: [Color(red: 0.05, green: 0.05, blue: 0.15), Color.black], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            
            ZStack {
                if let week = selectedWeek {
                    TimelineDetailView(week: week, animation: animation, onSelectRecording: onSelectRecording)
                        .transition(.opacity)
                } else {
                    MainTimelineListView(groupedData: groupedData, selectedWeek: $selectedWeek, animation: animation)
                        .transition(.opacity)
                }
            }
            
            navigationButtons
        }
        .onAppear(perform: groupRecordings)
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
            } else {
                // ⬇️ Book Button (List -> Close to Orb)
                Spacer()
                Button {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        showTimeline = false
                    }
                } label: {
                    Image(systemName: "book.fill").font(.system(size: 28)).foregroundColor(.white).frame(width: 77, height: 77).clipShape(Circle())
                }
                .glassEffect(.clear)
                .matchedGeometryEffect(id: "navButton", in: animation)
                .padding(.bottom, 50)
            }
        }
        .ignoresSafeArea(.all, edges: .bottom)
    }
    
    private func groupRecordings() {
        let raw = heartbeatSoundManager.savedRecordings
        let cal = Calendar.current
        let grouped = Dictionary(grouping: raw) { rec -> Int in
            let name = rec.fileURL.deletingPathExtension().lastPathComponent
            let parts = name.split(separator: "-")
            if let last = parts.last, let time = TimeInterval(last) { return cal.component(.weekOfYear, from: Date(timeIntervalSince1970: time)) }
            return 0
        }
        self.groupedData = grouped.map { WeekSection(weekNumber: $0.key, recordings: $0.value.sorted(by: { $0.fileURL.absoluteString > $1.fileURL.absoluteString })) }.sorted(by: { $0.weekNumber < $1.weekNumber })
    }
}

#Preview {
    let mockManager = HeartbeatSoundManager()
    
    let now = Date()
    let week1Time = now.timeIntervalSince1970
    let week2Time = (now.addingTimeInterval(-86400 * 7)).timeIntervalSince1970
    let week3Time = (now.addingTimeInterval(-86400 * 20)).timeIntervalSince1970
    
    mockManager.savedRecordings = [
        // Week A
        Recording(fileURL: URL(fileURLWithPath: "heartbeat-\(week1Time).caf")),
        Recording(fileURL: URL(fileURLWithPath: "heartbeat-\(week1Time - 100).caf")),
        
        // Week B
        Recording(fileURL: URL(fileURLWithPath: "heartbeat-\(week2Time).caf")),
        
        // Week C
        Recording(fileURL: URL(fileURLWithPath: "heartbeat-\(week3Time).caf")),
        Recording(fileURL: URL(fileURLWithPath: "heartbeat-\(week3Time - 50).caf"))
    ]
    
    // 4. Render the View
    return PregnancyTimelineView(
        heartbeatSoundManager: mockManager,
        showTimeline: .constant(true),
        onSelectRecording: { _ in }
    )
    .preferredColorScheme(.dark)
}
