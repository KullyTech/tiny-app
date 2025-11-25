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
    @Published var saveButtonScale: CGFloat = 1.0
    @Published var orbDragScale: CGFloat = 1.0
    @Published var canSaveCurrentRecording = false
    
    private var longPressTimer: Timer?
    
    let audioPostProcessingManager = AudioPostProcessingManager()
    let physicsController = OrbPhysicsController()

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
        isPlaybackMode = true
        animateOrb = true
        audioPostProcessingManager.stop()
        audioPostProcessingManager.loadAndPlay(fileURL: recording.fileURL)
    }

    func handleDragChange(value: SequenceGesture<LongPressGesture, DragGesture>.Value, geometry: GeometryProxy) {
        guard canSaveCurrentRecording else { return }
        switch value {
        case .second(true, let drag):
            isDraggingToSave = true
            let translation = max(0, drag?.translation.height ?? 0)
            dragOffset = translation
            let maxDragDistance = geometry.size.height / 2
            let dragProgress = min(translation / maxDragDistance, 1.0)
            withAnimation(.interactiveSpring(response: 0.3, dampingFraction: 0.7)) {
                orbDragScale = 1.0 - (dragProgress * 0.4)
                saveButtonScale = 1.0 + (dragProgress * 0.4)
            }
        default: break
        }
    }
    
    func handleDragEnd(value: SequenceGesture<LongPressGesture, DragGesture>.Value, geometry: GeometryProxy, onSave: @escaping () -> Void) {
        guard canSaveCurrentRecording else { return }
        switch value {
        case .second(true, let drag):
            let translation = drag?.translation.height ?? 0
            if translation > geometry.size.height / 4 {
                handleSaveRecording(onSave: onSave)
            } else {
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
            isDraggingToSave = false
        }
    }
    
    func handleSaveRecording(onSave: @escaping () -> Void) {
        guard canSaveCurrentRecording else { return }
        withAnimation(.interpolatingSpring(mass: 1, stiffness: 200, damping: 15)) {
            saveButtonScale = 1.6
            orbDragScale = 0.05
        }
        onSave()
        canSaveCurrentRecording = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.resetDragState()
        }
    }

    func handleBackButton() {
        audioPostProcessingManager.stop()
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
        guard isPlaybackMode, !isListening, !isLongPressing, !isDraggingToSave else { return }
        guard let lastRecording = lastRecording else { return }
        if audioPostProcessingManager.isPlaying {
            audioPostProcessingManager.pause()
        } else if audioPostProcessingManager.currentTime > 0 {
            audioPostProcessingManager.resume()
        } else {
            audioPostProcessingManager.loadAndPlay(fileURL: lastRecording.fileURL)
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
        isLongPressing = false
        longPressCountdown = 3
        longPressScale = 1.0
        longPressTimer?.invalidate()
        longPressTimer = nil
    }
    
    func handleLongPressComplete(onStop: @escaping () -> Void) {
        cancelLongPressCountdown()
        
        withAnimation(.interpolatingSpring(mass: 2, stiffness: 100, damping: 20)) {
            isListening = false
            animateOrb = false
            isPlaybackMode = true
            canSaveCurrentRecording = true
        }
        
        onStop()
    }
    
    func handleSelectRecordingFromTimeline(_ recording: Recording, onSelect: @escaping (Recording) -> Void) {
        isListening = false
        
        withAnimation(.easeInOut(duration: 0.4)) {
            isPlaybackMode = true
            canSaveCurrentRecording = false
            animateOrb = true
        }

        audioPostProcessingManager.stop()
        audioPostProcessingManager.loadAndPlay(fileURL: recording.fileURL)
        
        onSelect(recording)
    }
}
