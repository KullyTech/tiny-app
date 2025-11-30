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
    @EnvironmentObject var authService: AuthenticationService
    @EnvironmentObject var syncManager: HeartbeatSyncManager

    @State private var showRoomCode = false
    @State private var isInitialized = false

    private var isMother: Bool {
        authService.currentUser?.role == .mother
    }

    var body: some View {
        ZStack {
            TabView(selection: $viewModel.currentPage) {
                PregnancyTimelineView(
                    heartbeatSoundManager: viewModel.heartbeatSoundManager,
                    showTimeline: .constant(true),
                    onSelectRecording: viewModel.handleRecordingSelection,
                    onDisableSwipe: { disable in
                        print("🚫 Swipe disable requested: \(disable), allowTabViewSwipe will be: \(!disable)")
                        viewModel.allowTabViewSwipe = !disable
                    },
                    isMother: isMother,
                    inputWeek: authService.currentUser?.pregnancyWeeks
                )
                .tag(0)
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.95).combined(with: .opacity),
                    removal: .scale(scale: 1.05).combined(with: .opacity)
                ))
                OrbLiveListenView(
                    heartbeatSoundManager: viewModel.heartbeatSoundManager,
                    showTimeline: Binding(
                        get: { viewModel.currentPage == 0 },
                        set: { if $0 { viewModel.currentPage = 0 } else { viewModel.currentPage = 1 } }
                    )
                )
                .tag(1)
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.95).combined(with: .opacity),
                    removal: .scale(scale: 1.05).combined(with: .opacity)
                ))
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .highPriorityGesture(
                // Block TabView swipe only on Orb View (page 1) when requested (e.g. recording/dragging)
                // On Timeline View (page 0), we allow gestures to pass through so vertical scrolling (Profile/Tutorial) works
                (viewModel.currentPage == 1 && !viewModel.allowTabViewSwipe) ? DragGesture() : nil
            )
            .ignoresSafeArea()
            
            // Page indicator dots
            PageIndicators(viewModel: viewModel, manager: viewModel.heartbeatSoundManager)
            
            // SavedRecordingPlaybackView overlay
            if let recording = viewModel.selectedRecording {
                SavedRecordingPlaybackView(
                    recording: recording,
                    heartbeatSoundManager: viewModel.heartbeatSoundManager,
                    showTimeline: Binding(
                        get: { false },
                        set: { if $0 { viewModel.selectedRecording = nil } }
                    )
                )
                .transition(.move(edge: .trailing).combined(with: .opacity))
                .zIndex(10)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            // Initialize only once
            if !isInitialized {
                initializeManager()
            }
        }
        .onChange(of: authService.currentUser?.roomCode) { oldValue, newValue in
            // Re-initialize when room code changes
            if newValue != nil && newValue != oldValue {
                print("🔄 Room code updated: \(newValue ?? "nil")")
                initializeManager()
            }
        }
        .sheet(isPresented: $showRoomCode) {
            RoomCodeDisplayView()
                .environmentObject(authService)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
    }

    private func initializeManager() {
        Task {
            // Auto-create room for mothers if they don't have one
            if isMother && authService.currentUser?.roomCode == nil {
                do {
                    let roomCode = try await authService.createRoom()
                    print("✅ Room created: \(roomCode)")
                } catch {
                    print("❌ Error creating room: \(error)")
                }
            }

            // Wait a bit for room code to be set
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds

            // Now setup the manager with current user data
            let userId = authService.currentUser?.id
            let roomCode = authService.currentUser?.roomCode

            print("🔍 Initializing manager with:")
            print("   User ID: \(userId ?? "nil")")
            print("   Room Code: \(roomCode ?? "nil")")

            await MainActor.run {
                viewModel.setupManager(
                    modelContext: modelContext,
                    syncManager: syncManager,
                    userId: userId,
                    roomCode: roomCode,
                    userRole: authService.currentUser?.role
                )
                isInitialized = true
            }
        }
    }
}

private struct PageIndicators: View {
    @ObservedObject var viewModel: HeartbeatMainViewModel
    @ObservedObject var manager: HeartbeatSoundManager
    
    var body: some View {
        if manager.isRecording || manager.isPlayingPlayback || viewModel.selectedRecording != nil || !viewModel.allowTabViewSwipe {
            EmptyView()
        } else {
            VStack {
                Spacer()
                HStack(spacing: 8) {
                    // Timeline dot (page 0)
                    Circle()
                        .fill(viewModel.currentPage == 0 ? Color.white : Color.white.opacity(0.3))
                        .frame(width: 8, height: 8)
                        .animation(.easeInOut(duration: 0.2), value: viewModel.currentPage)
                    
                    // Orb dot (page 1)
                    Circle()
                        .fill(viewModel.currentPage == 1 ? Color.white : Color.white.opacity(0.3))
                        .frame(width: 8, height: 8)
                        .animation(.easeInOut(duration: 0.2), value: viewModel.currentPage)
                }
                .padding(.bottom, 20)
            }
            .transition(.opacity)
        }
    }
}

#Preview {
    HeartbeatMainView()
        .modelContainer(for: SavedHeartbeat.self, inMemory: true)
        .environmentObject(AuthenticationService())
        .environmentObject(HeartbeatSyncManager())
        .environmentObject(ThemeManager())
}
