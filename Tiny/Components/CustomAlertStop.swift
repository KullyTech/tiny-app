//
//  CustomAlertStop.swift
//  Tiny
//
//  Created by Destu Cikal Ramdani on 29/10/25.
//

import SwiftUI

struct CustomStopAlert: View {
    @Binding var isPresented: Bool
    @Environment(\.colorScheme) var colorScheme
    let onStop: () -> Void

    var body: some View {
        ZStack {
            // Background overlay
            Color.black.opacity(0.2)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation {
                        isPresented = false
                    }
                }

            // Alert content
            VStack(spacing: 20) {
                VStack(spacing: 8) {
                    Text("Stop this session?")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)

                    Text("Your recording will be saved automatically in your library.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }

                HStack(spacing: 12) {
                    // Cancel Button
                    Button {
                        withAnimation {
                            isPresented = false
                        }
                    } label: {
                        Text("Cancel")
                            .fontWeight(.regular)
                            .font(.body)
                            .foregroundColor(.gray)
                            .buttonSizing(.flexible)
                            .padding(.vertical, 16)
                            .padding(.horizontal, 16)
                            .background(Color(.systemGray5))
                            .clipShape(Capsule())
                            .glassEffect(.clear.interactive())
                    }

                    // Stop Button with gradient
                    Button {
                        onStop()
                        withAnimation {
                            isPresented = false
                        }
                    } label: {
                        Text("Stop & Save")
                            .fontWeight(.bold)
                            .font(.body)
                            .foregroundColor(colorScheme == .dark ? .white : .white)
                            .buttonSizing(.flexible)
                            .padding(.vertical, 16)
                            .padding(.horizontal, 16)
                            .background(
                                colorScheme == .dark ?
                                AnyShapeStyle(.black) :
                                    AnyShapeStyle(.gradientPurpleWithShadow)
                            )
                            .clipShape(Capsule())
                            .glassEffect(.clear.interactive())
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        colorScheme == .dark ? Color(.gray).opacity(0.2) : Color(
                            .systemBackground
                        )
                    )
                    .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
            )
            .padding(.horizontal, 40)
        }
    }
}

#Preview {
    @Previewable @State var isPresented = true

    ZStack {
        Color(.systemBackground)
            .ignoresSafeArea()

        Button("Show Alert") {
            withAnimation {
                isPresented.toggle()
            }
        }

        CustomStopAlert(isPresented: $isPresented) {
            print("Stop tapped")
        }
    }
}
