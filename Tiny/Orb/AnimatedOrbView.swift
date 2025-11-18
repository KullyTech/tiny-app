// AnimatedOrbView.swift
// Tiny
//
// Portions of this file are derived from "Orb" by Siddhant Mehta
// Copyright (c) 2024 Siddhant Mehta
// Licensed under the MIT License.
// See: https://github.com/metasidd/Orb/blob/main/LICENSE
//
// Modifications made by Destu Cikal Ramdani on 2025-11-18.
//

import SwiftUI
import SpriteKit
internal import Combine

struct AnimatedOrbView: View {
    @StateObject private var physicsController = OrbPhysicsController()

    private let configuration = OrbConfiguration(
        backgroundColors: [.orange, Color(hex: "F0AC45"), .clear],
        glowColor: .white.opacity(0.9),
        coreGlowIntensity: 0.3,
        showBackground: true,
        showWavyBlobs: true,
        showParticles: false,
        showGlowEffects: false,
        showShadow: true,
        speed: 30
    )

    var body: some View {
        OrbView(configuration: configuration)
            .frame(width: 200, height: 200)
            .scaleEffect(x: physicsController.scaleX, y: physicsController.scaleY)
            .offset(x: physicsController.offsetX, y: physicsController.offsetY)
            .rotationEffect(.degrees(physicsController.rotation))
            .onAppear {
                physicsController.startPhysics()
            }
    }
}

class OrbPhysicsController: ObservableObject {
    @Published var offsetX: CGFloat = 0
    @Published var offsetY: CGFloat = 0
    @Published var scaleX: CGFloat = 1.0
    @Published var scaleY: CGFloat = 1.0
    @Published var rotation: Double = 0

    private var time: Double = 0.0
    private var displayLink: CADisplayLink?

    func startPhysics() {
        displayLink = CADisplayLink(target: self, selector: #selector(update))
        displayLink?.add(to: .main, forMode: .common)
    }

    @objc private func update() {
        // Increment time. A smaller number means a slower, more "amniotic" feel.
        time += 0.05

        // --- Tunable Parameters ---
        let driftAmount: CGFloat = 10.0   // How far it wanders from the center
        let wobbleAmount: CGFloat = 0.1  // How much it "jiggles"
        let rotationAmount: Double = 5.0 // How much it slowly turns
        let smoothing: CGFloat = 0.05    // How "heavy" or "watery" the motion feels
        // -------------------------

        // 1. Organic "Floating" (Offset)
        // We use two different sine waves for each axis.
        // This creates a complex, non-linear drift.
        let targetOffsetX = (sin(time * 0.3) * driftAmount) + (cos(time * 0.7) * driftAmount * 0.5)
        let targetOffsetY = (cos(time * 0.2) * driftAmount) + (sin(time * 0.5) * driftAmount * 0.5)

        // 2. Asymmetric "Wobble" (Scale)
        // X and Y now scale independently, using different wave combinations.
        let baseScale: CGFloat = 1.0
        let targetScaleX = baseScale + (sin(time * 0.8) * wobbleAmount) + (cos(time * 0.3) * wobbleAmount * 0.5)
        let targetScaleY = baseScale + (cos(time * 0.6) * wobbleAmount) + (sin(time * 0.2) * wobbleAmount * 0.5)

        // 3. Slow "Turning" (Rotation)
        // A very slow rotation frequency for a gentle turn.
        let targetRotation = sin(time * 0.15) * rotationAmount

        // 4. Smoothly apply all changes (the "liquid" feel)
        offsetX += (targetOffsetX - offsetX) * smoothing
        offsetY += (targetOffsetY - offsetY) * smoothing
        scaleX += (targetScaleX - scaleX) * smoothing
        scaleY += (targetScaleY - scaleY) * smoothing
        rotation += (targetRotation - rotation) * smoothing
    }

    deinit {
        displayLink?.invalidate()
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        AnimatedOrbView()
    }
}
