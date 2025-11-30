//
//  RoomCodeDisplayView.swift
//  Tiny
//
//  Created by Benedictus Yogatama Favian Satyajati on 27/11/25.
//

import SwiftUI
import UIKit

struct RoomCodeDisplayView: View {
    @EnvironmentObject var authService: AuthenticationService
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) var dismiss
    @State private var showCopiedMessage = false

    var body: some View {
        ZStack {
            Color(hex: "030411").ignoresSafeArea()

            // Bottom circular glow
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            themeManager.selectedBackground.color.opacity(1),
                            themeManager.selectedBackground.color.opacity(0)
                        ]),
                        center: .center,
                        startRadius: 0,
                        endRadius: 600
                    )
                )
                .frame(width: 200, height: 200)
                .blur(radius: 60)
                .offset(y: 120) // Near bottom

            VStack(spacing: 10) {
                // Header
                HStack {
                    Spacer()
                    Button(action: {
                        dismiss()
                    }, label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.secondary)
                    })
                }
                .padding(.horizontal)
                .padding(.top, 10)

                Spacer()

                // Icon
                Image("yellowHeart")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30)

                // Title
                VStack(spacing: 5) {
                    Text(authService.currentUser?.role == .mother ? "Your Room Code" : "Room Code")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text(authService.currentUser?.role == .mother ?
                         "Share this code with your partner" :
                            "You're connected to this room")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                }

                // Room Code Display
                if let roomCode = authService.currentUser?.roomCode {
                    Button(action: copyRoomCode) {
                        HStack {
                            Text(roomCode)
                                .font(.system(size: 18, weight: .heavy, design: .rounded))
                                .tracking(3)
                                .foregroundColor(.white)
                            Image(systemName: "doc.on.doc")
                                .foregroundColor(.white)
                        }
                        .padding(.vertical, 20)
                        .padding(.horizontal, 40)
                        .background(
                            // Frosted capsule background
                            Capsule()
                                .fill(.ultraThinMaterial) // frosted glass effect
                                .opacity(0.8)
                        )
                    }
                } else {
                    VStack(spacing: 15) {
                        if authService.currentUser?.role == .mother {
                            ProgressView().padding()
                            Text("Creating room...")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        } else {
                            Text("No room code")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text("Ask your partner for their room code")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                        }
                    }
                }
                Spacer()
            }
        }
    }

    private func copyRoomCode() {
        if let roomCode = authService.currentUser?.roomCode {
            UIPasteboard.general.string = roomCode
            withAnimation { showCopiedMessage = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation { showCopiedMessage = false }
            }
        }
    }
}

#Preview {
    RoomCodeDisplayView()
        .environmentObject(AuthenticationService())
        .environmentObject(ThemeManager())
}

#Preview {
    // Create a mock AuthenticationService with a sample user
    let authService = AuthenticationService()
    authService.currentUser = User(
        id: "1",
        email: "mother@example.com",
        name: "Jane Doe",
        role: .mother,
        pregnancyWeeks: 20,
        roomCode: "ABCD12", // Sample room code
        createdAt: Date()
    )

    let themeManager = ThemeManager()

    return RoomCodeDisplayView()
        .environmentObject(authService)
        .environmentObject(themeManager)
        .preferredColorScheme(.dark) // Optional: show dark mode preview
}
