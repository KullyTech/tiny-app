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
    case weekInput  // For mothers only
    case roomCodeInput  // For fathers only
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
                        if role == .mother {
                            currentStep = .weekInput
                        } else {
                            currentStep = .roomCodeInput
                        }
                    }
                )
            case .weekInput:
                WeekInputView(onComplete: { week in
                    Task {
                        do {
                            // Update user role and pregnancy week in Firebase
                            try await authService.updateUserRole(role: .mother, pregnancyWeeks: week)
                            print("✅ Successfully saved pregnancy week: \(week)")
                        } catch {
                            print("❌ Error saving pregnancy week: \(error.localizedDescription)")
                        }
                    }
                })
            case .roomCodeInput:
                RoomCodeInputView()
            }
        }
    }
}

#Preview {
    OnboardingCoordinator()
}
