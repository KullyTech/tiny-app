//
//  BokehEffectView.swift
//  Tiny
//
//  Created by Destu Cikal Ramdani on 12/11/25.
//

import SwiftUI
internal import Combine

struct BokehEffectView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @Binding var amplitude: Float

    private var pulseOpacity: Double {
        let clampedAmplitude = min(max(Double(amplitude), 0.0), 1.0)
        return 0.15 + (clampedAmplitude * 0.6)
    }

    private var pulseScale: CGFloat {
        return 1.0 + CGFloat(amplitude) * 0.3
    }
    
    private var bokehColor: Color {
        themeManager.selectedOrbStyle.bokehColor
    }

    var body: some View {
        ZStack {
            // Layer 1: The Base Glow (Shifted Left)
            // This is the bottom layer, slightly less bright.
            Circle()
                .fill(bokehColor)
                .frame(width: 30)
                .opacity(pulseOpacity * 0.5)
                .scaleEffect(pulseScale * 1)
                .offset(x: -2)

            // Layer 2: The Core/Highlight (Shifted Right)
            // *** We apply .blendMode(.screen) here to brighten the overlap ***
            Circle()
                .fill(bokehColor)
                .frame(width: 30)
                .opacity(pulseOpacity * 0.5)
                .scaleEffect(pulseScale * 1.1)
                .offset(x: 1, y: -2)
                .blendMode(
                    .hardLight
                ) // Makes the overlapping area brighter (like adding light)
        }
        .blur(radius: 1)
        .animation(.easeInOut(duration: 0.2), value: amplitude)
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var dummyAmplitude: Float = 0.5
        let timer = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()

        var body: some View {
            ZStack {
                Color.black.ignoresSafeArea()
                BokehEffectView(amplitude: $dummyAmplitude)
                    .onReceive(timer) { _ in
                        withAnimation {
                            dummyAmplitude = Float.random(in: 0.2...0.9)
                        }
                    }
            }
        }
    }
    return PreviewWrapper()
}
