//
//  RoomCodeInputView.swift
//  Tiny
//
//  Created by Benedictus Yogatama Favian Satyajati on 27/11/25.
//

import SwiftUI

struct RoomCodeInputView: View {
    @EnvironmentObject var authService: AuthenticationService
    
    @State private var roomCode: String = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    func makeTitle() -> AttributedString {
        var title = AttributedString("Together Starts Here")
        
        if let range = title.range(of: "Together") {
            title[range].foregroundColor = Color("mainYellow")
        }
        
        return title
    }
    
    var body: some View {
        ZStack {
            Image("backgroundPurple")
                .resizable()
                .scaledToFill()
                .clipped()
                .ignoresSafeArea()
            
            VStack(spacing: 100) {
                VStack(spacing: 12) {
                    Text(makeTitle())
                        .font(.title2.bold())
                    Text("Enter the code from Mom to join your shared parent space.")
                        .font(.body)
                        .multilineTextAlignment(.center)
                }
                VStack(alignment: .center, spacing: 56) {
                    Image("tinyMom")
                        .resizable()
                        .frame(width: 126, height: 136)
                    TextField("Enter code", text: $roomCode)
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(32)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.characters)
                        .padding(.horizontal, 40)
                    if let error = errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(8)
                    }
                }
                VStack(spacing: 12) {
                    Button(action: handleJoinRoom) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Join Room")
                                .fontWeight(.semibold)
                                .frame(height: 48)
                                .padding(.horizontal, 56)
                                .glassEffect()
                            
                        }
                    }
                    .buttonStyle(.plain)
                    .disabled(roomCode.trimmingCharacters(in: .whitespaces).isEmpty || isLoading)
                    Button(action: handleSkip) {
                        Text("Skip")
                            .fontWeight(.medium)
                            .foregroundStyle(Color(.systemGray))
                    }
                    .buttonStyle(.plain)
                    .disabled(isLoading)
                }
                
            }
        }
    }
    
    private func handleJoinRoom() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let code = roomCode.trimmingCharacters(in: .whitespaces).uppercased()
                try await authService.updateUserRole(role: .father, roomCode: code)
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
    
    func handleSkip() {
        Task {
            do {
                try await authService.updateUserRole(role: .father)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}

#Preview {
    RoomCodeInputView()
        .preferredColorScheme(.dark)
}
