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

    @Published var isSignedIn: Bool = false

    // Persistence Keys

    private let kIsSignedIn = "isUserSignedIn"
    
    private init() {
        loadUserData()
    }
    
    // MARK: - Data Persistence
    
    func loadUserData() {
        let defaults = UserDefaults.standard
        isSignedIn = defaults.bool(forKey: kIsSignedIn)

        
        loadProfileImageFromDisk()
    }

    func saveUserData() {
        let defaults = UserDefaults.standard
        defaults.set(isSignedIn, forKey: kIsSignedIn)

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
        profileImage = nil

        saveUserData()
        deleteProfileImageFromDisk()
    }
    

    
    // MARK: - Delete Account
    func deleteAllData() {
        // Clear all published properties
        isSignedIn = false
        profileImage = nil
        
        // Clear UserDefaults
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: kIsSignedIn)

        defaults.removeObject(forKey: "pregnancyStartDate")
        
        // Delete profile image from disk
        deleteProfileImageFromDisk()
        
        // Delete all local heartbeat recordings and moment images
        deleteAllLocalFiles()
        
        print("✅ All local user data cleared")
    }
    
    private func deleteAllLocalFiles() {
        let fileManager = FileManager.default
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        
        do {
            let fileURLs = try fileManager.contentsOfDirectory(at: documentsPath, includingPropertiesForKeys: nil)
            
            for fileURL in fileURLs {
                let fileName = fileURL.lastPathComponent
                
                // Delete heartbeat recordings (recording-*.caf)
                if fileName.hasPrefix("recording-") && fileName.hasSuffix(".caf") {
                    try? fileManager.removeItem(at: fileURL)
                    print("   🗑️ Deleted local heartbeat: \(fileName)")
                }
                
                // Delete moment images (moment-*.jpg)
                if fileName.hasPrefix("moment-") && fileName.hasSuffix(".jpg") {
                    try? fileManager.removeItem(at: fileURL)
                    print("   🗑️ Deleted local moment: \(fileName)")
                }
            }
        } catch {
            print("   ⚠️ Error cleaning local files: \(error.localizedDescription)")
        }
    }
}
