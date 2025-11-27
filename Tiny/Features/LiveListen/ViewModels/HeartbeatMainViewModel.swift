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
    @Published var showTimeline = false
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
        
        // Set as last recording
        heartbeatSoundManager.lastRecording = recording
        
        // Play the recording
        heartbeatSoundManager.togglePlayback(recording: recording)
        
        // Close timeline and go to orb view for playback (for both mother and father)
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            showTimeline = false
        }
    }
}
