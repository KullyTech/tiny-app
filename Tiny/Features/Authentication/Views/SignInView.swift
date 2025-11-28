//
//  SignInView.swift
//  Tiny
//
//  Created by Benedictus Yogatama Favian Satyajati on 26/11/25.
//

import SwiftUI
import AuthenticationServices

struct SignInView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var authService: AuthenticationService
    @State private var errorMessage: String?
    
    func makeTitle() -> AttributedString {
        var title = AttributedString("Let's Begin!")
        
        if let range = title.range(of: "Begin") {
            title[range].foregroundColor = Color("mainYellow")
        }
        
        return title
    }
    
    var body: some View {
        ZStack(alignment: .center) {
            Color.black.ignoresSafeArea()
            Image(themeManager.selectedBackground.imageName)
                .resizable()
                .scaledToFill()
                .clipped()
                .ignoresSafeArea()
            
            VStack(spacing: 100) {
                VStack(spacing: 12) {
                    Text(makeTitle())
                        .font(.title2.bold())
                    Text("You can always find guides and info in your profile later.")
                        .font(.body)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 56)
                
                Image("TinyMascot_Book")
                    .resizable()
                    .frame(width: 244, height: 188)
                
                VStack {
                    if let error = errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(8)
                            .padding(.horizontal)
                    }
                    SignInWithAppleButton(
                        onRequest: { request in
                            request.requestedScopes = [.email, .fullName]
                            request.nonce = authService.startSignInWithAppleFlow()
                        },
                        onCompletion: { result in
                            switch result {
                            case .success(let authorization):
                                Task {
                                    do {
                                        try await authService.signInWithApple(authorization: authorization)
                                    } catch {
                                        errorMessage = error.localizedDescription
                                    }
                                }
                            case .failure(let error):
                                errorMessage = error.localizedDescription
                            }
                        }
                    )
                    .signInWithAppleButtonStyle(.white)
                    .frame(height: 50)
                    .cornerRadius(12)
                    .padding(.horizontal, 40)
                }
            }
        }
    }
}

#Preview {
    SignInView()
        .environmentObject(AuthenticationService())
        .preferredColorScheme(.dark)
}
