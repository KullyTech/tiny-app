//
//  SavedRecordingPlaybackViewModel.swift
//  Tiny
//
//  Created by Tm Revanza Narendra Pradipta on 30/11/25.
//

import Foundation
import SwiftUI
internal import Combine
import AudioKit
import SwiftData

@MainActor
class SavedRecordingPlaybackViewModel: ObservableObject {
    @Published var isPlaying = false
    @Published var currentTime: TimeInterval = 0
    @Published var recordingName = "Heartbeat Recording"
    @Published var editedName = "Heartbeat Recording"
    @Published var isEditingName = false
    @Published var showSuccessAlert = false
    @Published var formattedDate = ""
    @Published var showShareSheet = false
    
    // Drag state
    @Published var dragOffset: CGFloat = 0
    @Published var orbDragScale: CGFloat = 1.0
    @Published var isDraggingToDelete = false
    @Published var deleteButtonScale: CGFloat = 1.0
    
    private var audioManager: HeartbeatSoundManager?
    private var currentRecording: Recording?
    private var modelContext: ModelContext?
    private var onRecordingUpdated: (() -> Void)?
    
    let audioPostProcessingManager = AudioPostProcessingManager()
    private var cancellables = Set<AnyCancellable>()
    
    var isHapticsEnabled: Bool {
        audioPostProcessingManager.isHapticsEnabled
    }
    
    init() {
        // Subscribe to audioPostProcessingManager changes to trigger UI updates
        audioPostProcessingManager.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.isPlaying = self.audioPostProcessingManager.isPlaying
                self.currentTime = self.audioPostProcessingManager.currentTime
            }
            .store(in: &cancellables)
    }
    
    func toggleHaptics() {
        audioPostProcessingManager.toggleHaptics()
        objectWillChange.send()
    }
    
    func setupPlayback(for recording: Recording, manager: HeartbeatSoundManager, modelContext: ModelContext, onRecordingUpdated: @escaping () -> Void) {
        self.audioManager = manager
        self.currentRecording = recording
        self.modelContext = modelContext
        self.onRecordingUpdated = onRecordingUpdated
        
        // Try to find the SavedHeartbeat entry to get custom name
        let filePath = recording.fileURL.path
        let descriptor = FetchDescriptor<SavedHeartbeat>(
            predicate: #Predicate { $0.filePath == filePath }
        )
        
        if let savedHeartbeat = try? modelContext.fetch(descriptor).first {
            // Use custom name if available, otherwise use filename
            if let customName = savedHeartbeat.displayName, !customName.isEmpty {
                self.recordingName = customName
            } else {
                let fileName = recording.fileURL.deletingPathExtension().lastPathComponent
                self.recordingName = fileName.replacingOccurrences(of: "recording-", with: "Recording ")
            }
        } else {
            // Fallback to filename
            let fileName = recording.fileURL.deletingPathExtension().lastPathComponent
            self.recordingName = fileName.replacingOccurrences(of: "recording-", with: "Recording ")
        }
        
        self.editedName = recordingName
        
        // Format date
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMMM yyyy"
        self.formattedDate = formatter.string(from: recording.createdAt)
        
        // Stop any existing playback in manager
        manager.stop()
        
        // Start playback with AudioPostProcessingManager
        audioPostProcessingManager.loadAndPlay(fileURL: recording.fileURL)
    }
    
    func togglePlayback(manager: HeartbeatSoundManager, recording: Recording) {
        if audioPostProcessingManager.isPlaying {
            audioPostProcessingManager.pause()
        } else {
            if audioPostProcessingManager.currentTime > 0 {
                audioPostProcessingManager.resume()
            } else {
                audioPostProcessingManager.loadAndPlay(fileURL: recording.fileURL)
            }
        }
    }
    
    func cleanup() {
        audioPostProcessingManager.stop()
    }
    
    func handleDragChange(value: DragGesture.Value, geometry: GeometryProxy) {
        let translation = value.translation.height
        dragOffset = translation
        
        // Only handle upward drag (delete)
        if translation < 0 {
            isDraggingToDelete = true
            let progress = min(abs(translation) / (geometry.size.height / 4), 1.0)
            orbDragScale = 1.0 - (progress * 0.3)
            deleteButtonScale = 1.0 + (progress * 0.6)
        } else {
            resetDragState()
        }
    }
    
    func handleDragEnd(value: DragGesture.Value, geometry: GeometryProxy, onDelete: @escaping () -> Void) {
        let translation = value.translation.height
        let threshold = geometry.size.height / 4
        
        if translation < -threshold {
            // Dragged up enough - Delete
            handleDelete(onDelete: onDelete)
        } else {
            // Not dragged enough - Reset
            resetDragState()
        }
    }
    
    private func handleDelete(onDelete: @escaping () -> Void) {
        withAnimation(.interpolatingSpring(mass: 1, stiffness: 200, damping: 15)) {
            deleteButtonScale = 1.6
            orbDragScale = 0.05
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            onDelete()
        }
    }
    
    private func resetDragState() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            dragOffset = 0
            orbDragScale = 1.0
            isDraggingToDelete = false
            deleteButtonScale = 1.0
        }
    }
    
    func startEditing() {
        isEditingName = true
    }
    
    func saveName() {
        recordingName = editedName
        isEditingName = false
        
        // Show success alert
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            showSuccessAlert = true
        }
        
        // Hide alert after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                self.showSuccessAlert = false
            }
        }
        
        // Save to SwiftData
        guard let recording = currentRecording,
              let modelContext = modelContext else {
            print("❌ Cannot save: missing recording or context")
            return
        }
        
        let filePath = recording.fileURL.path
        print("🔍 Looking for SavedHeartbeat with path: \(filePath)")
        
        let descriptor = FetchDescriptor<SavedHeartbeat>(
            predicate: #Predicate { heartbeat in
                heartbeat.filePath == filePath
            }
        )
        
        do {
            let results = try modelContext.fetch(descriptor)
            print("📊 Found \(results.count) matching recordings")
            
            if let savedHeartbeat = results.first {
                print("✏️ Updating recording: \(savedHeartbeat.filePath)")
                print("   Old name: \(savedHeartbeat.displayName ?? "nil")")
                print("   New name: \(editedName)")
                
                savedHeartbeat.displayName = editedName
                try modelContext.save()
                
                print("✅ Saved recording name: \(editedName)")
                
                // Trigger reload to update UI
                onRecordingUpdated?()
                
                // Sync to Firebase
                if let syncManager = self.audioManager?.syncManager {
                    Task {
                        do {
                            try await syncManager.updateHeartbeatName(savedHeartbeat, newName: editedName)
                        } catch {
                            print("❌ Failed to sync name update: \(error)")
                        }
                    }
                }
            } else {
                print("⚠️ Could not find SavedHeartbeat entry for path: \(filePath)")
                // List all recordings for debugging
                let allDescriptor = FetchDescriptor<SavedHeartbeat>()
                let allRecordings = try modelContext.fetch(allDescriptor)
                print("📝 All recordings in database:")
                for (index, rec) in allRecordings.enumerated() {
                    print("   [\(index)] \(rec.filePath)")
                }
            }
        } catch {
            print("❌ Error saving recording name: \(error)")
        }
    }
}