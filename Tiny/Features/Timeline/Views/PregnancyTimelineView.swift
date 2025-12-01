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
    let onDisableSwipe: (Bool) -> Void  // Callback to disable TabView swipe
    let isMother: Bool  // Add this parameter
    var inputWeek: Int?  // Week from onboarding input
    
    @Namespace private var animation
    @State private var selectedWeek: WeekSection?
    @State private var groupedData: [WeekSection] = []
    @State private var isProfilePresented = false
    @EnvironmentObject var themeManager: ThemeManager
    
    // Animation support
    @StateObject private var animationController = TimelineAnimationController()
    @State private var isFirstTimeVisit: Bool = false
    
    @ObservedObject private var userProfile = UserProfileManager.shared
    
    var body: some View {
        NavigationStack {
            ZStack {
                Image(themeManager.selectedBackground.imageName)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .ignoresSafeArea()
                
                if let week = selectedWeek {
                    TimelineDetailView(
                        week: week,
                        animation: animation,
                        onSelectRecording: onSelectRecording,
                        heartbeatSoundManager: heartbeatSoundManager,
                        isMother: isMother
                    )
                    .transition(.opacity)
                } else {
                    MainTimelineListView(
                        groupedData: groupedData,
                        selectedWeek: $selectedWeek,
                        animation: animation,
                        animationController: animationController,
                        isFirstTimeVisit: isFirstTimeVisit,
//                        isMother: isMother
                    )
                    .transition(.opacity)
                }
                
                // Top navigation bar
                GeometryReader { geometry in
                    VStack {
                        HStack {
                            if selectedWeek != nil {
                                Button {
                                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                        selectedWeek = nil
                                    }
                                } label: {
                                    Image(systemName: "chevron.left")
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundColor(.white)
                                        .frame(width: 50, height: 50)
                                }
                                .glassEffect(.clear)
                                .matchedGeometryEffect(id: "navButton", in: animation)
                            } else {
                                Spacer()
                            }
                            
                            Spacer()
                            
                            if selectedWeek == nil {
                                Button {
                                    isProfilePresented = true
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
                                    .frame(width: 50, height: 50)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 1))
                                    .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                                }
                                .opacity(isFirstTimeVisit ? (animationController.profileVisible ? 1.0 : 0.0) : 1.0)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, geometry.safeAreaInsets.top + 39)
                        
                        Spacer()
                    }
                }
            }
            .navigationDestination(isPresented: $isProfilePresented) {
                ProfileView()
            }
            .onAppear(perform: groupRecordings)
        }
        .onAppear {
            print("Timeline appeared")
            initializeTimeline()
        }
        .onChange(of: heartbeatSoundManager.savedRecordings) { oldValue, newValue in
            print("Recordings changed: \(oldValue.count) -> \(newValue.count)")
            groupRecordings()
        }
        .onChange(of: isProfilePresented) { _, newValue in
            // Disable TabView swipe when ProfileView is presented
            print("🔄 Profile presented changed: \(newValue)")
            onDisableSwipe(newValue)
        }
    }
    
    private func initializeTimeline() {
        // Check if this is first time visit
        isFirstTimeVisit = !UserDefaults.standard.bool(forKey: "hasSeenTimelineAnimation")
        
        // Get week from parameter or UserDefaults
        let week = inputWeek ?? UserDefaults.standard.integer(forKey: "pregnancyWeek")
        
        print("🎬 Timeline initialization:")
        print("   inputWeek parameter: \(inputWeek ?? -1)")
        print("   UserDefaults week: \(UserDefaults.standard.integer(forKey: "pregnancyWeek"))")
        print("   Final week: \(week)")
        print("   isFirstTimeVisit: \(isFirstTimeVisit)")
        
        if isFirstTimeVisit, week > 0 {
            // First time: Create initial data with placeholder dots
            print("🎬 First time visit - creating initial timeline for week \(week)")
            
            // Create 3 weeks: reversed order (newest at bottom)
            groupedData = [
                WeekSection(weekNumber: week + 2, recordings: [], type: .placeholder),
                WeekSection(weekNumber: week + 1, recordings: [], type: .placeholder),
                WeekSection(weekNumber: week, recordings: [], type: .placeholder)
            ]
            
            // Start animation after a brief delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                print("🎬 Starting timeline animation!")
                self.animationController.startAnimation()
            }
            
            // Mark as seen
            UserDefaults.standard.set(true, forKey: "hasSeenTimelineAnimation")
        } else {
            // Normal visit: Group recordings and show everything immediately
            print("📊 Normal visit - grouping recordings")
            
            // Set animation controller to complete state so path and orbs are visible
            animationController.skipAnimation()
            
            groupRecordings()
        }
    }
    
    private func groupRecordings() {
        let raw = heartbeatSoundManager.savedRecordings
        print("📊 Grouping \(raw.count) recordings")

        guard let initialPregnancyWeek = inputWeek else {
            print("⚠️ No pregnancy week available, showing empty timeline")
            groupedData = []
            return
        }
        
        let calendar = Calendar.current
        let now = Date()
        
        // Store initial pregnancy week and date in UserDefaults if not already stored
        if UserDefaults.standard.object(forKey: "pregnancyStartDate") == nil {
            let pregnancyStartDate = calendar.date(byAdding: .weekOfYear, value: -initialPregnancyWeek, to: now)!
            UserDefaults.standard.set(pregnancyStartDate, forKey: "pregnancyStartDate")
            UserDefaults.standard.set(initialPregnancyWeek, forKey: "initialPregnancyWeek")
            print("💾 Stored pregnancy start date: \(pregnancyStartDate)")
        }
        
        // Get the stored pregnancy start date
        guard let storedDate = UserDefaults.standard.object(forKey: "pregnancyStartDate") as? Date else {
            print("⚠️ Could not get pregnancy start date")
            groupedData = []
            return
        }
        // Normalize to start of day to avoid time-based drift
        let pregnancyStartDate = calendar.startOfDay(for: storedDate)
        
        // Calculate CURRENT pregnancy week based on time elapsed since pregnancy start
        let weeksSinceStart = calendar.dateComponents([.weekOfYear], from: pregnancyStartDate, to: now).weekOfYear ?? 0
        let currentPregnancyWeek = weeksSinceStart
        
        print("📅 Pregnancy started: \(pregnancyStartDate)")
        print("📅 Initial pregnancy week: \(initialPregnancyWeek)")
        print("📅 Current pregnancy week (calculated): \(currentPregnancyWeek)")
        print("📅 Weeks elapsed: \(currentPregnancyWeek - initialPregnancyWeek)")

        // Group recordings by pregnancy week
        let grouped = Dictionary(grouping: raw) { recording -> Int in
            // Calculate how many weeks since pregnancy started
            let weeksSinceStart = calendar.dateComponents([.weekOfYear], from: pregnancyStartDate, to: recording.createdAt).weekOfYear ?? 0
            let pregnancyWeek = weeksSinceStart
            print("   Recording from \(recording.createdAt) -> Pregnancy week \(pregnancyWeek)")
            return pregnancyWeek
        }
        
        var recordedWeeks = grouped.map {
            WeekSection(weekNumber: $0.key, recordings: $0.value.sorted(by: { $0.createdAt > $1.createdAt }), type: .recorded)
        }.sorted(by: { $0.weekNumber > $1.weekNumber })  // Reversed: newest (highest week) at bottom
        
        // Show current week + next 2 weeks (as placeholders if no recordings)
        let weeksToShow = [currentPregnancyWeek, currentPregnancyWeek + 1, currentPregnancyWeek + 2]
        
        for week in weeksToShow where !recordedWeeks.contains(where: { $0.weekNumber == week }) {
            recordedWeeks.append(
                WeekSection(weekNumber: week, recordings: [], type: .placeholder)
            )
        }

        // Sort again after adding placeholders
        recordedWeeks.sort(by: { $0.weekNumber > $1.weekNumber })
        
        self.groupedData = recordedWeeks
        
        print("📊 Created \(groupedData.count) week sections")
        for section in groupedData {
            print("   Week \(section.weekNumber): \(section.recordings.count) recordings (\(section.type))")
        }
    }
}

