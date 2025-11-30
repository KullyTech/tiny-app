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
    
    @State private var showMenu = false
    @State private var showImagePicker = false
    @State private var sourceType: UIImagePickerController.SourceType = .photoLibrary
    @State private var selectedImage: UIImage?
    @State private var selectedMoment: Moment?
    @State private var showSuccessAlert = false
    @State private var successMessage = (title: "", subtitle: "")
    
    private var currentItems: [TimelineItem] {
        let calendar = Calendar.current
        guard let storedDate = UserDefaults.standard.object(forKey: "pregnancyStartDate") as? Date else {
            return []
        }
        let pregnancyStartDate = calendar.startOfDay(for: storedDate)
        
        // Filter recordings
        let recordings = heartbeatSoundManager.savedRecordings.compactMap { recording -> TimelineItem? in
            let weeksSinceStart = calendar.dateComponents([.weekOfYear], from: pregnancyStartDate, to: recording.createdAt).weekOfYear ?? 0
            return weeksSinceStart == week.weekNumber ? .recording(recording) : nil
        }
        
        // Filter moments
        let moments = heartbeatSoundManager.savedMoments.compactMap { moment -> TimelineItem? in
            let weeksSinceStart = calendar.dateComponents([.weekOfYear], from: pregnancyStartDate, to: moment.createdAt).weekOfYear ?? 0
            return weeksSinceStart == week.weekNumber ? .moment(moment) : nil
        }
        
        // Combine and sort (Oldest first)
        return (recordings + moments).sorted { $0.createdAt < $1.createdAt }
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
                        // Right side spacer or Add Button
                        // Right side spacer or Add Button
                        VStack(alignment: .trailing, spacing: 0) {
                            Button {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    showMenu.toggle()
                                }
                            } label: {
                                Image(systemName: "plus")
                                    .font(.system(size: 20, weight: .medium))
                                    .foregroundColor(.white)
                                    .frame(width: 44, height: 44)
                                    .background(.ultraThinMaterial)
                                    .clipShape(Circle())
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                    )
                                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                            }
                            .rotationEffect(.degrees(showMenu ? 45 : 0))
                            
                            // Custom Popover Menu
                            if showMenu {
                                VStack(spacing: 0) {
                                    Button {
                                        sourceType = .photoLibrary
                                        showImagePicker = true
                                        showMenu = false
                                    } label: {
                                        HStack {
                                            Image(systemName: "photo.on.rectangle")
                                            Text("Photo Library")
                                            Spacer()
                                        }
                                        .padding()
                                        .foregroundColor(.white)
                                    }
                                    
                                    Divider()
                                        .background(Color.white.opacity(0.2))
                                    
                                    Button {
                                        sourceType = .camera
                                        showImagePicker = true
                                        showMenu = false
                                    } label: {
                                        HStack {
                                            Image(systemName: "camera")
                                            Text("Take Photo")
                                            Spacer()
                                        }
                                        .padding()
                                        .foregroundColor(.white)
                                    }
                                }
                                .frame(width: 200)
                                .background(.ultraThinMaterial)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                )
                                .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
                                .padding(.top, 8)
                                .transition(.scale(scale: 0.8, anchor: .topTrailing).combined(with: .opacity))
                            }
                        }
                        .zIndex(100) // Ensure menu is on top
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
                
                // Moment Overlay
                if let moment = selectedMoment {
                    MomentOverlayView(
                        moment: moment,
                        onDismiss: { selectedMoment = nil },
                        onDelete: {
                            // Show alert first
                            successMessage = (title: "Deleted.", subtitle: "Your moment is deleted.")
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                showSuccessAlert = true
                            }
                            // Then delete after alert is visible
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                heartbeatSoundManager.deleteMoment(moment)
                                selectedMoment = nil
                                // Hide alert after another delay
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                        showSuccessAlert = false
                                    }
                                }
                            }
                        }
                    )
                    .transition(.opacity)
                    .zIndex(100)
                }
                
                // Success Alert with dark overlay
                if showSuccessAlert {
                    ZStack {
                        // Dark overlay
                        Color.black.opacity(0.6)
                            .ignoresSafeArea()
                        
                        // Alert on top
                        VStack {
                            HStack(spacing: 16) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 28))
                                    .foregroundColor(.white)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(successMessage.title)
                                        .font(.body)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.white)
                                    
                                    Text(successMessage.subtitle)
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.8))
                                }
                                
                                Spacer()
                            }
                            .padding(20)
                            .glassEffect(.clear)
                            .padding(.horizontal, 20)
                            .padding(.top, 60)
                            
                            Spacer()
                        }
                    }
                    .transition(.opacity)
                    .zIndex(300)
                }
            }
            .onChange(of: selectedImage) { _, newImage in
                if let image = newImage {
                    heartbeatSoundManager.saveMoment(image: image)
                }
            }

            .onTapGesture {
                // Close menu when tapping outside
                if showMenu {
                    withAnimation {
                        showMenu = false
                    }
                }
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(image: $selectedImage, sourceType: sourceType)
            }
        }
    }
    
    private func recordingsScrollView(geometry: GeometryProxy) -> some View {
        let items = currentItems
        let recSpacing: CGFloat = 100
        let orbHeight: CGFloat = 115
        let topPadding: CGFloat = geometry.safeAreaInsets.top + 100
        
        // Calculate total height
        let contentHeight = orbHeight + CGFloat(items.count) * recSpacing + 200
        
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
                
                // Items (Recordings & Moments)
                ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                    let yPos = orbHeight + CGFloat(index) * recSpacing + 40
                    let xPos = TimelineLayout.calculateX(
                        yCoor: yPos,
                        width: geometry.size.width,
                        period: 400,
                        amplitude: 60
                    )
                    
                    HStack(spacing: 16) {
                        switch item {
                        case .recording(let recording):
                            // Glowing dot
                            glowingDot
                                .onTapGesture { onSelectRecording(recording) }
                            
                            // Label
                            recordingLabel(for: recording)
                            
                        case .moment(let moment):
                            // Moment Thumbnail
                            momentThumbnail(for: moment)
                                .onTapGesture {
                                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                        selectedMoment = moment
                                    }
                                }
                            
                            // Date Label
                            Text(moment.createdAt.formatted(date: .long, time: .omitted))
                                .font(.system(size: 13))
                                .foregroundColor(.white.opacity(0.6))
                        }
                        
                        Spacer()
                    }
                    .padding(.leading, xPos - (itemIsMoment(item) ? 25 : 6)) // Adjust padding based on item size
                    .frame(width: geometry.size.width, alignment: .leading)
                    .position(x: geometry.size.width / 2, y: yPos)
                }
            }
            .frame(width: geometry.size.width, height: contentHeight)
            .padding(.top, topPadding)
        }
    }
    
    private func itemIsMoment(_ item: TimelineItem) -> Bool {
        if case .moment = item { return true }
        return false
    }
    
    func momentThumbnail(for moment: Moment) -> some View {
        AsyncImage(url: moment.fileURL) { phase in
            if let image = phase.image {
                image
                    .resizable()
                    .scaledToFill()
            } else {
                Color.gray.opacity(0.3)
            }
        }
        .frame(width: 50, height: 50)
        .clipShape(Circle())
        .overlay(Circle().stroke(Color.white, lineWidth: 2))
        .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
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

struct MomentOverlayView: View {
    let moment: Moment
    let onDismiss: () -> Void
    let onDelete: () -> Void
    @State private var showDeleteAlert = false
    
    var body: some View {
        ZStack {
            // Darkened background
            Color.black.opacity(0.8)
                .ignoresSafeArea()
                .onTapGesture {
                    onDismiss()
                }
            
            VStack(spacing: 20) {
                // Photo with overlay
                ZStack(alignment: .bottom) {
                    AsyncImage(url: moment.fileURL) { phase in
                        if let image = phase.image {
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(maxWidth: .infinity)
                                .frame(height: 400)
                                .clipped()
                        } else {
                            ProgressView()
                                .tint(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 400)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 400)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .padding(.horizontal, 20)
                    
                    // Date overlay - no background, body font
                    Text(moment.createdAt.formatted(date: .long, time: .omitted))
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.bottom, 20)
                }
                
                // Delete Button
                Button {
                    showDeleteAlert = true
                } label: {
                    Image(systemName: "trash.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.red)
                        .frame(width: 50, height: 50)
                        .background(Circle().fill(Color.white.opacity(0.1)))
                }
                .padding(.top, 10)
            }
            
            // Custom Alert (matching screenshot)
            if showDeleteAlert {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture {
                        showDeleteAlert = false
                    }
                
                VStack(alignment: .leading, spacing: 10) {
                    
                    VStack(alignment: .leading, spacing: 10) {
                        // Title
                        Text("Delete this moment?")
                            .font(.body)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        // Message
                        Text("This action is permanent and can't be undone.")
                            .font(.callout)
                            .foregroundColor(.white)
                    }
                    .padding(8)
                    .padding(.bottom, 24)
                    
                    // Buttons (side by side)
                    HStack(spacing: 12) {
                        // Delete Button (left)
                        Button {
                            showDeleteAlert = false
                            onDelete()
                        } label: {
                            Text("Delete")
                                .font(.headline)
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity)
                                .frame(height: 48)
                                .cornerRadius(25)
                        }
                        .glassEffect(.regular.tint(.black.opacity(0.20)))
                        
                        // Keep Button (right, with gradient)
                        Button {
                            showDeleteAlert = false
                        } label: {
                            Text("Keep")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 48)
                                .background(
                                    RadialGradient(
                                        colors: [
                                            Color(hex: "8376DB"),
                                            Color(hex: "705AB1")
                                        ],
                                        center: .center,
                                        startRadius: 5,
                                        endRadius: 100
                                    )
                                )
                                .cornerRadius(25)
                        }
                    }
                }
                .frame(width: 300)
                .padding(14)
                .cornerRadius(20)
                .glassEffect(.regular.tint(.black.opacity(0.50)), in: .rect(cornerRadius: 20.0))
            }
        }
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
