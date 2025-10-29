//
//  PauseListeningButton.swift
//  Tiny
//
//  Created by Destu Cikal Ramdani on 29/10/25.
//

import SwiftUI

struct PauseListeningButton: View {
    @Binding var isExpanded: Bool
    @Binding var isPaused: Bool
    @Binding var isShowingStopAlert: Bool
    @Environment(\.colorScheme) var colorScheme
    @Namespace private var namespace

    var body: some View {
        ZStack {
            GlassEffectContainer(spacing: 40.0) {
                HStack(spacing: 40.0) {
                    Button(
                        action: {
                            withAnimation {
                                isPaused.toggle()
                                isExpanded = isPaused
                            }
                        },
                        label: {
                            HStack(spacing: 8) {
                                Image(systemName: isPaused ? "play.fill" : "pause.fill")
                                    .foregroundStyle(.white)
                                Text(isPaused ? "Continue" : "Pause")
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
                            .clipShape(Capsule())
                            .glassEffect(.clear.interactive())
                            .glassEffectID("continue", in: namespace)
                        }
                    )
                    .sensoryFeedback(.impact(weight: .medium), trigger: isExpanded)

                    if isExpanded {
                        Button(
                            action: {
                                print("Stop Listening")
                                withAnimation {
                                    isShowingStopAlert = true
                                }
                            }, label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "stop.circle")
                                        .foregroundStyle(.white)
                                    Text("Stop")
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
                                .clipShape(Capsule())
                                .glassEffect(.clear.interactive())
                                .glassEffectID("stop", in: namespace)
                            }
                        )
                        .sensoryFeedback(.impact(weight: .medium), trigger: isExpanded)
                    }
                }
            }
        }
    }
}

#Preview("PauseListeningButton") {
    struct PreviewWrapper: View {
        @State private var isExpanded = false
        @State private var isPaused = false
        @State private var isShowingStopAlert = false

        var body: some View {
            PauseListeningButton(
                isExpanded: $isExpanded,
                isPaused: $isPaused,
                isShowingStopAlert: $isShowingStopAlert
            )
            .padding()
            .background(Color(.systemBackground))
        }
    }
    return PreviewWrapper()
}
