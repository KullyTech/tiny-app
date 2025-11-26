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
<<<<<<< HEAD

=======
    
>>>>>>> 1fbb098 (feat: add profile navigation in PregnancyTimelineView)
    @Published var profileImage: UIImage?
    @Published var userName: String = "Guest"
    @Published var userEmail: String?
    @Published var isSignedIn: Bool = false
<<<<<<< HEAD

=======
    
>>>>>>> 1fbb098 (feat: add profile navigation in PregnancyTimelineView)
    // Persistence Keys
    private let kUserName = "savedUserName"
    private let kUserEmail = "savedUserEmail"
    private let kIsSignedIn = "isUserSignedIn"
<<<<<<< HEAD

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

=======
    
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
    
>>>>>>> 1fbb098 (feat: add profile navigation in PregnancyTimelineView)
    func saveUserData() {
        let defaults = UserDefaults.standard
        defaults.set(isSignedIn, forKey: kIsSignedIn)
        defaults.set(userName, forKey: kUserName)
        defaults.set(userEmail, forKey: kUserEmail)
    }
<<<<<<< HEAD

    func saveProfileImage(_ image: UIImage?) {
        profileImage = image

=======
    
    func saveProfileImage(_ image: UIImage?) {
        profileImage = image
        
>>>>>>> 1fbb098 (feat: add profile navigation in PregnancyTimelineView)
        if let image = image {
            saveProfileImageToDisk(image)
        } else {
            deleteProfileImageFromDisk()
        }
    }
<<<<<<< HEAD

=======
    
>>>>>>> 1fbb098 (feat: add profile navigation in PregnancyTimelineView)
    private func saveProfileImageToDisk(_ image: UIImage) {
        guard let data = image.jpegData(compressionQuality: 0.8) else { return }
        let fileURL = getProfileImageURL()
        try? data.write(to: fileURL)
    }
<<<<<<< HEAD

=======
    
>>>>>>> 1fbb098 (feat: add profile navigation in PregnancyTimelineView)
    private func loadProfileImageFromDisk() {
        let fileURL = getProfileImageURL()
        guard let data = try? Data(contentsOf: fileURL),
              let image = UIImage(data: data) else {
            profileImage = nil
            return
        }
        profileImage = image
    }
<<<<<<< HEAD

=======
    
>>>>>>> 1fbb098 (feat: add profile navigation in PregnancyTimelineView)
    private func deleteProfileImageFromDisk() {
        let fileURL = getProfileImageURL()
        try? FileManager.default.removeItem(at: fileURL)
    }
<<<<<<< HEAD

=======
    
>>>>>>> 1fbb098 (feat: add profile navigation in PregnancyTimelineView)
    private func getProfileImageURL() -> URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsPath.appendingPathComponent("profileImage.jpg")
    }
<<<<<<< HEAD

    // MARK: - Actions

=======
    
    // MARK: - Actions
    
>>>>>>> 1fbb098 (feat: add profile navigation in PregnancyTimelineView)
    func signOut() {
        isSignedIn = false
        userName = "Guest"
        userEmail = nil
        profileImage = nil
<<<<<<< HEAD

        saveUserData()
        deleteProfileImageFromDisk()
    }

=======
        
        saveUserData()
        deleteProfileImageFromDisk()
    }
    
>>>>>>> 1fbb098 (feat: add profile navigation in PregnancyTimelineView)
    func signInDummy() {
        isSignedIn = true
        userName = "John Doe"
        userEmail = "john.doe@example.com"
        saveUserData()
    }
}
