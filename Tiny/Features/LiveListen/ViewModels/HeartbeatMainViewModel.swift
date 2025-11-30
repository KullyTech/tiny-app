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
    @Published var currentPage: Int = 0
    @Published var allowTabViewSwipe: Bool = true
    @Published var selectedRecording: Recording? = nil
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
        
        // Show SavedRecordingPlaybackView
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            selectedRecording = recording
        }
    }
}
