//
//  RippleEffect.swift
//  Tiny
//
//  Created by Destu Cikal Ramdani on 11/11/25.
//

import SwiftUI

// MARK: - Ripple Effect View
struct RippleEffectView: View {
    @State private var ripples: [RippleState] = []
    @State private var animationTimer: Timer?

    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [Color(hex: "5B9FD8"), Color(hex: "4A8BC2")],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // Ripple layers
            ZStack {
                ForEach(ripples) { ripple in
                    Ellipse()
                        .stroke(
                            Color.white.opacity(ripple.opacity),
                            lineWidth: 2
                        )
                        .frame(
                            width: ripple.size,
                            height: ripple.size * 0.6
                        )
                }
            }
        }
        .onAppear {
            startRippleAnimation()
        }
        .onDisappear {
            animationTimer?.invalidate()
        }
    }

    private func startRippleAnimation() {
        // Create initial ripples with staggered delays
        for index in 0..<6 {
            let delay = Double(index) * 0.4
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                addRipple()
            }
        }

        // Add new ripple every 2.4 seconds
        animationTimer = Timer.scheduledTimer(withTimeInterval: 2.4, repeats: true) { _ in
            addRipple()
        }
    }

    private func addRipple() {
        let newRipple = RippleState()
        ripples.append(newRipple)

        withAnimation(.easeOut(duration: 4.0)) {
            if let index = ripples.firstIndex(where: { $0.id == newRipple.id }) {
                ripples[index].size = 500
                ripples[index].opacity = 0.0
            }
        }

        // Remove ripple after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
            ripples.removeAll { $0.id == newRipple.id }
        }
    }
}

// MARK: - Ripple State
struct RippleState: Identifiable {
    let id = UUID()
    var size: CGFloat = 40
    var opacity: Double = 0.7
}

#Preview {
    RippleEffectView()
}
