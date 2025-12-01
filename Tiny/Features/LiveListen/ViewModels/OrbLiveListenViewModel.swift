//
//  OrbLiveListenViewModel.swift
//  Tiny
//
//  Created by Benedictus Yogatama Favian Satyajati on 25/11/25.
//
import Foundation
internal import Combine
import SwiftUI

class OrbLiveListenViewModel: ObservableObject {
    @Published var isListening = false
    @Published var animateOrb = false
    @Published var showShareSheet = false
    @Published var isPlaybackMode = false
    
    @Published var isLongPressing = false
    @Published var longPressCountdown = 3
    @Published var longPressScale: CGFloat = 1.0
    @Published var dragOffset: CGFloat = 0
    @Published var isDraggingToSave = false
    @Published var isDraggingToDelete = false
    @Published var saveButtonScale: CGFloat = 1.0
    @Published var deleteButtonScale: CGFloat = 1.0
    @Published var orbDragScale: CGFloat = 1.0
    @Published var canSaveCurrentRecording = false
    @Published var currentTime: TimeInterval = 0
    
    var isHapticsEnabled: Bool {
        audioPostProcessingManager.isHapticsEnabled
    }
    
    func toggleHaptics() {
        audioPostProcessingManager.toggleHaptics()
    }

    private var longPressTimer: Timer?
    private var playbackTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    let audioPostProcessingManager = AudioPostProcessingManager()
    let physicsController = OrbPhysicsController()

    init() {
        // Subscribe to audioPostProcessingManager changes to trigger UI updates
        audioPostProcessingManager.objectWillChange
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }

    var orbScaleEffect: CGFloat {
        if isListening {
            return isLongPressing ? (animateOrb ? 1.6 : 1.1) * longPressScale : (animateOrb ? 1.5 : 1.0)
        } else if isPlaybackMode {
            return audioPostProcessingManager.isPlaying ? 1.3 : 0.8
        }
        return 1.0
    }
    
    func orbOffset(geometry: GeometryProxy) -> CGFloat {
        isListening ? geometry.size.height / 2 - 150 : 0
    }

