//
//  StartListeningButton.swift
//  Tiny
//
//  Created by Destu Cikal Ramdani on 28/10/25.
//

import SwiftUI

let gradientPurple = LinearGradient(
    colors: [Color(.gradientStart), Color(.gradientEnd)],
    startPoint: .leading,
    endPoint: .trailing
)

struct StartListeningButton: View {
    @State private var isPressed = false
    @Environment(\.colorScheme) var colorScheme

    private var gradientWithShadow: some ShapeStyle {
        gradientPurple.shadow(.inner(color: Color.white, radius: 4, x: 0, y: 0))
    }

    var body: some View {
        Button(action: {
            print("Start Listening")
            isPressed.toggle()
        }, label: {
            HStack(spacing: 8) {
                Text("Start Listening")
                    .lineLimit(1)
                    .fontWeight(.bold)
                    .font(.title3)
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(colorScheme == .dark ? AnyShapeStyle(Color.clear) : AnyShapeStyle(gradientWithShadow))
            .glassEffect(.clear.interactive())
            .clipShape(Capsule())
        })
        .sensoryFeedback(.impact(weight: .medium), trigger: isPressed)
    }
}

#Preview {
    StartListeningButton()
}
