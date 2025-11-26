//
//  RoomCodeDisplayView.swift
//  Tiny
//
//  Created by Benedictus Yogatama Favian Satyajati on 27/11/25.
//


//
//  RoomCodeDisplayView.swift
//  Tiny
//
//  Created by Benedictus Yogatama Favian Satyajati on 27/11/25.
//

import SwiftUI

struct RoomCodeDisplayView: View {
    @EnvironmentObject var authService: AuthenticationService
    @Environment(\.dismiss) var dismiss
    @State private var showCopiedMessage = false
    
    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                // Header
                HStack {
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 10)
                
                Spacer()
                
                // Icon
                Image(systemName: "person.2.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.pink)
                
                // Title
                VStack(spacing: 10) {
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
                    VStack(spacing: 15) {
                        Text(roomCode)
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .tracking(8)
                            .foregroundColor(.primary)
                            .padding(.vertical, 20)
                            .padding(.horizontal, 40)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color(.systemGray6))
                            )
                        
                        // Copy Button
                        Button(action: copyRoomCode) {
                            HStack(spacing: 8) {
                                Image(systemName: showCopiedMessage ? "checkmark" : "doc.on.doc")
                                    .font(.system(size: 16))
                                Text(showCopiedMessage ? "Copied!" : "Copy Code")
                                    .fontWeight(.medium)
                            }
                            .foregroundColor(showCopiedMessage ? .green : .blue)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(showCopiedMessage ? Color.green.opacity(0.1) : Color.blue.opacity(0.1))
                            )
                        }
                    }
                } else {
                    VStack(spacing: 15) {
                        if authService.currentUser?.role == .mother {
                            ProgressView()
                                .padding()
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
                Spacer()
            }
        }
    }
    
    private func copyRoomCode() {
        if let roomCode = authService.currentUser?.roomCode {
            UIPasteboard.general.string = roomCode
            
            withAnimation {
                showCopiedMessage = true
            }
            
            // Reset after 2 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation {
                    showCopiedMessage = false
                }
            }
        }
    }
}

#Preview {
    RoomCodeDisplayView()
        .environmentObject(AuthenticationService())
}