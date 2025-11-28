//
//  OnboardingCoordinator.swift
//  Tiny
//
//  Created by Benedictus Yogatama Favian Satyajati on 27/11/25.
//

import SwiftUI

enum OnboardingStep {
    case roleSelection
    case nameInput(role: UserRole)
    case roomCodeInput
}

struct OnboardingCoordinator: View {
    @EnvironmentObject var authService: AuthenticationService
    @State private var currentStep: OnboardingStep = .roleSelection
    @State private var selectedRole: UserRole?
    
    var body: some View {
        Group {
            switch currentStep {
            case .roleSelection:
                RoleSelectionView(
                    selectedRole: $selectedRole,
                    onContinue: {
                        if let role = selectedRole {
                            currentStep = .nameInput(role: role)
                        }
                    }
                )
            case .nameInput(let role):
                NameInputView(
                    selectedRole: role,
                    onContinue: {
                        if role == .father {
                            currentStep = .roomCodeInput
                        }
                    }
                )
            case .roomCodeInput:
                RoomCodeInputView()
            }
        }
    }
}

#Preview {
    OnboardingCoordinator()
}
