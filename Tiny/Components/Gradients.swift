//
//  Gradients.swift
//  Tiny
//
//  Created by Destu Cikal Ramdani on 29/10/25.
//

import SwiftUI

extension ShapeStyle where Self == LinearGradient {
    private static func makeGradient(
        _ colors: [Color],
        start: UnitPoint = .leading,
        end: UnitPoint = .trailing
    ) -> LinearGradient {
        LinearGradient(colors: colors, startPoint: start, endPoint: end)
    }
    
    private static func withInnerWhiteShadow<S: ShapeStyle>(_ style: S) -> some ShapeStyle {
        style.shadow(.inner(color: .white, radius: 4, x: 0, y: 0))
    }

    static var gradientPurple: LinearGradient {
        makeGradient([Color(.gradientStart), Color(.gradientEnd)])
    }

    static var gradientPinkPurple: LinearGradient {
        makeGradient(
            [Color(hex: "FDBBEB"), Color(hex: "9595E8")],
            start: UnitPoint(x: 0.09, y: -0.12),
            end: UnitPoint(x: 1.03, y: 1)
        )
    }

    static var gradientYellowPink: LinearGradient {
        makeGradient(
            [Color(hex: "FFDE90"), Color(hex: "FFA8E2")],
            start: UnitPoint(x: 0.09, y: -0.12),
            end: UnitPoint(x: 1.03, y: 1)
        )
    }
    
    static var gradientPurpleWithShadow: some ShapeStyle {
        withInnerWhiteShadow(gradientPurple)
    }
    
    static var gradientPinkPurpleWithShadow: some ShapeStyle {
        withInnerWhiteShadow(gradientPinkPurple)
    }
    
    static var gradientYellowPinkWithShadow: some ShapeStyle {
        withInnerWhiteShadow(gradientYellowPink)
    }
}
