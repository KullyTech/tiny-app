//
//  Gradients.swift
//  Tiny
//
//  Created by Destu Cikal Ramdani on 29/10/25.
//

import SwiftUI

extension ShapeStyle where Self == LinearGradient {
    static var gradientPurple: LinearGradient {
        LinearGradient(
            colors: [Color(.gradientStart), Color(.gradientEnd)],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    static var gradientPurpleWithShadow: some ShapeStyle {
        gradientPurple.shadow(.inner(color: Color.white, radius: 4, x: 0, y: 0))
    }
}
