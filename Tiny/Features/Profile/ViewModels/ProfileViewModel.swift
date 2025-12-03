//
//  ProfileViewModel.swift
//  Tiny
//
//  Created by Destu Cikal Ramdani on 26/11/25.
//

import SwiftUI
internal import Combine

@MainActor
class ProfileViewModel: ObservableObject {
    // Observe the singleton manager so this ViewModel publishes changes when manager changes
    var manager = UserProfileManager.shared
    private var cancellables = Set<AnyCancellable>()
    @AppStorage("appTheme") var appTheme: String = "System"

    init() {
        // Propagate manager changes to this ViewModel
        manager.objectWillChange
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Computed Properties for View Bindings
    
    var isSignedIn: Bool {
        get { manager.isSignedIn }
        set { manager.isSignedIn = newValue }
    }
    




    // For ImagePicker binding
    var profileImage: UIImage? {
        get { manager.profileImage }
        set { manager.saveProfileImage(newValue) }
    }

    // MARK: - Actions




    func signOut() {
        manager.signOut()
        print("User signed out")
    }
    
    func deleteAccount() async throws {
        manager.deleteAllData()
    }
}
