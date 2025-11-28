//
//  TimelineAnimationController.swift
//  Tiny
//
//  Animation state management for timeline first-time experience
//

import SwiftUI
internal import Combine

enum AnimationPhase {
    case empty
    case drawingPath
    case showingDots
    case transformingOrb
    case showingProfile
    case complete
}

class TimelineAnimationController: ObservableObject {
    @Published var currentPhase: AnimationPhase = .empty
    @Published var pathProgress: CGFloat = 0.0
    @Published var dotsVisible: [Bool] = [false, false, false]
    @Published var orbVisible: Bool = false
    @Published var profileVisible: Bool = false
    
    // Timing constants (in seconds) - Slowed down for better visibility
    private let pathDuration: Double = 2.5  // Was 1.5
    private let dotDelay: Double = 0.5      // Was 0.33
    private let dotDuration: Double = 0.5   // Was 0.3
    private let transformDuration: Double = 1.0  // Was 0.7
    private let profileDuration: Double = 0.8    // Was 0.6
    
    func startAnimation() {
        currentPhase = .drawingPath
        animatePathDrawing()
    }
    
    private func animatePathDrawing() {
        withAnimation(.easeInOut(duration: pathDuration)) {
            pathProgress = 1.0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + pathDuration) {
            self.currentPhase = .showingDots
            self.animateDotsAppearing()
        }
    }
    
    private func animateDotsAppearing() {
        // Show dots sequentially
        for index in 0..<3 {
            DispatchQueue.main.asyncAfter(deadline: .now() + (Double(index) * dotDelay)) {
                withAnimation(.easeOut(duration: self.dotDuration)) {
                    self.dotsVisible[index] = true
                }
            }
        }
        
        // After all dots appear, transform first dot to orb
        let totalDotTime = Double(3) * dotDelay + dotDuration
        DispatchQueue.main.asyncAfter(deadline: .now() + totalDotTime) {
            self.currentPhase = .transformingOrb
            self.animateOrbTransform()
        }
    }
    
    private func animateOrbTransform() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.75)) {
            dotsVisible[0] = false
            orbVisible = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + transformDuration) {
            self.currentPhase = .showingProfile
            self.animateProfileAppear()
        }
    }
    
    private func animateProfileAppear() {
        withAnimation(.easeIn(duration: profileDuration)) {
            profileVisible = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + profileDuration) {
            self.currentPhase = .complete
        }
    }
    
    func skipAnimation() {
        currentPhase = .complete
        pathProgress = 1.0
        dotsVisible = [false, false, false]
        orbVisible = true
        profileVisible = true
    }
}
