//
//  StartListeningButton.swift
//  Tiny
//
//  Created by Destu Cikal Ramdani on 28/10/25.
//

import SwiftUI

struct StartListeningButton: View {
    @State private var isPressed = false
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        Button(
            action: {
                print("Start Listening")
                isPressed.toggle()
            },
            label: {
                HStack(spacing: 8) {
                    Text("Start Listening")
                        .lineLimit(1)
                        .fontWeight(.bold)
                        .font(.title3)
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(colorScheme == .dark ?
                            AnyShapeStyle(Color.clear) :
                            AnyShapeStyle(.gradientPurpleWithShadow))
                .glassEffect(.clear.interactive())
                .clipShape(Capsule())
            })
        .sensoryFeedback(.impact(weight: .medium), trigger: isPressed)
    }
}

#Preview {
    StartListeningButton()
}
