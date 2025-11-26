//
//  ProfileViewModel.swift
//  Tiny
//
//  Created by Destu Cikal Ramdani on 26/11/25.
//

import SwiftUI
internal import Combine

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
<<<<<<< HEAD

    @AppStorage("appTheme") var appTheme: String = "System"

=======
    
    @AppStorage("appTheme") var appTheme: String = "System"
    
>>>>>>> 1fbb098 (feat: add profile navigation in PregnancyTimelineView)
    init() {
        // Propagate manager changes to this ViewModel
        manager.objectWillChange
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }
<<<<<<< HEAD

    // MARK: - Computed Properties for View Bindings

=======
    
    // MARK: - Computed Properties for View Bindings
    
>>>>>>> 1fbb098 (feat: add profile navigation in PregnancyTimelineView)
    var isSignedIn: Bool {
        manager.isSignedIn
    }
    
    var userName: String {
        get { manager.userName }
        set { manager.userName = newValue }
    }
    
    var userEmail: String? {
        manager.userEmail
    }
    
    // For ImagePicker binding
    var profileImage: UIImage? {
        get { manager.profileImage }
        set { manager.saveProfileImage(newValue) }
    }
    
    // MARK: - Actions

<<<<<<< HEAD
    var userName: String {
        get { manager.userName }
        set { manager.userName = newValue }
    }

    var userEmail: String? {
        manager.userEmail
    }

    // For ImagePicker binding
    var profileImage: UIImage? {
        get { manager.profileImage }
        set { manager.saveProfileImage(newValue) }
    }

=======
    func saveName() {
        manager.saveUserData()
        print("Name saved: \(manager.userName)")
    }

>>>>>>> 1fbb098 (feat: add profile navigation in PregnancyTimelineView)
    func signIn() {
        manager.signInDummy()
        print("User signed in (dummy)")
    }

    func signOut() {
        manager.signOut()
        print("User signed out")
    }
}

