//
//  SavedHeartbeatModel.swift
//  Tiny
//
//  Created by Tm Revanza Narendra Pradipta on 20/11/25.
//

import SwiftData
import Foundation
import FirebaseFirestore

@Model
class SavedHeartbeat {
    @Attribute(.unique) var id: UUID
    var filePath: String // Local file path
    var timestamp: Date
    var displayName: String? // Custom name for the recording
    
    // Firebase fields
    var firebaseId: String? // Document ID in Firestore (for metadata)
    var motherUserId: String?
    var roomCode: String?
    var isShared: Bool // Whether mom has shared it with dad
    var firebaseStorageURL: String? // Firebase Storage download URL
    var isSyncedToCloud: Bool // Whether it's been uploaded to Firebase Storage
    var pregnancyWeeks: Int?
    
    init(filePath: String,
         timestamp: Date = Date(),
         displayName: String? = nil,
         motherUserId: String? = nil,
         roomCode: String? = nil,
         isShared: Bool = true,  // Changed default from false to true
         firebaseStorageURL: String? = nil,
         pregnancyWeeks: Int? = nil,
         isSyncedToCloud: Bool = false,
         firebaseId: String? = nil) {
        self.id = UUID()
        self.filePath = filePath
        self.timestamp = timestamp
        self.displayName = displayName
        self.motherUserId = motherUserId
        self.roomCode = roomCode
        self.isShared = isShared
        self.firebaseStorageURL = firebaseStorageURL
        self.pregnancyWeeks = pregnancyWeeks
        self.isSyncedToCloud = isSyncedToCloud
        self.firebaseId = firebaseId
    }
}

// Extension for Firestore conversion (metadata only)
extension SavedHeartbeat {
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "timestamp": Timestamp(date: timestamp),
            "isShared": isShared,
            "isSyncedToCloud": isSyncedToCloud
        ]
        
        if let displayName = displayName {
            dict["displayName"] = displayName
        }
        if let motherUserId = motherUserId {
            dict["motherUserId"] = motherUserId
        }
        if let roomCode = roomCode {
            dict["roomCode"] = roomCode
        }
        if let firebaseStorageURL = firebaseStorageURL {
            dict["firebaseStorageURL"] = firebaseStorageURL
        }
        if let pregnancyWeeks = pregnancyWeeks {
            dict["pregnancyWeeks"] = pregnancyWeeks
        }
        
        return dict
    }
    
    static func fromFirestore(id: String, data: [String: Any]) -> SavedHeartbeat? {
        guard let timestamp = (data["timestamp"] as? Timestamp)?.dateValue() else {
            return nil
        }
        
        return SavedHeartbeat(
            filePath: "", // Will be set after downloading
            timestamp: timestamp,
            displayName: data["displayName"] as? String,
            motherUserId: data["motherUserId"] as? String,
            roomCode: data["roomCode"] as? String,
            isShared: data["isShared"] as? Bool ?? false,
            firebaseStorageURL: data["firebaseStorageURL"] as? String,
            pregnancyWeeks: data["pregnancyWeeks"] as? Int,
            isSyncedToCloud: data["isSyncedToCloud"] as? Bool ?? false,
            firebaseId: id
        )
    }
}
