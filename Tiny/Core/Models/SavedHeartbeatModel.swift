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
    var filePath: String
    var timestamp: Date

    var firebaseId: String?
    var motherUserId: String?
    var roomCode: String?
    var isShared: Bool
    var audioFileURL: String?
    var pregnancyWeeks: Int?
    var isSyncedToCloud: Bool
    
    init(filePath: String,
         timestamp: Date = Date(),
         motherUserId: String? = nil,
         roomCode: String? = nil,
         isShared: Bool = false,
         audioFileURL: String? = nil,
         pregnancyWeeks: Int? = nil,
         isSyncedToCloud: Bool = false,
         firebaseId: String? = nil) {
        self.id = UUID()
        self.filePath = filePath
        self.timestamp = timestamp
        self.motherUserId = motherUserId
        self.roomCode = roomCode
        self.isShared = isShared
        self.audioFileURL = audioFileURL
        self.pregnancyWeeks = pregnancyWeeks
        self.isSyncedToCloud = isSyncedToCloud
        self.firebaseId = firebaseId
    }
}

extension SavedHeartbeat {
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "timestamp": Timestamp(date: timestamp),
            "isShared": isShared,
            "isSyncedToCloud": isSyncedToCloud
        ]
        
        if let motherUserId = motherUserId {
            dict["motherUserId"] = motherUserId
        }
        if let roomCode = roomCode {
            dict["roomCode"] = roomCode
        }
        if let audioFileURL = audioFileURL {
            dict["audioFileURL"] = audioFileURL
        }
        if let pregnancyWeeks = pregnancyWeeks {
            dict["pregnancyWeeks"] = pregnancyWeeks
        }
        
        return dict
    }
    
    static func fromFirestore(id: String, data: [String: Any], localFilePath: String) -> SavedHeartbeat? {
        guard let timestamp = (data["timestamp"] as? Timestamp)?.dateValue() else {
            return nil
        }
        
        return SavedHeartbeat(
            filePath: localFilePath,
            timestamp: timestamp,
            motherUserId: data["motherUserId"] as? String,
            roomCode: data["roomCode"] as? String,
            isShared: data["isShared"] as? Bool ?? false,
            audioFileURL: data["audioFileURL"] as? String,
            pregnancyWeeks: data["pregnancyWeeks"] as? Int,
            isSyncedToCloud: data["isSyncedToCloud"] as? Bool ?? false,
            firebaseId: id
        )
    }
}
