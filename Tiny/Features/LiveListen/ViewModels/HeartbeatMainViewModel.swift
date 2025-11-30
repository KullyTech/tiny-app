//
//  HeartbeatMainViewModel.swift
//  Tiny
//
//  Created by Benedictus Yogatama Favian Satyajati on 25/11/25.
//
import Foundation
import SwiftUI
import SwiftData
internal import Combine

class HeartbeatMainViewModel: ObservableObject {
    @Published var currentPage = 0  // 0 = Timeline (left), 1 = Orb (right)
    let heartbeatSoundManager = HeartbeatSoundManager()
    
    func setupManager(
        modelContext: ModelContext,
        syncManager: HeartbeatSyncManager,
        userId: String?,
        roomCode: String?,
        userRole: UserRole?
    ) {
        heartbeatSoundManager.modelContext = modelContext
        heartbeatSoundManager.syncManager = syncManager
        heartbeatSoundManager.currentUserId = userId
        heartbeatSoundManager.currentRoomCode = roomCode
        heartbeatSoundManager.currentUserRole = userRole
        heartbeatSoundManager.loadFromSwiftData()
    }
    
    func handleRecordingSelection(_ recording: Recording) {
        print("🎵 Recording selected: \(recording.fileURL.lastPathComponent)")
        
        // Set as last recording (but don't auto-play)
        heartbeatSoundManager.lastRecording = recording
        
        // Switch to orb view (page 1) for playback
        // User will need to tap the orb to start playback
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            currentPage = 1
        }
    }
}
