//
// RealisticShadows.swift
// Tiny
//
// Portions of this file are derived from “Orb” by Siddhant Mehta
// Copyright (c) 2024 Siddhant Mehta
// Licensed under the MIT License.
// See: https://github.com/metasidd/Orb/blob/main/LICENSE
//
// Modifications made by Destu Cikal Ramdani on 2025-11-14.
//

import SwiftUI

struct RealisticShadowModifier: ViewModifier {
    let colors: [Color]
    let radius: CGFloat

    func body(content: Content) -> some View {
        content
            .background {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: colors,
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .blur(radius: radius * 0.75)
                    .opacity(0.5)
                    .offset(y: radius * 0.5)
            }
            .background {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: colors,
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .blur(radius: radius * 3)
                    .opacity(0.3)
                    .offset(y: radius * 0.75)
            }
    }
}

#Preview {
    Circle()
        .fill(.blue)
        .frame(width: 120, height: 120)
        .modifier(RealisticShadowModifier(colors: [.blue], radius: 10))
        .padding()
}
