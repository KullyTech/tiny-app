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
    
    @ObservedObject private var userProfile = UserProfileManager.shared
    
    var body: some View {
        NavigationStack {
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
    }
    
    private var navigationButtons: some View {
        VStack {
            // Top Bar
            HStack {
                if selectedWeek != nil {
                    // Back Button (Detail -> List)
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
                } else {
                    Spacer()
                }
                
                Spacer()
                
                // Profile Button (Top Right)
                if selectedWeek == nil {
                    NavigationLink {
                        ProfileView()
                    } label: {
                        Group {
                            if let image = userProfile.profileImage {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                            } else {
                                Image(systemName: "person.crop.circle.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .foregroundColor(.white.opacity(0.8))
                            }
                        }
                        .frame(width: 45, height: 45    )
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 1))
                        .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top,20)

            Spacer()
            
            if selectedWeek == nil {
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
    
    mockManager.savedRecordings = [
        // Week A (Current Week)
        Recording(fileURL: URL(fileURLWithPath: "my-baby-heartbeat.caf"), createdAt: week1Date),
        Recording(fileURL: URL(fileURLWithPath: "morning-check.caf"), createdAt: week1Date.addingTimeInterval(-100)),
        
        // Week B (Last Week)
        Recording(fileURL: URL(fileURLWithPath: "late-night-kick.caf"), createdAt: week2Date),
        
        // Week C (3 Weeks Ago)
        Recording(fileURL: URL(fileURLWithPath: "first-time.caf"), createdAt: week3Date),
        Recording(fileURL: URL(fileURLWithPath: "doctor-visit.caf"), createdAt: week3Date.addingTimeInterval(-50))
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
