//
//  AnimatedOrbView.swift
//  Tiny
//
//  Created by Destu Cikal Ramdani on 13/11/25.
//

import SwiftUI

struct AnimatedOrbView: View {
    private let configuration = OrbConfiguration(
        backgroundColors: [.yellow, .orange, .clear], // Custom gradient colors
        glowColor: .white,                            // Glow effect color
        coreGlowIntensity: 0.3,                       // Increased intensity for more visibility
        showBackground: true,                         // Toggle background visibility
        showWavyBlobs: true,                          // Toggle organic movement elements
        showParticles: false,                         // Toggle particle effects
        showGlowEffects: true,                        // Toggle glow effects
        showShadow: true,                             // Toggle shadow effects
        speed: 30,                                    // Increased speed for more dynamic wiggle
    )

    var body: some View {
        OrbView(configuration: configuration)
            .frame(width: 200, height: 200)
    }
}

#Preview {
    AnimatedOrbView()
}
