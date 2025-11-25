//
//  SelectLiveListenButton.swift
//  Tiny
//
//  Created by Destu Cikal Ramdani on 30/10/25.
//

import SwiftUI

struct SelectLiveListenButton: View {
    @Environment(\.colorScheme) var colorScheme
    @State private var animateLiveListenSymbol = false
    @State private var animateRecordListenSymbol = false

    var body: some View {
        VStack(spacing: 16) {
            button(
                title: "Live Listen and Record",
                systemImage: "airpods.gen3",
                animate: $animateLiveListenSymbol
            )

            button(
                title: "Record and Listen Later",
                systemImage: "waveform.badge.microphone",
                animate: $animateRecordListenSymbol
            )
        }
    }

    private func button(
        title: String,
        systemImage: String,
        animate: Binding<Bool>
    ) -> some View {
        Button {
            animate.wrappedValue.toggle()
        } label: {
            HStack(spacing: 8) {
                Text(title)
                    .font(.title3.weight(.bold))
                    .foregroundColor(.white)
                    .lineLimit(1)

                Image(systemName: systemImage)
                    .font(.title.weight(.bold))
                    .foregroundColor(.white)
                    .symbolEffect(.bounce, value: animate.wrappedValue)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
            .background(
                colorScheme == .dark
                ? AnyShapeStyle(Color.clear)
                : AnyShapeStyle(.gradientPurpleWithShadow)
            )
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .glassEffect(.clear.interactive(), in: .rect(cornerRadius: 20))
        }
        .sensoryFeedback(.impact(weight: .medium), trigger: animate.wrappedValue)
    }
}

#Preview {
    SelectLiveListenButton()
}
