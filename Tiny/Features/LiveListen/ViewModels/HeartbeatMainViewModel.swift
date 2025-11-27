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
    @AppStorage("hasSeenSwipeHint") var hasSeenSwipeHint = false
    let heartbeatSoundManager = HeartbeatSoundManager()
    
    func setupManager(modelContext: ModelContext) {
        heartbeatSoundManager.modelContext = modelContext
        heartbeatSoundManager.loadFromSwiftData()
    }
    
    func handleRecordingSelection(_ recording: Recording) {
        heartbeatSoundManager.lastRecording = recording
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            showTimeline = false
        }
    }
}
