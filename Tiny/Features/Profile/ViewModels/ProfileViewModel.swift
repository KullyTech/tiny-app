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
    @Published var isSignedIn: Bool = false
    @Published var profileImage: UIImage?
    @Published var userName: String = "Guest"
    @Published var userEmail: String?

    // Settings
    @AppStorage("appTheme") var appTheme: String = "System"
    @AppStorage("isUserSignedIn") private var storedSignInStatus: Bool = false
    @AppStorage("savedUserName") private var savedUserName: String?
    @AppStorage("savedUserEmail") private var savedUserEmail: String?

    private var cancellables = Set<AnyCancellable>()

    init() {
        loadUserData()
    }

    // MARK: - Data Persistence

    private func loadUserData() {
        isSignedIn = storedSignInStatus

        if let savedName = savedUserName {
            userName = savedName
        }

        if let savedEmail = savedUserEmail {
            userEmail = savedEmail
        }

        loadProfileImageFromDisk()
    }

    func saveName() {
        savedUserName = userName
        print("Name saved: \(userName)")
    }

    private func saveProfileImageToDisk() {
        guard let image = profileImage,
              let data = image.jpegData(compressionQuality: 0.8) else { return }

        let fileURL = getProfileImageURL()
        try? data.write(to: fileURL)
    }

    private func loadProfileImageFromDisk() {
        let fileURL = getProfileImageURL()
        guard let data = try? Data(contentsOf: fileURL),
              let image = UIImage(data: data) else { return }

        profileImage = image
    }

    private func deleteProfileImageFromDisk() {
        let fileURL = getProfileImageURL()
        try? FileManager.default.removeItem(at: fileURL)
    }

    private func getProfileImageURL() -> URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsPath.appendingPathComponent("profileImage.jpg")
    }

    // MARK: - Authentication (Dummy Implementation)

    /// Dummy sign in - Replace this with real Apple Sign In implementation
    func signIn() {
        // TODO: Implement real Apple Sign In here
        // This is a placeholder for demonstration
        isSignedIn = true
        userName = "John Doe"
        userEmail = "john.doe@example.com"

        // Persist sign in status
        storedSignInStatus = true
        savedUserName = userName
        savedUserEmail = userEmail

        print("User signed in (dummy)")
    }

    /// Sign out user and clear all data
    func signOut() {
        isSignedIn = false
        profileImage = nil
        userName = "Guest"
        userEmail = nil

        // Clear persisted data
        storedSignInStatus = false
        savedUserName = nil
        savedUserEmail = nil
        deleteProfileImageFromDisk()

        print("User signed out")
    }

    // MARK: - Profile Image Management

    func updateProfileImage(_ image: UIImage?) {
        profileImage = image
        if image != nil {
            saveProfileImageToDisk()
        }
    }
}
