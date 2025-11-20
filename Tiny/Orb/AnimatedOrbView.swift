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

struct AnimatedOrbView: View {
    @StateObject private var physicsController = OrbPhysicsController()
    var size: CGFloat = 200

    private let configuration = OrbConfiguration(
        backgroundColors: [.orange, .orbOrange, .clear],
        glowColor: .white.opacity(0.1),
        coreGlowIntensity: 0.1,
        showBackground: true,
        showWavyBlobs: true,
        showParticles: false,
        showGlowEffects: false,
        showShadow: false,
        speed: 30
    )

    var body: some View {
        ZStack {
            
            // 1. The Ring (behind)
            Circle()
                .stroke(
                    AngularGradient(
                        colors: [
                            .orbOrange.opacity(0.8),
                            .orbOrange.opacity(2),
                            .orbOrange.opacity(0.6)
                        ],
                        center: .center,
                        startAngle: .degrees(0),
                        endAngle: .degrees(360)
                    ),
                    lineWidth: 1.5
                )
                .blur(radius: 5)
                .frame(width: size * 1.175, height: size * 1.175)

            // 2. The Orb (in front)
            OrbView(configuration: configuration)
                .frame(width: size, height: size)
        }
        // animate the ring AND the orb together as one unit.
        .scaleEffect(x: physicsController.scaleX, y: physicsController.scaleY)
        .offset(x: physicsController.offsetX, y: physicsController.offsetY)
        .rotationEffect(.degrees(physicsController.rotation))
        .onAppear {
            physicsController.startPhysics()
        }
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        AnimatedOrbView()
    }
}
