//
//  PregnancyTimelineView.swift
//  Tiny
//
//  Created by Tm Revanza Narendra Pradipta on 18/11/25.
//

import SwiftUI

struct PregnancyTimelineView: View {
    @ObservedObject var heartbeatSoundManager: HeartbeatSoundManager
    @Binding var showTimeline: Bool
    let onSelectRecording: (Recording) -> Void
    let isMother: Bool  // Add this parameter
    
    @Namespace private var animation
    @State private var selectedWeek: WeekSection?
    @State private var groupedData: [WeekSection] = []
    
    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(red: 0.05, green: 0.05, blue: 0.15), Color.black], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            
            ZStack {
                if let week = selectedWeek {
                    TimelineDetailView(
                        week: week,
                        animation: animation,
                        onSelectRecording: onSelectRecording,
                        isMother: isMother  // Pass it here
                    )
                    .transition(.opacity)
                } else {
                    MainTimelineListView(groupedData: groupedData, selectedWeek: $selectedWeek, animation: animation)
                        .transition(.opacity)
                }
            }
            
            navigationButtons
        }
        .onAppear {
            print("📱 Timeline appeared - grouping recordings")
            groupRecordings()
        }
        .onChange(of: heartbeatSoundManager.savedRecordings) { oldValue, newValue in
            print("🔄 Recordings changed: \(oldValue.count) -> \(newValue.count)")
            groupRecordings()
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
            } else {
                // Sync Button (Top Right)
                HStack {
                    Spacer()
                    Button {
                        print("🔄 Manual sync triggered")
                        heartbeatSoundManager.loadFromSwiftData()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 50, height: 50)
                            .clipShape(Circle())
                    }
                    .glassEffect(.clear)
                    .padding(.trailing, 20)
                    .padding(.top, 50)
                }
                
                Spacer()
                
                // Book Button (List -> Close to Orb)
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
        print("📊 Grouping \(raw.count) recordings")
        
        let calendar = Calendar.current
        
        let grouped = Dictionary(grouping: raw) { recording -> Int in
            return calendar.component(.weekOfYear, from: recording.createdAt)
        }
        
        self.groupedData = grouped.map {
            WeekSection(weekNumber: $0.key, recordings: $0.value.sorted(by: { $0.createdAt > $1.createdAt }))
        }.sorted(by: { $0.weekNumber < $1.weekNumber })
        
        print("📊 Created \(groupedData.count) week sections")
        for section in groupedData {
            print("   Week \(section.weekNumber): \(section.recordings.count) recordings")
        }
    }
}
