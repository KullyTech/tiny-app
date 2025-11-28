//
//  RoleSelectionView.swift
//  Tiny
//
//  Created by Benedictus Yogatama Favian Satyajati on 26/11/25.
//

import SwiftUI

struct RoleSelectionView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var authService: AuthenticationService
    @Binding var selectedRole: UserRole?
    let onContinue: () -> Void
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            Image(themeManager.selectedBackground.imageName)
                .resizable()
                .scaledToFill()
                .clipped()
                .ignoresSafeArea()
            
            VStack(spacing: 100) {
                VStack(spacing: 12) {
                    Text("Get to Know You!")
                        .font(.title2.bold())
                    Text("So… are you the super Mom or the awesome Dad? Let’s step in!")
                        .font(.body)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 56)
                
                HStack(spacing: 24) {
                    RoleButton(
                        title: "Mom",
                        icon: "tinyMom",
                        isSelected: selectedRole == .mother
                    ) {
                        withAnimation(.spring(duration: 0.3)) {
                            selectedRole = .mother
                        }
                    }
                    RoleButton(
                        title: "Dad",
                        icon: "tinyDad",
                        isSelected: selectedRole == .father
                    ) {
                        withAnimation(.spring(duration: 0.3)) {
                            selectedRole = .father
                        }
                    }
                }
                
                continueButton
                    .padding(.horizontal, 40)
                
            }
        }
    }
    
    private var continueButton: some View {
        let enabled = selectedRole != nil
        
        return Button(
            action: {
                guard enabled else { return }
                onContinue()
            },
            label: {
                HStack {
                    Spacer()
                    Text("Continue")
                        .fontWeight(.semibold)
                        .frame(height: 48)
                        .padding(.horizontal, 56)
                        .glassEffect()
                    Spacer()
                }
                .contentShape(Rectangle())
            }
        )
        .buttonStyle(.plain)
        .disabled(selectedRole == nil)
        .opacity(enabled ? 1.0 : 0.65)
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: enabled)
    }
}

//#Preview {
//    RoleSelectionView()
//        .preferredColorScheme(.dark)
//}
