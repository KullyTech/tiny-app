//
//  NameInputView.swift
//  Tiny
//
//  Created by Benedictus Yogatama Favian Satyajati on 27/11/25.
//

import SwiftUI

struct NameInputView: View {
    @EnvironmentObject var authService: AuthenticationService
    let selectedRole: UserRole
    let onContinue: () -> Void
    
    @State private var name: String = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    func makeTitle() -> AttributedString {
        var title = AttributedString("Hello Mom!")
        
        if let range = title.range(of: "Mom") {
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
                    Text("Tell me your name and step into your amazing journey")
                        .font(.body)
                        .multilineTextAlignment(.center)
                }
                VStack(alignment: .center, spacing: 56) {
                    Image("tinyMom")
                        .resizable()
                        .frame(width: 126, height: 136)
                    TextField("I can call you...", text: $name)
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(32)
                        .autocorrectionDisabled()
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
                Button(action: handleContinue) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Continue")
                            .fontWeight(.semibold)
                            .frame(height: 48)
                            .padding(.horizontal, 56)
                            .glassEffect()
                        
                    }
                }
                .buttonStyle(.plain)
                .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || isLoading)
                
            }
        }
        .onAppear {
            if let userName = authService.currentUser?.name, !userName.isEmpty {
                name = userName
            }
        }
    }
    
    func handleContinue() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                try await authService.updateUserName(name: name.trimmingCharacters(in: .whitespaces))
                if selectedRole == .mother {
                    try await authService.updateUserRole(role: selectedRole, pregnancyMonths: 5)
                } else {
                    onContinue()
                }
            } catch {
                errorMessage = error.localizedDescription
                isLoading = false
            }
            
            if selectedRole == .father {
                isLoading = false
            }
        }
    }
}

//#Preview {
//    NameInputView(selectedRole: .mother)
//        .environmentObject(AuthenticationService())
//        .preferredColorScheme(.dark)
//}
