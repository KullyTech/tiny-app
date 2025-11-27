//
//  HeartbeatMainView.swift
//  Tiny
//
//  Created by Tm Revanza Narendra Pradipta on 20/11/25.
//

import SwiftUI
import SwiftData

struct HeartbeatMainView: View {
    @StateObject private var viewModel = HeartbeatMainViewModel()
    @Environment(\.modelContext) private var modelContext
    @State private var dragOffset: CGFloat = 0

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background views
                HStack(spacing: 0) {
                    OrbLiveListenView(
                        heartbeatSoundManager: viewModel.heartbeatSoundManager,
                        showTimeline: $viewModel.showTimeline
                    )
                    .frame(width: geometry.size.width)
                    
                    PregnancyTimelineView(
                        heartbeatSoundManager: viewModel.heartbeatSoundManager,
                        showTimeline: $viewModel.showTimeline,
                        onSelectRecording: viewModel.handleRecordingSelection
                    )
                    .frame(width: geometry.size.width)
                }
                .offset(x: viewModel.showTimeline ? -geometry.size.width + dragOffset : dragOffset)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            dragOffset = value.translation.width
                        }
                        .onEnded { value in
                            let threshold: CGFloat = geometry.size.width * 0.25
                            let velocity = value.predictedEndTranslation.width
                            
                            // Determine if we should switch pages
                            let shouldSwitch = abs(value.translation.width) > threshold || abs(velocity) > 500
                            
                            if shouldSwitch {
                                if value.translation.width > 0 && viewModel.showTimeline {
                                    // Swipe right - go to live view
                                    triggerHaptic(style: .medium)
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                        viewModel.showTimeline = false
                                        dragOffset = 0
                                    }
                                } else if value.translation.width < 0 && !viewModel.showTimeline {
                                    // Swipe left - go to timeline
                                    triggerHaptic(style: .medium)
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                        viewModel.showTimeline = true
                                        dragOffset = 0
                                    }
                                } else {
                                    // Bounce back
                                    triggerHaptic(style: .light)
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.9)) {
                                        dragOffset = 0
                                    }
                                }
                            } else {
                                // Snap back
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.9)) {
                                    dragOffset = 0
                                }
                            }
                        }
                )
                .animation(.spring(response: 0.35, dampingFraction: 0.85), value: viewModel.showTimeline)
                
                // Page indicators with swipe hint
                VStack {
                    Spacer()
                    
                    HStack(spacing: 20) {
                        // Live Listen indicator
                        VStack(spacing: 8) {
                            Image(systemName: "waveform.circle.fill")
                                .font(.system(size: 20))
                                .foregroundColor(viewModel.showTimeline ? .white.opacity(0.3) : .white)
                            
                            Circle()
                                .fill(viewModel.showTimeline ? Color.white.opacity(0.3) : Color.white)
                                .frame(width: 8, height: 8)
                        }
                        .scaleEffect(viewModel.showTimeline ? 0.85 : 1.0)
                        
                        // Timeline indicator
                        VStack(spacing: 8) {
                            Image(systemName: "calendar.circle.fill")
                                .font(.system(size: 20))
                                .foregroundColor(viewModel.showTimeline ? .white : .white.opacity(0.3))
                            
                            Circle()
                                .fill(viewModel.showTimeline ? Color.white : Color.white.opacity(0.3))
                                .frame(width: 8, height: 8)
                        }
                        .scaleEffect(viewModel.showTimeline ? 1.0 : 0.85)
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(
                        Capsule()
                            .fill(.ultraThinMaterial)
                            .shadow(color: .black.opacity(0.2), radius: 10, y: 5)
                    )
                    .padding(.bottom, 40)
                }
                
                // Swipe hint (shows only on first launch)
                if !viewModel.hasSeenSwipeHint {
                    SwipeHintOverlay(
                        onDismiss: {
                            withAnimation {
                                viewModel.hasSeenSwipeHint = true
                            }
                        }
                    )
                    .transition(.opacity)
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            viewModel.setupManager(modelContext: modelContext)
        }
    }
    
    private func triggerHaptic(style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }
}

// Optional: Swipe hint overlay for first-time users
struct SwipeHintOverlay: View {
    let onDismiss: () -> Void
    @State private var animateArrow = false
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()
                .onTapGesture {
                    onDismiss()
                }
            
            VStack(spacing: 24) {
                HStack(spacing: 12) {
                    Image(systemName: "arrow.left")
                        .font(.system(size: 30, weight: .medium))
                        .offset(x: animateArrow ? -10 : 0)
                    
                    Image(systemName: "arrow.right")
                        .font(.system(size: 30, weight: .medium))
                        .offset(x: animateArrow ? 10 : 0)
                }
                .foregroundColor(.white)
                
                Text("Swipe to switch views")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Button(action: onDismiss) {
                    Text("Got it")
                        .font(.body.weight(.semibold))
                        .foregroundColor(.black)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 12)
                        .background(
                            Capsule()
                                .fill(Color.white)
                        )
                }
                .padding(.top, 8)
            }
            .padding(40)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
            )
            .padding(.horizontal, 40)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                animateArrow = true
            }
        }
    }
}

#Preview {
    HeartbeatMainView()
        .modelContainer(for: SavedHeartbeat.self, inMemory: true)
}