#Preview {
    @Previewable @State var showTimeline = true

    let mockManager = HeartbeatSoundManager()
    let themeManager = ThemeManager()
    let calendar = Calendar.current
    let now = Date()

    // Sample mock data per week
    let mockData: [(weeksAgo: Int, count: Int)] = [
        (9, 2), // Week 1
        (8, 3), // Week 2
        (7, 1), // Week 3
        (6, 4), // Week 4
        (5, 2), // Week 5
        (4, 3), // Week 6
        (3, 2), // Week 7
        (2, 3), // Week 8
        (1, 1)  // Week 9
    ]

    // Generate weeks 1–9
    for (weeksAgo, count) in mockData {
        if let weekDate = calendar.date(byAdding: .day, value: -(weeksAgo * 7), to: now) {
            for index in 0..<count {
                let file = "/mock/week\(weeksAgo)-rec\(index + 1).wav"
                let createdAt = weekDate.addingTimeInterval(Double(index) * 3600)
                mockManager.savedRecordings.append(
                    Recording(
                        fileURL: URL(fileURLWithPath: file),
                        createdAt: createdAt
                    )
                )
            }
        }
    }

    // Current week (Week 10)
    let currentWeekTimes: [TimeInterval] = [-10800, -7200, -3600, 0]
    for (index, time) in currentWeekTimes.enumerated() {
        mockManager.savedRecordings.append(
            Recording(
                fileURL: URL(fileURLWithPath: "/mock/week10-rec\(index + 1).wav"),
                createdAt: now.addingTimeInterval(time)
            )
        )
    }

    UserDefaults.standard.set(false, forKey: "hasSeenTimelineAnimation")

    return PregnancyTimelineView(
        heartbeatSoundManager: mockManager,
        showTimeline: $showTimeline,
        onSelectRecording: { recording in
            print("Selected recording: \(recording.fileURL.lastPathComponent)")
        },
        onDisableSwipe: { _ in },
        isMother: true,
        inputWeek: 20
    )
    .environmentObject(themeManager)
}
