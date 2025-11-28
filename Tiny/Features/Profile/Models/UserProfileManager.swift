//
//  UserProfileManager.swift
//  Tiny
//
//  Created by Destu Cikal Ramdani on 27/11/25.
//

import SwiftUI
internal import Combine

class UserProfileManager: ObservableObject {
    static let shared = UserProfileManager()

    @Published var profileImage: UIImage?
    @Published var userName: String = "Guest"
    @Published var userEmail: String?
    @Published var isSignedIn: Bool = false

    // Persistence Keys
    private let kUserName = "savedUserName"
    private let kUserEmail = "savedUserEmail"
    private let kIsSignedIn = "isUserSignedIn"

    private init() {
        loadUserData()
    }

    // MARK: - Data Persistence

    func loadUserData() {
        let defaults = UserDefaults.standard
        isSignedIn = defaults.bool(forKey: kIsSignedIn)

        if let savedName = defaults.string(forKey: kUserName) {
            userName = savedName
        }

        if let savedEmail = defaults.string(forKey: kUserEmail) {
            userEmail = savedEmail
        }

        loadProfileImageFromDisk()
    }

    func saveUserData() {
        let defaults = UserDefaults.standard
        defaults.set(isSignedIn, forKey: kIsSignedIn)
        defaults.set(userName, forKey: kUserName)
        defaults.set(userEmail, forKey: kUserEmail)
    }

    func saveProfileImage(_ image: UIImage?) {
        profileImage = image

        if let image = image {
            saveProfileImageToDisk(image)
        } else {
            deleteProfileImageFromDisk()
        }
    }

    private func saveProfileImageToDisk(_ image: UIImage) {
        guard let data = image.jpegData(compressionQuality: 0.8) else { return }
        let fileURL = getProfileImageURL()
        try? data.write(to: fileURL)
    }

    private func loadProfileImageFromDisk() {
        let fileURL = getProfileImageURL()
        guard let data = try? Data(contentsOf: fileURL),
              let image = UIImage(data: data) else {
            profileImage = nil
            return
        }
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

    // MARK: - Actions

    func signOut() {
        isSignedIn = false
        userName = "Guest"
        userEmail = nil
        profileImage = nil

        saveUserData()
        deleteProfileImageFromDisk()
    }

    func signInDummy() {
        isSignedIn = true
        userName = "John Doe"
        userEmail = "john.doe@example.com"
        saveUserData()
    }
}
