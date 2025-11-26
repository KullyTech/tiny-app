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
    
    @State private var showRoomCode = false
    
    var body: some View {
        ZStack {
            if viewModel.showTimeline {
                PregnancyTimelineView(
                    heartbeatSoundManager: viewModel.heartbeatSoundManager,
                    showTimeline: $viewModel.showTimeline,
                    onSelectRecording: viewModel.handleRecordingSelection
                )
                .transition(.opacity)
            } else {
                OrbLiveListenView(
                    heartbeatSoundManager: viewModel.heartbeatSoundManager,
                    showTimeline: $viewModel.showTimeline
                )
                .transition(.opacity)
            }
            
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
            viewModel.setupManager(modelContext: modelContext)
            
            // Auto-create room for mothers if they don't have one
            if authService.currentUser?.role == .mother && authService.currentUser?.roomCode == nil {
                Task {
                    do {
                        _ = try await authService.createRoom()
                    } catch {
                        print("Error creating room: \(error)")
                    }
                }
            }
        }
        .sheet(isPresented: $showRoomCode) {
            RoomCodeDisplayView()
                .environmentObject(authService)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
    }
}

#Preview {
    HeartbeatMainView()
        .modelContainer(for: SavedHeartbeat.self, inMemory: true)
}
