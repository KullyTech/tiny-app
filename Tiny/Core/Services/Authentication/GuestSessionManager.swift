//
//  GuestSessionManager.swift
//  Tiny
//
//  Created for offline guest session management
//

import Foundation
import SwiftData

/// Manages offline guest sessions with local-only data storage
@MainActor
class GuestSessionManager {
    static let shared = GuestSessionManager()
    
    // UserDefaults keys
    private let guestSessionIdKey = "offlineGuestSessionId"
    private let isGuestSessionKey = "isOfflineGuestSession"
    private let guestNameKey = "offlineGuestName"
    private let guestRoleKey = "offlineGuestRole"
    private let guestPregnancyWeeksKey = "offlineGuestPregnancyWeeks"
    
    private init() {}
    
    // MARK: - Session Creation
    
    /// Creates a new offline guest session
    func createGuestSession() -> User {
        let guestId = UUID().uuidString
        
        // Store session info in UserDefaults
        UserDefaults.standard.set(guestId, forKey: guestSessionIdKey)
        UserDefaults.standard.set(true, forKey: isGuestSessionKey)
        
        let guestUser = User(
            id: guestId,
            email: "guest@offline.local",
            name: "Guest User",
            role: nil,
            pregnancyWeeks: nil,
            roomCode: "GUEST1", // Fixed offline room code
            createdAt: Date(),
            isGuest: true,
            isOfflineGuest: true
        )
        
        print("✅ Created offline guest session: \(guestId)")
        return guestUser
    }
    
    // MARK: - Session Retrieval
    
    /// Retrieves the current guest session if one exists
    func getCurrentGuestSession() -> User? {
        guard isGuestSession(),
              let guestId = UserDefaults.standard.string(forKey: guestSessionIdKey) else {
            return nil
        }
        
        let name = UserDefaults.standard.string(forKey: guestNameKey) ?? "Guest User"
        let roleString = UserDefaults.standard.string(forKey: guestRoleKey)
        let role = roleString.flatMap { UserRole(rawValue: $0) }
        let pregnancyWeeks = UserDefaults.standard.object(forKey: guestPregnancyWeeksKey) as? Int
        let roomCode = UserDefaults.standard.string(forKey: "offlineGuestRoomCode") ?? "GUEST1"
        
        return User(
            id: guestId,
            email: "guest@offline.local",
            name: name,
            role: role,
            pregnancyWeeks: pregnancyWeeks,
            roomCode: roomCode,
            createdAt: Date(),
            isGuest: true,
            isOfflineGuest: true
        )
    }
    
    // MARK: - Session Status
    
    /// Checks if there's an active guest session
    func isGuestSession() -> Bool {
        return UserDefaults.standard.bool(forKey: isGuestSessionKey)
    }
    
    // MARK: - Session Updates
    
    /// Updates guest user information
    func updateGuestUser(name: String? = nil, role: UserRole? = nil, pregnancyWeeks: Int? = nil) {
        guard isGuestSession() else { return }
        
        if let name = name {
            UserDefaults.standard.set(name, forKey: guestNameKey)
        }
        
        if let role = role {
            UserDefaults.standard.set(role.rawValue, forKey: guestRoleKey)
            
            // Assign role-specific room code
            let roomCode = role == .mother ? "GUEST-MOM" : "GUEST-DAD"
            UserDefaults.standard.set(roomCode, forKey: "offlineGuestRoomCode")
        }
        
        if let weeks = pregnancyWeeks {
            UserDefaults.standard.set(weeks, forKey: guestPregnancyWeeksKey)
        }
        
        print("✅ Updated guest session data")
    }
    
    // MARK: - Session Cleanup
    
    /// Clears the guest session and all associated data
    func clearGuestSession(modelContext: ModelContext?) {
        guard isGuestSession() else { return }
        
        print("🗑️ Clearing guest session...")
        
        // 1. Delete all SwiftData records
        if let modelContext = modelContext {
            deleteSwiftDataRecords(modelContext: modelContext)
        }
        
        // 2. Delete profile images
        deleteProfileImages()
        
        // 3. Clear UserDefaults
        clearUserDefaults()
        
        print("✅ Guest session cleared")
    }
    
    // MARK: - Private Helpers
    
    private func deleteSwiftDataRecords(modelContext: ModelContext) {
        do {
            // Delete all heartbeats
            let heartbeatDescriptor = FetchDescriptor<SavedHeartbeat>()
            let heartbeats = try modelContext.fetch(heartbeatDescriptor)
            for heartbeat in heartbeats {
                modelContext.delete(heartbeat)
            }
            print("   Deleted \(heartbeats.count) heartbeats")
            
            // Delete all moments
            let momentDescriptor = FetchDescriptor<SavedMoment>()
            let moments = try modelContext.fetch(momentDescriptor)
            for moment in moments {
                modelContext.delete(moment)
            }
            print("   Deleted \(moments.count) moments")
            
            // Save changes
            try modelContext.save()
            
        } catch {
            print("❌ Error deleting SwiftData records: \(error)")
        }
    }
    
    private func deleteProfileImages() {
        let fileManager = FileManager.default
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let profileImageURL = documentsPath.appendingPathComponent("profileImage.jpg")
        
        if fileManager.fileExists(atPath: profileImageURL.path) {
            try? fileManager.removeItem(at: profileImageURL)
            print("   Deleted profile image")
        }
    }
    
    private func clearUserDefaults() {
        UserDefaults.standard.removeObject(forKey: guestSessionIdKey)
        UserDefaults.standard.removeObject(forKey: isGuestSessionKey)
        UserDefaults.standard.removeObject(forKey: guestNameKey)
        UserDefaults.standard.removeObject(forKey: guestRoleKey)
        UserDefaults.standard.removeObject(forKey: guestPregnancyWeeksKey)
        UserDefaults.standard.removeObject(forKey: "offlineGuestRoomCode")
        UserDefaults.standard.removeObject(forKey: "pregnancyStartDate")
        UserDefaults.standard.removeObject(forKey: "hasSeenTimelineAnimation") // Reset timeline animation
        UserDefaults.standard.removeObject(forKey: "hasShownInitialTutorial") // Reset initial tutorial
        UserDefaults.standard.removeObject(forKey: "hasShownListeningTutorial") // Reset listening tutorial
        print("   Cleared UserDefaults")
    }
}
