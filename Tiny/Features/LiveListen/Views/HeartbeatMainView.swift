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
    
    // Check if user is a mother
    private var isMother: Bool {
        authService.currentUser?.role == .mother
    }
    
    var body: some View {
        ZStack {
            // TabView with swipe navigation
            TabView(selection: $viewModel.currentPage) {
                // Left page: Timeline (default)
                PregnancyTimelineView(
                    heartbeatSoundManager: viewModel.heartbeatSoundManager,
                    showTimeline: .constant(true),
                    onSelectRecording: viewModel.handleRecordingSelection,
                    isMother: isMother
                )
                .tag(0)
                
                // Right page: Orb Live Listen
                OrbLiveListenView(
                    heartbeatSoundManager: viewModel.heartbeatSoundManager,
                    showTimeline: Binding(
                        get: { viewModel.currentPage == 0 },
                        set: { if $0 { viewModel.currentPage = 0 } else { viewModel.currentPage = 1 } }
                    )
                )
                .tag(1)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .ignoresSafeArea()
            
            // Room Code Button (Top Right)
            VStack {
                HStack {
                    Spacer()
                    
                    Button(action: {
                        showRoomCode.toggle()
                    }) {
                        Image(systemName: "person.2.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                            .padding(12)
                            .background(Color.white.opacity(0.2))
                            .clipShape(Circle())
                    }
                    .padding(.trailing, 20)
                    .padding(.top, 50)
                }
                
                Spacer()
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

#Preview {
    HeartbeatMainView()
        .modelContainer(for: SavedHeartbeat.self, inMemory: true)
        .environmentObject(AuthenticationService())
        .environmentObject(HeartbeatSyncManager())
}