    func handleOnAppear(recording: Recording?) {
        guard let recording = recording, !isListening, !isPlaybackMode else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.setupPlayback(for: recording)
        }
    }
    
    func setupPlayback(for recording: Recording) {
        // This is only called for fresh recordings after countdown
        isPlaybackMode = true
        animateOrb = true
        audioPostProcessingManager.stop()
        audioPostProcessingManager.loadAndPlay(fileURL: recording.fileURL)
        startPlaybackTimer()
    }

    func handleDragChange(value: SequenceGesture<LongPressGesture, DragGesture>.Value, geometry: GeometryProxy) {
        guard canSaveCurrentRecording || isPlaybackMode else { return }
        switch value {
        case .second(true, let drag):
            let translation = drag?.translation.height ?? 0
            
            if translation > 0 {
                // Dragging DOWN - Save
                isDraggingToSave = true
                isDraggingToDelete = false
                dragOffset = translation
                let maxDragDistance = geometry.size.height / 2
                let dragProgress = min(translation / maxDragDistance, 1.0)
                withAnimation(.interactiveSpring(response: 0.3, dampingFraction: 0.7)) {
                    orbDragScale = 1.0 - (dragProgress * 0.4)
                    saveButtonScale = 1.0 + (dragProgress * 0.4)
                    deleteButtonScale = 1.0
                }
            } else if translation < 0 {
                // Dragging UP - Delete
                isDraggingToDelete = true
                isDraggingToSave = false
                dragOffset = translation
                let maxDragDistance = geometry.size.height / 2
                let dragProgress = min(abs(translation) / maxDragDistance, 1.0)
                withAnimation(.interactiveSpring(response: 0.3, dampingFraction: 0.7)) {
                    orbDragScale = 1.0 - (dragProgress * 0.4)
                    deleteButtonScale = 1.0 + (dragProgress * 0.4)
                    saveButtonScale = 1.0
                }
            }
        default: break
        }
    }
    
    func handleDragEnd(value: SequenceGesture<LongPressGesture, DragGesture>.Value, geometry: GeometryProxy, onSave: @escaping () -> Void, onDelete: @escaping () -> Void) {
        guard canSaveCurrentRecording || isPlaybackMode else { return }
        switch value {
        case .second(true, let drag):
            let translation = drag?.translation.height ?? 0
            let threshold = geometry.size.height / 4
            
            if translation > threshold {
                // Dragged down enough - Save
                handleSaveRecording(onSave: onSave)
            } else if translation < -threshold {
                // Dragged up enough - Delete/Dismiss
                handleDeleteRecording(onDelete: onDelete)
            } else {
                // Not dragged enough - Reset
                resetDragState()
            }
        default: resetDragState()
        }
    }
    
    func resetDragState() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            dragOffset = 0
            orbDragScale = 1.0
            saveButtonScale = 1.0
            deleteButtonScale = 1.0
            isDraggingToSave = false
            isDraggingToDelete = false
        }
    }
    
    func handleSaveRecording(onSave: @escaping () -> Void) {
        guard canSaveCurrentRecording else { return }
        withAnimation(.interpolatingSpring(mass: 1, stiffness: 200, damping: 15)) {
            saveButtonScale = 1.6
            orbDragScale = 0.05
        }
        
        // Wait for animation to complete before saving and navigating
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            onSave()
            self.canSaveCurrentRecording = false
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.resetDragState()
            }
        }
    }
    
    func handleDeleteRecording(onDelete: @escaping () -> Void) {
        withAnimation(.interpolatingSpring(mass: 1, stiffness: 200, damping: 15)) {
            deleteButtonScale = 1.6
            orbDragScale = 0.05
        }
        
        // Wait for animation to complete before deleting and navigating
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            // Call the delete callback
            onDelete()
            
            // Stop playback and reset state
            self.audioPostProcessingManager.stop()
            self.stopPlaybackTimer()
            self.canSaveCurrentRecording = false
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    self.isPlaybackMode = false
                    self.animateOrb = false
                    self.resetDragState()
                }
            }
        }
    }

    func handleBackButton() {
        audioPostProcessingManager.stop()
        stopPlaybackTimer()
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            isPlaybackMode = false
            animateOrb = false
            isDraggingToSave = false
            dragOffset = 0
        }
    }
    
    func handleDoubleTap(onStart: @escaping () -> Void) {
        guard !isLongPressing, !isListening, !isPlaybackMode else { return }
        
        withAnimation(.interpolatingSpring(mass: 2, stiffness: 100, damping: 20)) {
            animateOrb = true
            isListening = true
        }
        onStart()
    }
    
    func handleSingleTap(lastRecording: Recording?) {
        guard isPlaybackMode, !isListening, !isLongPressing, !isDraggingToSave else {
            print("❌ Tap blocked - Mode check failed")
            return
        }

        print("👆 Single tap detected - isPlaying: \(audioPostProcessingManager.isPlaying)")

        if audioPostProcessingManager.isPlaying {
            print("⏸️ Pausing playback")
            audioPostProcessingManager.pause()
            stopPlaybackTimer()
        } else {
            print("▶️ Starting/resuming playback")
            if let lastRecording = lastRecording, audioPostProcessingManager.currentTime == 0 {
                audioPostProcessingManager.loadAndPlay(fileURL: lastRecording.fileURL)
            } else {
                audioPostProcessingManager.resume()
            }
            startPlaybackTimer()
        }
    }

    func handleLongPressChange(pressing: Bool) {
        guard isListening else { return }
        if pressing {
            startLongPressCountdown()
        } else {
            cancelLongPressCountdown()
        }
    }

    private func startPlaybackTimer() {
        stopPlaybackTimer()
        playbackTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.currentTime = self.audioPostProcessingManager.currentTime
            if !self.audioPostProcessingManager.isPlaying && self.currentTime >= self.audioPostProcessingManager.duration {
                self.stopPlaybackTimer()
            }
        }
    }

    private func stopPlaybackTimer() {
        playbackTimer?.invalidate()
        playbackTimer = nil
    }

    func startLongPressCountdown() {
        isLongPressing = true
        longPressCountdown = 3
        longPressScale = 1.0

        var tickCount = 0
        let totalTicks = 30
        let scaleIncrement = 0.15 / 30

        longPressTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            tickCount += 1

            if tickCount % 10 == 0 {
                withAnimation(.easeInOut(duration: 0.2)) { self.longPressCountdown -= 1 }
            }

            withAnimation(.linear(duration: 0.1)) { self.longPressScale += scaleIncrement }

            if tickCount >= totalTicks { timer.invalidate() }
        }
    }

    func cancelLongPressCountdown() {
        longPressTimer?.invalidate()
        longPressTimer = nil
        longPressCountdown = 3

        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            isLongPressing = false
            longPressScale = 1.0
        }
    }

    func handleLongPressComplete(onStop: @escaping () -> Void) {
        // Stop the timer but don't trigger separate animation
        longPressTimer?.invalidate()
        longPressTimer = nil
        longPressCountdown = 3

        // 1. First animation: Move orb to center and reset scale
        withAnimation(.spring(response: 0.8, dampingFraction: 0.8)) {
            isListening = false
            isLongPressing = false
            longPressScale = 1.0
            animateOrb = false
        }
        
        onStop()
        
        // 2. Second phase: Switch to playback mode after movement starts
        // We delay this slightly to prevent the GestureModifier from reconstructing the view
        // and cancelling the spring animation mid-flight.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation(.easeIn(duration: 0.3)) {
                self.isPlaybackMode = true
                self.canSaveCurrentRecording = true
            }
        }
    }
}
